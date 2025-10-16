//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

/// A mock implementation of `ChannelDeliveryTracker` for testing purposes.
final class ChannelDeliveryTracker_Mock: ChannelDeliveryTracker {
    init() {
        super.init(
            currentUserUpdater: CurrentUserUpdater_Mock(
                database: DatabaseContainer_Spy(),
                apiClient: APIClient_Spy()
            )
        )
    }

    /// The number of times `submitForDelivery` was called.
    var submitForDelivery_callCount = 0
    
    /// The parameters passed to the last `submitForDelivery` call.
    var submitForDelivery_channelId: ChannelId?
    var submitForDelivery_messageId: MessageId?
    
    /// The number of times `cancel` was called.
    var cancel_callCount = 0
    
    /// The parameters passed to the last `cancel` call.
    var cancel_channelId: ChannelId?
    
    override func submitForDelivery(channelId: ChannelId, messageId: MessageId) {
        submitForDelivery_callCount += 1
        submitForDelivery_channelId = channelId
        submitForDelivery_messageId = messageId
    }
    
    override func cancel(channelId: ChannelId) {
        cancel_callCount += 1
        cancel_channelId = channelId
    }
    
    /// Resets all mock data.
    func cleanUp() {
        submitForDelivery_callCount = 0
        submitForDelivery_channelId = nil
        submitForDelivery_messageId = nil
        cancel_callCount = 0
        cancel_channelId = nil
    }
}
