//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

/// A validator responsible for determining whether a message can be marked as delivered
/// based on various criteria including channel state, user settings, and message properties.
protocol MessageDeliveryCriteriaValidating {
    /// Determines if a message can be marked as delivered for a specific user in a channel.
    ///
    /// - Parameters:
    ///   - message: The message to check for delivery status.
    ///   - currentUser: The current user who would mark the message as delivered.
    ///   - channel: The channel containing the message.
    /// - Returns: `true` if the message can be marked as delivered, `false` otherwise.
    func canMarkMessageAsDelivered(
        _ message: ChatMessage,
        for currentUser: CurrentChatUser,
        in channel: ChatChannel
    ) -> Bool
}

/// Default implementation of message delivery criteria validation.
struct MessageDeliveryCriteriaValidator: MessageDeliveryCriteriaValidating {
    init() {}
    
    /// Determines if a message can be marked as delivered for a specific user in a channel.
    ///
    /// A message can be marked as delivered when all of the following conditions are met:
    /// - The channel can be marked as delivered (not muted, not hidden)
    /// - The current user has delivery receipts enabled in privacy settings
    /// - The message is not a thread reply (unless it's shown in the channel)
    /// - The message was not sent by the current user
    /// - The message is not shadowed
    /// - The message author is not muted by the current user
    /// - The current user has a read state in the channel
    /// - The message was created after the user's last read timestamp
    /// - The message was created after the user's last delivered timestamp
    ///
    /// - Parameters:
    ///   - message: The message to check for delivery status.
    ///   - currentUser: The current user who would mark the message as delivered.
    ///   - channel: The channel containing the message.
    /// - Returns: `true` if the message can be marked as delivered, `false` otherwise.
    func canMarkMessageAsDelivered(
        _ message: ChatMessage,
        for currentUser: CurrentChatUser,
        in channel: ChatChannel
    ) -> Bool {
        guard channel.canBeMarkedAsDelivered else {
            return false
        }
        
        // Check if delivery receipts are enabled in privacy settings
        guard currentUser.privacySettings.deliveryReceipts?.enabled ?? true else {
            return false
        }

        if message.parentMessageId != nil && !message.showReplyInChannel {
            return false
        }

        guard message.author.id != currentUser.id else {
            return false
        }

        if message.isShadowed {
            return false
        }

        if currentUser.mutedUsers.map(\.id).contains(message.author.id) {
            return false
        }

        if let userRead = channel.read(for: currentUser.id) {
            return message.createdAt >= userRead.lastReadAt
                && message.createdAt >= userRead.lastDeliveredAt ?? .distantPast
        }

        return true
    }
}

private extension ChatChannel {
    var canBeMarkedAsDelivered: Bool {
        config.deliveryEventsEnabled && !isMuted && !isHidden
    }
}
