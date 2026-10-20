//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamCore
import SwiftUI

/// The messages of an AI conversation, oldest first.
///
/// The conversation starts at the top of the list and grows down. When the person sends a
/// message, the list scrolls it to the top, and the reply streams in below it without moving
/// anything on screen. A conversation that loads, or replaces the one shown, opens at its end,
/// and a button brings the end back into view whenever it is out of it.
///
/// Each message the person sends starts a turn: that message and the replies after it. The
/// latest turn is at least as tall as the list, so its message can always reach the top.
///
/// Give it ``AIMessage``s and it shows them by itself, with the views of an
/// ``AIConversationViewFactory``:
///
/// ```swift
/// AIConversationView(
///     messages: messages,
///     pendingMessage: sending,
///     isThinking: isWaitingForReply,
///     footer: {
///         if let error {
///             RetryButton(error: error)
///         }
///     },
///     emptyContent: {
///         Text("How can I help?")
///     }
/// )
/// ```
///
/// Or show messages of any kind your own way:
///
/// ```swift
/// AIConversationView(messages: messages, isSentByCurrentUser: \.isSentByCurrentUser) { message in
///     MessageRow(message: message)
/// }
/// ```
///
/// Rows your own way are laid out again each time the messages change. Make a row's view
/// `Equatable` and add `.equatable()`, so only the message that changed is.
///
/// Place the composer below the list, or over it with `safeAreaInset(edge: .bottom)`, so the
/// list knows how much of it is visible.
public struct AIConversationView<Message: Identifiable, MessageContent: View, Footer: View, EmptyContent: View>: View {
    // The rows and whether the agent is thinking, which can depend on the messages on their way.
    var content: (AIPendingMessageTracker) -> (messages: [Message], isThinking: Bool)
    var isSentByCurrentUser: (Message) -> Bool
    var loadOlderMessages: (@MainActor () async -> Void)?
    var messageContent: (Message) -> MessageContent
    var footer: Footer
    var emptyContent: EmptyContent

    @State private var shownAbove: Above?
    @State private var lastTurnID: Message.ID?
    // Where the turns in view are, read when what is above them changes.
    @State private var positions = AITurnPositions()
    @State private var clock = AIThinkingClock()
    @State private var tracker = AIPendingMessageTracker()
    @State private var isEndInView = true

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Injected(\.aiAppearance.tokens.layout) private var layout

    /// - Parameters:
    ///   - messages: The conversation, oldest message first.
    ///   - isSentByCurrentUser: Whether the person using the app sent a message. Each of their
    ///     messages starts a turn.
    ///   - isThinking: Whether the agent is answering the latest message and its reply shows
    ///     nothing yet. Meanwhile the latest turn ends with an ``AIThinkingView``, and the
    ///     reply's first reasoning step, shown with ``StreamingReasoningView``, takes over its
    ///     seconds.
    ///   - loadOlderMessages: Loads the messages before the first one, which the list asks for
    ///     as the person scrolls to its start. It shows a spinner meanwhile, and what is on
    ///     screen stays in place as they arrive. Pass nil once there are none left.
    ///   - messageContent: The view of a message.
    ///   - footer: A view under the latest turn's messages, such as what the agent is doing, or
    ///     an error with a way to retry.
    ///   - emptyContent: What the list shows while there are no messages, centered in it.
    public init(
        messages: [Message],
        isSentByCurrentUser: @escaping (Message) -> Bool,
        isThinking: Bool = false,
        loadOlderMessages: (@MainActor () async -> Void)? = nil,
        @ViewBuilder messageContent: @escaping (Message) -> MessageContent,
        @ViewBuilder footer: () -> Footer = { EmptyView() },
        @ViewBuilder emptyContent: () -> EmptyContent = { EmptyView() }
    ) {
        self.init(
            content: { _ in (messages, isThinking) },
            isSentByCurrentUser: isSentByCurrentUser,
            loadOlderMessages: loadOlderMessages,
            messageContent: messageContent,
            footer: footer(),
            emptyContent: emptyContent()
        )
    }

    init(
        content: @escaping (AIPendingMessageTracker) -> (messages: [Message], isThinking: Bool),
        isSentByCurrentUser: @escaping (Message) -> Bool,
        loadOlderMessages: (@MainActor () async -> Void)?,
        messageContent: @escaping (Message) -> MessageContent,
        footer: Footer,
        emptyContent: EmptyContent
    ) {
        self.content = content
        self.isSentByCurrentUser = isSentByCurrentUser
        self.loadOlderMessages = loadOlderMessages
        self.messageContent = messageContent
        self.footer = footer
        self.emptyContent = emptyContent
    }

    public var body: some View {
        let (messages, isThinking) = content(tracker)
        let turns = AIMessageTurn.turns(of: messages, isSentByCurrentUser: isSentByCurrentUser)
        let above = Above(firstTurnID: turns.first?.id, loadsOlder: loadOlderMessages != nil)
        // Both repeat harmlessly on every update: a turn's thinking starts and ends once, and
        // what is above the turns is noted only when it changes.
        clock.update(latest: turns.last.map { clock.key(for: $0.id) }, isThinking: isThinking)
        positions.expect(above: above)
        let animation: Animation? = reduceMotion ? nil : .default
        return GeometryReader { geometry in
            let height = geometry.size.height
            let slack = layout.spacingXl
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 0) {
                        if turns.isEmpty {
                            emptyContent
                                .frame(maxWidth: .infinity, minHeight: height)
                        } else {
                            turnStack(turns, isThinking: isThinking, height: height)
                        }

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
                    positions.update(frames)
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
                            guard let last = turns.last?.id else { return }
                            withAnimation(animation) {
                                proxy.scrollTo(last, anchor: .bottom)
                            }
                        }
                        .padding(.bottom, layout.spacingXs)
                        .transition(.opacity.combined(with: .scale(scale: 0.8)))
                    }
                }
                .onAppear {
                    shownAbove = above
                    lastTurnID = turns.last?.id
                    if let last = turns.last?.id {
                        Self.scrollToEnd(at: last, with: proxy)
                    }
                }
                .modifier(OnChange(value: above) {
                    let previous = shownAbove
                    shownAbove = above
                    // Older messages arrived above what is in view, or the spinner came or went:
                    // the turn at the top goes back to where it was, rather than being pushed.
                    guard previous?.firstTurnID != nil,
                          let held = positions.heldTurn(among: Set(turns.map { AnyHashable($0.id) })),
                          let turnID = turns.first(where: { AnyHashable($0.id) == held.id })?.id else {
                        positions.release()
                        return
                    }
                    let anchor = held.anchor(in: height)
                    DispatchQueue.main.async {
                        proxy.scrollTo(turnID, anchor: anchor)
                        positions.release()
                    }
                })
                .modifier(OnChange(value: turns.last?.id) {
                    let scroll = AIConversationScroll(previousLastTurnID: lastTurnID, turnIDs: turns.map(\.id))
                    lastTurnID = turns.last?.id
                    // Scrolls once the new turn is laid out, at least as tall as the list.
                    DispatchQueue.main.async {
                        switch scroll {
                        case let .toTop(turnID):
                            withAnimation(animation) {
                                proxy.scrollTo(turnID, anchor: .top)
                            }
                        case .toEnd:
                            if let last = turns.last?.id {
                                Self.scrollToEnd(at: last, with: proxy)
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
    private static func scrollToEnd(at last: Message.ID, with proxy: ScrollViewProxy) {
        proxy.scrollTo(last, anchor: .bottom)
        DispatchQueue.main.async {
            proxy.scrollTo(last, anchor: .bottom)
        }
    }

    // What sits above the turns in view. When it changes, they would be pushed down or up.
    private struct Above: Hashable {
        var firstTurnID: Message.ID?
        var loadsOlder: Bool
    }

    // The turns, the latest at least as tall as the list, after a spinner while older messages
    // can still load.
    private func turnStack(_ turns: [AIMessageTurn<Message>], isThinking: Bool, height: CGFloat) -> some View {
        LazyVStack(spacing: layout.spacingXs) {
            if let loadOlderMessages {
                // Loads again whenever the first turn changes while the spinner is in view, so a
                // short conversation fills the list.
                OlderMessagesLoadingView()
                    .task(id: turns.first?.id) {
                        await loadOlderMessages()
                    }
            }
            ForEach(turns) { turn in
                let isLatest = turn.id == turns.last?.id
                AIMessageTurnView(
                    messages: turn.messages,
                    spacing: layout.spacingMd,
                    isThinking: isLatest && isThinking,
                    footer: isLatest ? footer : nil,
                    messageContent: messageContent
                )
                .environment(\.aiThinkingTurn, AIThinkingTurn(clock: clock, key: clock.key(for: turn.id)))
                .padding(.top, layout.spacingMd)
                .frame(minHeight: isLatest ? height : nil, alignment: .top)
                .background {
                    GeometryReader { frame in
                        Color.clear.preference(
                            key: AITurnFrames.self,
                            value: [AnyHashable(turn.id): frame.frame(in: .named(AIConversationEnd.space))]
                        )
                    }
                }
            }
        }
        .padding(.horizontal, layout.spacingMd)
        .padding(.bottom, layout.spacingMd)
    }
}

private enum AIConversationEnd {
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
