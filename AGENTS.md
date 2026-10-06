# Agent notes

This is a SwiftUI demo app for the Traffical iOS SDK (`https://github.com/traffical/ios-sdk`, Swift Package Manager).

| What | Where |
|------|-------|
| SDK client and parameter defaults | `HoldoutStore/Traffical.swift` |
| Every tracked event | `HoldoutStore/Events.swift` |
| `decide` + exposure per screen | `HoldoutStore/CatalogView.swift`, `HoldoutStore/ProductDetailView.swift` |
| Parameter and event definitions | `.traffical/config.yaml` |
| Metric definitions | `.traffical/metrics.yaml` |
| Project link | `.traffical/project.yaml` |

- Keep the defaults in `Traffical.swift` and the events in `Events.swift` equal to `.traffical/config.yaml`, and run `npx @traffical/cli push` after editing the YAML.
- Exposure is explicit: `decide` first, then `Events.exposure(decision)` when the changed UI is on screen. The recommendations expose on `.onEnterViewport`, not on appear. Do not switch to the typed getters (`traffical.string(...)` and friends): they expose on read.
- Layers and policies are not config-as-code; they live in the Traffical dashboard.
- The API key in `Traffical.swift` is a publishable (`traffical_pk_`) key. Never put a secret `traffical_sk_` key in the app.
- Build: `xcodebuild -project HoldoutStore.xcodeproj -scheme HoldoutStore -destination "platform=iOS Simulator,name=iPhone 15" build`

For the full Traffical workflow, install the agent skill: `npx skills add traffical/skills`.
