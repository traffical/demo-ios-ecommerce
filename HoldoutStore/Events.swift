import Traffical

// MARK: - 4. Track what users do
//
// Every event the app sends, in one place. The names and properties match the
// event definitions in `.traffical/config.yaml`, which is where the metrics
// that experiments are judged on get built from.
//
// Passing the `decisionId` ties an event to the decision that shaped the
// screen it happened on.

enum Events {
    /// The catalog screen was shown.
    static func catalogView(products: [Product], layout: String, sort: String, decision: TrafficalDecisionResult) {
        send("catalog_view", [
            "layout": layout,
            "sort": sort,
            "product_count": products.count,
            "product_ids": products.map(\.id),
        ], decision: decision)
    }

    /// A product page was shown.
    static func productView(_ product: Product, from route: ProductRoute, decision: TrafficalDecisionResult) {
        var properties: [String: Any] = [
            "product_id": product.id,
            "category": product.category,
            "price": product.price,
            "source": route.source.rawValue,
            "position": route.position,
        ]
        if let sourceProductId = route.sourceProductId {
            properties["source_product_id"] = sourceProductId
        }
        send("product_view", properties, decision: decision)
    }

    /// A recommended product scrolled into view on a product page.
    static func recommendationImpression(
        _ product: Product, position: Int, on page: Product, strategy: String, decision: TrafficalDecisionResult
    ) {
        send("recommendation_impression", [
            "product_id": product.id,
            "source_product_id": page.id,
            "position": position,
            "strategy": strategy,
        ], decision: decision)
    }

    /// The user actually saw what a decision changed. Experiment analysis
    /// counts a visitor from their first exposure. The SDK also deduplicates:
    /// it sends one exposure per visitor and variant per 30-minute session.
    static func exposure(_ decision: TrafficalDecisionResult) {
        print("[Traffical] exposure for decision \(decision.decisionId)")
        traffical.trackExposure(decision)
    }

    private static func send(_ event: String, _ properties: [String: Any], decision: TrafficalDecisionResult) {
        print("[Traffical] track \(event) \(properties)")
        traffical.track(event, properties: properties, options: .init(decisionId: decision.decisionId))
    }
}
