import SwiftUI
import Traffical

/// Shows what the SDK decided for this visitor on the current screen. Handy
/// to check an integration end to end; not something you would ship.
struct DecisionDetailsView: View {
    let decision: TrafficalDecisionResult?
    let onNewVisitor: (() -> Void)?

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                if let decision {
                    Section("Visitor") {
                        row("Unit key", decision.metadata.unitKeyValue)
                        row("Decision id", decision.decisionId)
                        row("Config version", decision.metadata.configVersion ?? "none (defaults)")
                        row("Reason", decision.metadata.reason?.rawValue ?? "")
                    }

                    Section("Parameters") {
                        ForEach(decision.assignments.keys.sorted(), id: \.self) { key in
                            row(key, describe(decision.assignments[key]))
                        }
                    }

                    Section("Layers") {
                        let layers = decision.metadata.layers.filter { $0.policyId != nil && !$0.attributionOnly }
                        if layers.isEmpty {
                            Text("No running policy matched. Every parameter uses its default.")
                                .foregroundStyle(.secondary)
                        }
                        ForEach(layers, id: \.layerId) { layer in
                            VStack(alignment: .leading, spacing: 4) {
                                row("Policy", layer.policyKey ?? layer.policyId ?? "")
                                row("Allocation", layer.allocationKey ?? layer.allocationName ?? "")
                                row("Bucket", String(layer.bucket))
                            }
                        }
                    }
                }

                Section("SDK health") {
                    let diagnostics = traffical.getDiagnostics()
                    row("Resolution errors", String(diagnostics.resolutionErrors))
                    row("Rejected bundles", String(diagnostics.rejectedBundles))
                    row("Dropped events", String(diagnostics.droppedEvents))
                    if let lastError = diagnostics.lastError {
                        row("Last error", "\(lastError.tag): \(lastError.message)")
                    }
                }

                if let onNewVisitor {
                    Section {
                        Button("Become a new visitor") {
                            onNewVisitor()
                            dismiss()
                        }
                    } footer: {
                        Text("Assigns a fresh random unit key, which may land in a different allocation.")
                    }
                }
            }
            .navigationTitle("Decision")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                Button("Done") { dismiss() }
            }
        }
    }

    private func row(_ label: String, _ value: String) -> some View {
        LabeledContent(label) {
            Text(value)
                .font(.footnote.monospaced())
                .textSelection(.enabled)
        }
    }

    private func describe(_ value: TrafficalParameterValue?) -> String {
        switch value {
        case .string(let s): return s
        case .number(let n): return String(n)
        case .bool(let b): return String(b)
        case .json: return "{…}"
        case nil: return ""
        }
    }
}
