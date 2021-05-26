//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChat

/// Resolves layout options for the message at given `indexPath`.
public typealias ChatMessageLayoutOptionsResolver = _ChatMessageLayoutOptionsResolver<NoExtraData>

/// Resolves layout options for the message at given `indexPath`.
open class _ChatMessageLayoutOptionsResolver<ExtraData: ExtraDataTypes> {
    /// The minimum time interval between messages to treat them as a single message group.
    public let minTimeIntervalBetweenMessagesInGroup: TimeInterval

    /// Creates the `_ChatMessageLayoutOptionsResolver` with the given `minTimeIntervalBetweenMessagesInGroup` value
    public init(minTimeIntervalBetweenMessagesInGroup: TimeInterval = 10) {
        self.minTimeIntervalBetweenMessagesInGroup = minTimeIntervalBetweenMessagesInGroup
    }

    /// Calculates layout options for the message.
    /// - Parameters:
    ///   - indexPath: The index path of the cell displaying the message.
    ///   - channel: The channel message is related to.
    ///   - messages: The list of messages in the channel.
    /// - Returns: The layout options describing the components and layout of message content view.
    open func optionsForMessage(
        at indexPath: IndexPath,
        in channel: _ChatChannel<ExtraData>,
        with messages: AnyRandomAccessCollection<_ChatMessage<ExtraData>>
    ) -> ChatMessageLayoutOptions {
        let messageIndex = messages.index(messages.startIndex, offsetBy: indexPath.item)
        let message = messages[messageIndex]

        let isLastInGroup: Bool = {
            guard indexPath.item > 0 else { return true }

            let nextMessageIndex = messages.index(messages.startIndex, offsetBy: indexPath.item - 1)
            let nextMessage = messages[nextMessageIndex]

            guard nextMessage.author == message.author else { return true }

            let delay = nextMessage.createdAt.timeIntervalSince(message.createdAt)

            return delay > minTimeIntervalBetweenMessagesInGroup
        }()

        var options: ChatMessageLayoutOptions = [
            .bubble
        ]

        if message.isSentByCurrentUser {
            options.insert(.flipped)
        }
        if !isLastInGroup {
            options.insert(.continuousBubble)
        }
        if !isLastInGroup && !message.isSentByCurrentUser {
            options.insert(.avatarSizePadding)
        }
        if isLastInGroup {
            options.insert(.metadata)
        }
        if message.isOnlyVisibleForCurrentUser {
            options.insert(.onlyVisibleForYouIndicator)
        }
        if message.textContent?.isEmpty == false {
            options.insert(.text)
        }

        guard message.isDeleted == false else {
            return options
        }

        if isLastInGroup && !message.isSentByCurrentUser {
            options.insert(.avatar)
        }
        if isLastInGroup && !message.isSentByCurrentUser && !channel.isDirectMessageChannel {
            options.insert(.authorName)
        }
        if message.quotedMessage?.id != nil {
            options.insert(.quotedMessage)
        }
        if message.isRootOfThread {
            options.insert(.threadInfo)
            // The bubbles with thread look like continuous bubbles
            options.insert(.continuousBubble)
        }
        if !message.reactionScores.isEmpty && channel.config.reactionsEnabled {
            options.insert(.reactions)
        }
        if message.lastActionFailed {
            options.insert(.errorIndicator)
        }

        return options
    }
}
