//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import SwiftUI

/// The reasoning, one paragraph at a time. It grows with the text up to `maxHeight`, then
/// scrolls, fading at the top so it reads as continuing above. While the reasoning is live,
/// new text is revealed smoothly and the newest stays in view unless the reader scrolls up.
struct ReasoningPanel: View {
    let text: String
    let isLive: Bool
    let maxHeight: CGFloat
    let color: Color

    @StateObject private var reveal = TextReveal()
    @State private var contentHeight: CGFloat = 0
    @State private var following = true
    private let bottom = "reasoning.bottom"

    var body: some View {
        let overflowing = contentHeight > maxHeight
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 10) {
                    ForEach(ReasoningParagraph.split(reveal.shown)) { paragraph in
                        ReasoningParagraphView(text: paragraph.text, color: color)
                            .equatable()
                    }
                    Color.clear.frame(height: 1).id(bottom)
                }
                .background {
                    GeometryReader { geometry in
                        Color.clear.preference(key: ReasoningHeightKey.self, value: geometry.size.height)
                    }
                }
            }
            .frame(height: min(max(contentHeight, 1), maxHeight))
            .mask(
                LinearGradient(
                    stops: [.init(color: overflowing ? .clear : .black, location: 0), .init(color: .black, location: 0.14)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .onPreferenceChange(ReasoningHeightKey.self) { contentHeight = $0 }
            .modifier(FollowsReader(following: $following))
            .onAppear {
                reveal.update(text, animated: false)
                if isLive { proxy.scrollTo(bottom, anchor: .bottom) }
            }
            .modifier(OnChange(value: text) {
                reveal.update(text, animated: isLive)
            })
            // The last thoughts can land as the model stops thinking, so new text keeps a
            // reader who is following at the end either way. A finished trace opens at its start.
            .modifier(OnChange(value: reveal.shown) {
                if following { proxy.scrollTo(bottom, anchor: .bottom) }
            })
        }
    }
}

private struct ReasoningHeightKey: PreferenceKey {
    static let defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

/// Stops following new text while the reader has scrolled up, and resumes once they are
/// back at the end. Only the reader's own scrolling counts: the panel growing, or the
/// list around it moving, never stops it following. Earlier systems always follow.
private struct FollowsReader: ViewModifier {
    @Binding var following: Bool

    func body(content: Content) -> some View {
        if #available(iOS 18.0, *) {
            content.onScrollPhaseChange { old, phase, context in
                guard phase == .idle, old == .interacting || old == .decelerating else { return }
                let geometry = context.geometry
                following = geometry.contentOffset.y + geometry.containerSize.height >= geometry.contentSize.height - 24
            }
        } else {
            content
        }
    }
}
