import SwiftUI
import Traffical

/// How the user got to a product page. Sent with `product_view`.
struct ProductRoute: Hashable {
    enum Source: String { case catalog, recommendation }

    let productId: String
    let source: Source
    /// 1-based position in the list the product was tapped in.
    let position: Int
    /// The product page a recommendation was tapped on.
    var sourceProductId: String?
}

struct CatalogView: View {
    @State private var decision: TrafficalDecisionResult?
    @State private var showingDetails = false

    var body: some View {
        Group {
            if let decision {
                catalog(decision)
            } else {
                ProgressView()
            }
        }
        .navigationTitle(decision?.assignments["catalog.title"]?.stringValue ?? "")
        .navigationDestination(for: ProductRoute.self) { route in
            ProductDetailView(route: route)
        }
        .toolbar {
            Button {
                showingDetails = true
            } label: {
                Image(systemName: "info.circle")
            }
            .accessibilityLabel("Decision details")
        }
        .sheet(isPresented: $showingDetails) {
            DecisionDetailsView(decision: decision, onNewVisitor: newVisitor)
        }
        .task {
            guard decision == nil else { return }   // not again when navigating back
            await decide()
        }
    }

    // MARK: - 3. Decide once per screen view

    private func decide() async {
        // Wait (briefly) for the first config so the screen renders its final
        // variant instead of flipping from the defaults. Returns immediately
        // when a cached config is already on disk.
        await traffical.waitForReady(timeoutMs: 2_000)

        // One `decide` call resolves every parameter on this screen and sends
        // one decision event to Traffical. The SDK identifies the visitor with
        // an anonymous id it creates and stores in the Keychain. Pass your own
        // id instead, e.g. `context: ["userId": user.id]`, once users sign in.
        let decision = traffical.decide(defaults: CatalogParams.defaults)
        self.decision = decision

        // The layout is visible as soon as the screen is: expose right away.
        Events.exposure(decision)
        let params = decision.assignments
        let layout = params["catalog.layout"]?.stringValue ?? "grid"
        let sort = params["catalog.sort"]?.stringValue ?? "featured"
        Events.catalogView(products: sorted(Product.catalog, by: sort), layout: layout, sort: sort, decision: decision)
    }

    private func newVisitor() {
        // Pretend to be someone else: a new unit key lands in a new bucket.
        traffical.identify(UUID().uuidString.lowercased())
        decision = nil
        Task { await decide() }
    }

    // MARK: - Rendering

    @ViewBuilder
    private func catalog(_ decision: TrafficalDecisionResult) -> some View {
        let params = decision.assignments
        let products = sorted(Product.catalog, by: params["catalog.sort"]?.stringValue)

        if params["catalog.layout"]?.stringValue == "list" {
            List(Array(products.enumerated()), id: \.element.id) { index, product in
                NavigationLink(value: ProductRoute(productId: product.id, source: .catalog, position: index + 1)) {
                    ProductRow(product: product)
                }
            }
            .listStyle(.plain)
        } else {
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 16)], spacing: 20) {
                    ForEach(Array(products.enumerated()), id: \.element.id) { index, product in
                        NavigationLink(value: ProductRoute(productId: product.id, source: .catalog, position: index + 1)) {
                            ProductCard(product: product)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
            }
        }
    }

    private func sorted(_ products: [Product], by sort: String?) -> [Product] {
        switch sort {
        case "price_low_to_high": return products.sorted { $0.price < $1.price }
        default: return products
        }
    }
}

// MARK: - Product views

struct ProductCard: View {
    let product: Product

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(product.imageName)
                .resizable()
                .scaledToFit()
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            Text(product.category.uppercased())
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(product.name)
                .font(.subheadline.weight(.medium))
                .lineLimit(2, reservesSpace: true)
            Text(product.price, format: .currency(code: "USD"))
                .font(.subheadline.weight(.semibold))
        }
        .contentShape(Rectangle())
    }
}

struct ProductRow: View {
    let product: Product

    var body: some View {
        HStack(spacing: 12) {
            Image(product.imageName)
                .resizable()
                .scaledToFit()
                .frame(width: 64, height: 64)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            VStack(alignment: .leading, spacing: 2) {
                Text(product.name)
                    .font(.subheadline.weight(.medium))
                Text(product.category)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(product.price, format: .currency(code: "USD"))
                .font(.subheadline.weight(.semibold))
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationStack { CatalogView() }
}
