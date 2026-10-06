import Traffical

// MARK: - 1. Create one client for the whole app
//
// The keys below belong to the public demo project. Swap in your own from
// the Traffical dashboard (or `.traffical/.env` after `traffical init`).
//
// Use a *publishable* key (`traffical_pk_…`) in an app. It can only read the
// config bundle and send events, so it is safe to ship in a binary. Never put
// a secret `traffical_sk_…` key in a client.

let traffical = TrafficalClient(options: .init(
    orgId: "org_0uM5pDR6",
    projectId: "proj_11cyay84",
    env: "production",
    apiKey: "traffical_pk_pIVDz15Aea7HsRI4ODsDxMgXYgY1BKlfnkeu1RfN1i2Ept",

    // Every `decide` call sends a decision event to Traffical. That is the
    // default; it is spelled out here so you know where the switch is.
    trackDecisions: true,

    // Events are sent in batches. The default is every 30 seconds; 10 makes
    // them show up sooner while you click around the demo.
    flushIntervalMs: 10_000,

    // Print the SDK's network calls to the Xcode console, e.g.
    // "[Traffical] POST https://sdk.traffical.io/v1/events/batch → 200".
    debugLogger: { event in print("[Traffical] \(event.message)") },

    // The SDK never crashes or throws into your app: on bad data it falls back
    // to your defaults. This hook tells you when that happened.
    onError: { tag, error in print("[Traffical] error in \(tag): \(error)") }
))

// Already running your own analytics pipeline (Segment, RudderStack,
// Snowplow, a warehouse)? Instead of sending events to Traffical, the SDK can
// hand each assignment to your code. Add `disableCloudEvents: true` after
// `trackDecisions`, and this option before `debugLogger`:
//
//     assignmentLogger: { entry in
//         Analytics.shared.track("Experiment Assignment", properties: [
//             "unit_key": entry.unitKey,
//             "type": entry.type.rawValue,          // "decision" or "exposure"
//             "policy_key": entry.policyKey ?? entry.policyId,
//             "allocation_key": entry.allocationKey ?? entry.allocationName,
//             "decision_id": entry.decisionId ?? "",
//         ])
//     }

// MARK: - 2. Declare the parameters each screen reads, with their defaults
//
// The defaults are what users see when no experiment is running, and the
// fallback when the app is offline before the first config download.
// Keep them equal to `.traffical/config.yaml`.

enum CatalogParams {
    static let defaults: [String: TrafficalParameterValue] = [
        "catalog.title": .string("Shop all"),
        "catalog.layout": .string("grid"),          // "grid" | "list"
        "catalog.sort": .string("featured"),        // "featured" | "price_low_to_high"
    ]
}

enum RecommendationParams {
    static let defaults: [String: TrafficalParameterValue] = [
        "pdp.recommendations.title": .string("You might also like"),
        "pdp.recommendations.strategy": .string("same_category"),   // "same_category" | "similar_price"
        "pdp.recommendations.count": .number(4),
    ]
}
