//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChat

/// Resolves layout options for the message at given `indexPath`.
open class ChatMessageLayoutOptionsResolver {
    /// The maximum time interval between 2 consecutive messages sent by the same user to treat them as a single message group.
    public let maxTimeIntervalBetweenMessagesInGroup: TimeInterval

    /// Creates new `ChatMessageLayoutOptionsResolver`.
    ///
    /// - Parameter maxTimeIntervalBetweenMessagesInGroup: The maximum time interval between 2 consecutive messages sent by the same user to treat them as a single message group (`60 sec` by default).
    public init(maxTimeIntervalBetweenMessagesInGroup: TimeInterval = 60) {
        self.maxTimeIntervalBetweenMessagesInGroup = maxTimeIntervalBetweenMessagesInGroup
    }

    /// Calculates layout options for the message.
    /// - Parameters:
    ///   - indexPath: The index path of the cell displaying the message.
    ///   - channel: The channel message is related to.
    ///   - messages: The list of messages in the channel.
    ///   - appearance: The appearance theme in use.
    /// - Returns: The layout options describing the components and layout of message content view.
    open func optionsForMessage(
        at indexPath: IndexPath,
        in channel: ChatChannel,
        with messages: AnyRandomAccessCollection<ChatMessage>,
        appearance: Appearance
    ) -> ChatMessageLayoutOptions {
        // Make sure the message exists. Sometimes when switching channels really fast on iPad's split view,
        // it can happen that this method is called for old data from a previous channel.
        guard indexPath.item < messages.count else {
            return []
        }

        let messageIndex = messages.index(messages.startIndex, offsetBy: indexPath.item)
        let message = messages[messageIndex]

        let isLastInSequence = isMessageLastInSequence(
            messageIndexPath: indexPath,
            messages: messages
        )
        
        var options: ChatMessageLayoutOptions = []

        // The text should be centered without a bubble for system or error messages
        guard message.type != .system && message.type != .error else {
            return [.text, .centered]
        }

        // Do not show bubble if the message is to be rendered as large emoji
        if !message.shouldRenderAsJumbomoji {
            options.insert(.bubble)
        }

        if message.isSentByCurrentUser {
            options.insert(.flipped)
        }
        if !isLastInSequence {
            options.insert(.continuousBubble)
        }
        if !isLastInSequence && !message.isSentByCurrentUser {
            options.insert(.avatarSizePadding)
        }
        if isLastInSequence {
            options.insert(.timestamp)
        }
        if message.isOnlyVisibleForCurrentUser {
            options.insert(.onlyVisibleForYouIndicator)
        }
        if message.textContent?.isEmpty == false {
            options.insert(.text)
        }
        if isLastInSequence && !message.isSentByCurrentUser {
            options.insert(.avatar)
        }
        if isLastInSequence && !message.isSentByCurrentUser && channel.memberCount > 2 {
            options.insert(.authorName)
        }
        
        guard message.isDeleted == false else {
            return options
        }
        
        if hasQuotedMessage(message) {
            options.insert(.quotedMessage)
        }
        if channel.config.repliesEnabled && (message.isRootOfThread || message.isPartOfThread) {
            options.insert(.threadInfo)
            // The bubbles with thread look like continuous bubbles
            options.insert(.continuousBubble)
        }
        if hasReactions(channel, message, appearance) {
            options.insert(.reactions)
        }
        if message.isLastActionFailed {
            options.insert(.errorIndicator)
        }

        return options
    }

    func hasQuotedMessage(_ message: ChatMessage) -> Bool {
        message.quotedMessage?.id != nil
    }

    func hasReactions(_ channel: ChatChannel, _ message: ChatMessage, _ appareance: Appearance) -> Bool {
        if !channel.config.reactionsEnabled {
            return false
        }

        if message.reactionScores.isEmpty {
            return false
        }

        let unhandledReactionTypes = message.latestReactions.filter { appareance.images.availableReactions[$0.type] == nil }
            .map(\.type)

        if !unhandledReactionTypes.isEmpty {
            log.warning("message contains unhandled reaction types \(unhandledReactionTypes)")
        }

        return !message.latestReactions.filter { appareance.images.availableReactions[$0.type] != nil }.isEmpty
    }

    /// Says whether the message at given `indexPath` is the last one in a sequence of messages
    /// sent by a single user where the time delta between near by messages
    /// is `<= maxTimeIntervalBetweenMessagesInGroup`.
    ///
    /// Returns `true` if one of the following conditions is met:
    ///     1. the message at `messageIndexPath` is the most recent one in the channel
    ///     2. the message sent after the message at `messageIndexPath` has different author
    ///     3. the message sent after the message at `messageIndexPath` has the same author but the
    ///     time delta between messages is bigger than `maxTimeIntervalBetweenMessagesInGroup`
    ///     4. the message sent after the message at `messageIndexPath` is of `error` type
    ///
    /// - Parameters:
    ///   - messageIndexPath: The index path of the target message.
    ///   - messages: The list of loaded channel messages.
    /// - Returns: Returns `true` if the message ends the sequence of messages from a single author.
    open func isMessageLastInSequence(
        messageIndexPath: IndexPath,
        messages: AnyRandomAccessCollection<ChatMessage>
    ) -> Bool {
        let messageIndex = messages.index(messages.startIndex, offsetBy: messageIndexPath.item)
        guard let message = messages[safe: messageIndex] else {
            indexNotFoundAssertion()
            return true
        }

        // The current message is the last message so it's either a standalone or last in sequence.
        guard messageIndexPath.item > 0 else { return true }

        let nextMessageIndex = messages.index(before: messageIndex)
        guard let nextMessage = messages[safe: nextMessageIndex] else {
            indexNotFoundAssertion()
            return true
        }

        // The message after the current one has different author so the current message
        // is either a standalone or last in sequence.
        guard nextMessage.author == message.author else { return true }

        // When the next message is of error type (e.g. contains invalid command/didn't pass moderation),
        // the current message should end the group.
        guard nextMessage.type != .error else { return true }
        
        let delay = nextMessage.createdAt.timeIntervalSince(message.createdAt)

        // If the message next to the current one is sent with delay > maxTimeIntervalBetweenMessagesInGroup,
        // the current message ends the sequence.
        return delay > maxTimeIntervalBetweenMessagesInGroup
    }
}
