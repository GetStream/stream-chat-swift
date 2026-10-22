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

    // Where the turns in view are, read when what is above them changes.
    @State private var positions = AITurnPositions()
    @State private var clock = AIThinkingClock()
    @State private var tracker = AIPendingMessageTracker()

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
        let above = AIConversationScrollView.Above(
            firstTurnID: turns.first.map { AnyHashable($0.id) },
            loadsOlder: loadOlderMessages != nil
        )
        // Both repeat harmlessly on every update: a turn's thinking starts and ends once, and
        // what is above the turns is noted only when it changes.
        clock.update(
            latest: turns.last.map { clock.key(for: $0.id) },
            isThinking: isThinking,
            hasReplies: (turns.last?.messages.count ?? 0) > 1
        )
        positions.expect(above: above)
        return AIConversationScrollView(
            turnIDs: turns.map { AnyHashable($0.id) },
            above: above,
            positions: positions,
            scrollTo: { id, anchor, proxy in
                guard let turn = turns.first(where: { AnyHashable($0.id) == id }) else { return }
                proxy.scrollTo(turn.id, anchor: anchor)
            },
            content: { height in
                AnyView(turnList(turns, isThinking: isThinking, height: height))
            }
        )
    }

    @ViewBuilder
    private func turnList(_ turns: [AIMessageTurn<Message>], isThinking: Bool, height: CGFloat) -> some View {
        if turns.isEmpty {
            emptyContent
                .frame(maxWidth: .infinity, minHeight: height)
        } else {
            turnStack(turns, isThinking: isThinking, height: height)
        }
    }

    // The turns, the latest at least as tall as the list, after a spinner while older messages
    // can still load.
    private func turnStack(_ turns: [AIMessageTurn<Message>], isThinking: Bool, height: CGFloat) -> some View {
        LazyVStack(spacing: layout.spacingXs) {
            if let loadOlderMessages {
                // Loads once the spinner has stayed in view a moment, rather than for the frame a
                // list that opens at its end can show its start, and again whenever the first
                // turn changes while it is in view.
                OlderMessagesLoadingView()
                    .task(id: turns.first?.id) {
                        try? await Task.sleep(nanoseconds: 300_000_000)
                        guard !Task.isCancelled else { return }
                        await loadOlderMessages()
                    }
            }
            ForEach(turns) { turn in
                let isLatest = turn.id == turns.last?.id
                VStack(alignment: .leading, spacing: layout.spacingMd) {
                    ForEach(turn.messages) { message in
                        messageContent(message)
                    }
                    if isLatest && isThinking {
                        AIThinkingView()
                    }
                    if isLatest {
                        footer
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
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
