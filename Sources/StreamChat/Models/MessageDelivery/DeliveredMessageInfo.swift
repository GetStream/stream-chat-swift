//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

/// Represents information about a delivered message for a specific channel.
public struct MessageDeliveryInfo: Equatable {
    /// The channel identifier where the message was delivered.
    public let channelId: ChannelId
    
    /// The message identifier that was delivered.
    public let messageId: MessageId
    
    /// Creates a new `MessageDeliveryInfo` instance.
    ///
    /// - Parameters:
    ///   - channelId: The channel identifier where the message was delivered.
    ///   - messageId: The message identifier that was delivered.
    public init(channelId: ChannelId, messageId: MessageId) {
        self.channelId = channelId
        self.messageId = messageId
    }
}

// MARK: - Conversion to Payload

extension MessageDeliveryInfo {
    /// Converts this model to its corresponding payload representation.
    var asPayload: DeliveredMessagePayload {
        DeliveredMessagePayload(cid: channelId, id: messageId)
    }
}
