import SwiftUI

@main
struct HoldoutStoreApp: App {
    init() {
        // Download the latest config in the background. The SDK never blocks
        // or throws: until the download finishes it serves the config cached
        // from the last launch, or your inline defaults on a first launch.
        Task { await traffical.initialize() }
    }

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                CatalogView()
            }
        }
    }
}
