//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamCore
import SwiftUI

// The scrolling of an AIConversationView, which does not depend on the type of its messages:
// it brings a message the person sent to the top, keeps what is in view in place as older
// messages arrive above it, opens a conversation at its end, and offers a button back to the end.
struct AIConversationScrollView: View {
    // What sits above the turns in view. When it changes, they would be pushed down or up.
    struct Above: Hashable {
        var firstTurnID: AnyHashable?
        var loadsOlder: Bool
    }

    var turnIDs: [AnyHashable]
    var above: Above
    var positions: AITurnPositions
    // Scrolls to a turn, by the id of its own type that the list knows it by.
    var scrollTo: (AnyHashable, UnitPoint, ScrollViewProxy) -> Void
    // The turns, or what shows while there are none, in a list that tall.
    var content: (CGFloat) -> AnyView

    @State private var shownAbove: Above?
    @State private var lastTurnID: AnyHashable?
    @State private var isEndInView = true

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Injected(\.aiAppearance.tokens.layout) private var layout

    var body: some View {
        let animation: Animation? = reduceMotion ? nil : .default
        return GeometryReader { geometry in
            let height = geometry.size.height
            let slack = layout.spacingXl
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 0) {
                        content(height)

                        Color.clear
                            .frame(height: 0)
                            .background {
                                GeometryReader { end in
                                    Color.clear.preference(
                                        key: AIConversationEndOffset.self,
                                        value: end.frame(in: .named(AIConversationEnd.space)).minY
                                    )
                                }
                            }
                    }
                }
                .coordinateSpace(name: AIConversationEnd.space)
                .modifier(OpensAtEnd())
                .onPreferenceChange(AITurnFrames.self) { frames in
                    positions.update(frames, height: height)
                }
                .onPreferenceChange(AIConversationEndOffset.self) { end in
                    let inView = end <= height + slack
                    guard inView != isEndInView else { return }
                    withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.2)) {
                        isEndInView = inView
                    }
                }
                .overlay(alignment: .bottom) {
                    if !isEndInView {
                        ScrollToLatestButton {
                            guard let last = turnIDs.last else { return }
                            withAnimation(animation) {
                                scrollTo(last, .bottom, proxy)
                            }
                        }
                        .padding(.bottom, layout.spacingXs)
                        .transition(.opacity.combined(with: .scale(scale: 0.8)))
                    }
                }
                .onAppear {
                    shownAbove = above
                    lastTurnID = turnIDs.last
                    if let last = turnIDs.last {
                        scrollToEnd(at: last, with: proxy)
                    }
                }
                .modifier(OnChange(value: above) {
                    let previous = shownAbove
                    shownAbove = above
                    // Older messages arrived above what is in view, or the spinner came or went:
                    // the turn at the top goes back to where it was, rather than being pushed.
                    guard previous?.firstTurnID != nil,
                          let held = positions.heldTurn(among: Set(turnIDs)) else {
                        positions.release()
                        return
                    }
                    let anchor = held.anchor(in: height)
                    DispatchQueue.main.async {
                        scrollTo(held.id, anchor, proxy)
                        positions.release()
                    }
                })
                .modifier(OnChange(value: turnIDs.last) {
                    let scroll = AIConversationScroll(previousLastTurnID: lastTurnID, turnIDs: turnIDs)
                    lastTurnID = turnIDs.last
                    // Scrolls once the new turn is laid out, at least as tall as the list.
                    DispatchQueue.main.async {
                        switch scroll {
                        case let .toTop(turnID):
                            withAnimation(animation) {
                                scrollTo(turnID, .top, proxy)
                            }
                        case .toEnd:
                            if let last = turnIDs.last {
                                scrollToEnd(at: last, with: proxy)
                            }
                        case .none:
                            break
                        }
                    }
                })
            }
        }
    }

    // Shows the end of the latest turn. The turns above it may have only estimated heights until
    // it is laid out, which leaves it short of the end, so it scrolls there again once they are.
    private func scrollToEnd(at last: AnyHashable, with proxy: ScrollViewProxy) {
        scrollTo(last, .bottom, proxy)
        DispatchQueue.main.async {
            scrollTo(last, .bottom, proxy)
        }
    }
}

enum AIConversationEnd {
    static let space = "AIConversationView.scroll"
}

// How far down the list's end is, from the top of what is visible.
private struct AIConversationEndOffset: PreferenceKey {
    static let defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// Shows a conversation that is already there at its end from the first frame. Earlier
// systems scroll there as the list appears.
private struct OpensAtEnd: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 18.0, *) {
            content.defaultScrollAnchor(.bottom, for: .initialOffset)
        } else {
            content
        }
    }
}
