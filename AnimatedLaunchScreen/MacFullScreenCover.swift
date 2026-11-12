import SwiftUI

#if os(macOS)
/// An in-window alternative to fullScreenCover. Apply it to the window's root view.
/// Dismiss by setting isPresented to false or calling dismiss from the cover.
private struct MacFullScreenCoverModifier<Cover: View>: ViewModifier {
    @Binding var isPresented: Bool
    let background: Color
    let onDismiss: (() -> Void)?
    @ViewBuilder let cover: () -> Cover

    func body(content: Content) -> some View {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .disabled(isPresented)
            .allowsHitTesting(!isPresented)
            .accessibilityHidden(isPresented)
            .overlay {
                if isPresented {
                    MacCoverPresentation(isPresented: $isPresented, cover: cover())
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(background.ignoresSafeArea())
                        .contentShape(Rectangle())
                        .accessibilityElement(children: .contain)
                        .transition(.opacity)
                        .onDisappear {
                            onDismiss?()
                        }
                }
            }
    }
}

// A navigation destination supplies SwiftUI's native dismiss action while
// keeping the presentation inside the window.
private struct MacCoverPresentation<Cover: View>: View {
    @Binding var isPresented: Bool
    let cover: Cover

    var body: some View {
        NavigationStack {
            Color.clear
                .navigationDestination(isPresented: $isPresented) {
                    cover
                        .toolbar(.hidden)
                }
        }
    }
}

extension View {
    /// Covers this view's content while preserving its state underneath.
    ///
    /// Attach to the root view to cover the window's content area. The title bar,
    /// toolbar, and app menu commands remain outside the cover.
    /// Call the cover's environment dismiss action or set isPresented to false to dismiss.
    /// Use withAnimation when changing the binding to animate the fade.
    /// Pass .clear for a transparent background; presentationBackground has no effect.
    func macFullScreenCover<Cover: View>(
        isPresented: Binding<Bool>,
        background: Color = Color(nsColor: .windowBackgroundColor),
        onDismiss: (() -> Void)? = nil,
        @ViewBuilder content: @escaping () -> Cover
    ) -> some View {
        modifier(MacFullScreenCoverModifier(
            isPresented: isPresented,
            background: background,
            onDismiss: onDismiss,
            cover: content
        ))
    }
}
#endif
