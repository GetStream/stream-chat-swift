//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

/// A mock implementation of `MessageDeliveryCriteriaValidating` for testing purposes.
final class MessageDeliveryCriteriaValidator_Mock: MessageDeliveryCriteriaValidating {
    var canMarkMessageAsDeliveredClosure: ((ChatMessage, CurrentChatUser, ChatChannel) -> Bool)?
    var canMarkMessageAsDeliveredCallCount = 0
    var canMarkMessageAsDeliveredCalledWithMessage: ChatMessage?
    var canMarkMessageAsDeliveredCalledWithCurrentUser: CurrentChatUser?
    var canMarkMessageAsDeliveredCalledWithChannel: ChatChannel?
    
    func canMarkMessageAsDelivered(
        _ message: ChatMessage,
        for currentUser: CurrentChatUser,
        in channel: ChatChannel
    ) -> Bool {
        canMarkMessageAsDeliveredCallCount += 1
        canMarkMessageAsDeliveredCalledWithMessage = message
        canMarkMessageAsDeliveredCalledWithCurrentUser = currentUser
        canMarkMessageAsDeliveredCalledWithChannel = channel
        
        return canMarkMessageAsDeliveredClosure?(message, currentUser, channel) ?? false
    }
    
    func reset() {
        canMarkMessageAsDeliveredClosure = nil
        canMarkMessageAsDeliveredCallCount = 0
        canMarkMessageAsDeliveredCalledWithMessage = nil
        canMarkMessageAsDeliveredCalledWithCurrentUser = nil
        canMarkMessageAsDeliveredCalledWithChannel = nil
    }
}
