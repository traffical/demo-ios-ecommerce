import SwiftUI
import Traffical

/// A product page with recommendations below the fold.
struct ProductDetailView: View {
    let route: ProductRoute

    @State private var decision: TrafficalDecisionResult?
    @State private var exposed = false
    @State private var showingDetails = false

    private var product: Product? { Product.find(route.productId) }

    var body: some View {
        ScrollView {
            if let product {
                VStack(alignment: .leading, spacing: 16) {
                    details(product)
                    if let decision {
                        recommendations(for: product, decision: decision)
                    }
                }
                .padding()
            }
        }
        .viewport()
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            Button {
                showingDetails = true
            } label: {
                Image(systemName: "info.circle")
            }
            .accessibilityLabel("Decision details")
        }
        .sheet(isPresented: $showingDetails) {
            DecisionDetailsView(decision: decision, onNewVisitor: nil)
        }
        .task {
            guard decision == nil, let product else { return }   // not again when navigating back
            let decision = traffical.decide(defaults: RecommendationParams.defaults)
            self.decision = decision
            Events.productView(product, from: route, decision: decision)
            // No exposure yet: the recommendations are below the fold. It is
            // sent when the first recommended product scrolls into view.
        }
    }

    // MARK: - Above the fold

    private func details(_ product: Product) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(product.imageName)
                .resizable()
                .scaledToFit()
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16))

            Text(product.category.uppercased())
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(product.name)
                .font(.title2.weight(.semibold))
            Text(product.price, format: .currency(code: "USD"))
                .font(.title3.weight(.semibold))
            Text(product.description)
                .foregroundStyle(.secondary)

            VStack(spacing: 8) {
                ForEach(Array(product.specs), id: \.key) { spec in
                    LabeledContent(spec.key, value: spec.value)
                        .font(.subheadline)
                    Divider()
                }
            }
            .padding(.top, 8)
        }
    }

    // MARK: - Below the fold

    private func recommendations(for product: Product, decision: TrafficalDecisionResult) -> some View {
        let params = decision.assignments
        let title = params["pdp.recommendations.title"]?.stringValue ?? "You might also like"
        let strategy = params["pdp.recommendations.strategy"]?.stringValue ?? "same_category"
        let count = Int(params["pdp.recommendations.count"]?.numberValue ?? 4)
        let items = product.recommendations(strategy: strategy, count: count)

        return VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .padding(.top, 24)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 16)], spacing: 20) {
                ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                    let position = index + 1
                    NavigationLink(value: ProductRoute(
                        productId: item.id, source: .recommendation, position: position, sourceProductId: product.id
                    )) {
                        ProductCard(product: item)
                    }
                    .buttonStyle(.plain)
                    .onEnterViewport {
                        // The first recommendation the user sees exposes them
                        // to the recommendations experiment.
                        if !exposed {
                            exposed = true
                            Events.exposure(decision)
                        }
                        Events.recommendationImpression(
                            item, position: position, on: product, strategy: strategy, decision: decision
                        )
                    }
                }
            }
        }
    }
}
