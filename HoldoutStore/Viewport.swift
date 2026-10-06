import SwiftUI

// A small helper to run code once a view has scrolled into view: at least
// half of it inside the visible area of the enclosing scroll view.
//
// `onAppear` is not enough for this: inside a ScrollView it fires when the
// view is built, which can be long before anyone has seen it.

extension View {
    /// Marks this scroll view as the viewport that `onEnterViewport` checks against.
    func viewport() -> some View {
        modifier(ViewportModifier())
    }

    /// Runs `action` once, the first time at least half of this view is visible.
    func onEnterViewport(perform action: @escaping () -> Void) -> some View {
        modifier(EnterViewportModifier(action: action))
    }
}

private let viewportSpace = "viewport"

private struct ViewportHeightKey: EnvironmentKey {
    static let defaultValue: CGFloat = 0
}

private extension EnvironmentValues {
    var viewportHeight: CGFloat {
        get { self[ViewportHeightKey.self] }
        set { self[ViewportHeightKey.self] = newValue }
    }
}

private struct ViewportModifier: ViewModifier {
    func body(content: Content) -> some View {
        GeometryReader { proxy in
            content
                .coordinateSpace(name: viewportSpace)
                .environment(\.viewportHeight, proxy.size.height)
        }
    }
}

private struct VisibleKey: PreferenceKey {
    static let defaultValue = false
    static func reduce(value: inout Bool, nextValue: () -> Bool) { value = value || nextValue() }
}

private struct EnterViewportModifier: ViewModifier {
    let action: () -> Void

    @Environment(\.viewportHeight) private var viewportHeight
    @State private var hasEntered = false

    func body(content: Content) -> some View {
        content
            .background(
                GeometryReader { proxy in
                    Color.clear.preference(key: VisibleKey.self, value: isHalfVisible(proxy.frame(in: .named(viewportSpace))))
                }
            )
            .onPreferenceChange(VisibleKey.self) { visible in
                guard visible, !hasEntered else { return }
                hasEntered = true
                action()
            }
    }

    private func isHalfVisible(_ frame: CGRect) -> Bool {
        guard viewportHeight > 0, frame.height > 0 else { return false }
        let visible = min(frame.maxY, viewportHeight) - max(frame.minY, 0)
        return visible >= frame.height / 2
    }
}
