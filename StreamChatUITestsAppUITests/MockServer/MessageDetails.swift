//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import XCTest

extension StreamMockServer {
    
    func saveMessageDetails(
        messageId: String,
        text: String,
        createdAt: String,
        updatedAt: String
    ) {
        messageDetails.append([
            .messageId: messageId,
            .text: text,
            .createdAt: createdAt,
            .updatedAt: updatedAt
        ])
    }
    
    func getMessageDetails(messageId: String) -> Dictionary<MessageDetail, String> {
        waitForMessageDetails().filter { $0[.messageId] == messageId }.first!
    }
    
    func getMessageDetails() -> Dictionary<MessageDetail, String> {
        waitForMessageDetails().last!
    }
    
    func removeMessageDetails(messageId: String) {
        let deletedMessage = messageDetails.filter { $0[.messageId] == messageId }.first!
        let deletedIndex = messageDetails.firstIndex(of: deletedMessage)!
        messageDetails.remove(at: deletedIndex)
    }
    
    func clearMessageDetails() {
        messageDetails = []
    }
    
    private func waitForMessageDetails() -> [Dictionary<MessageDetail, String>] {
        let endTime = Date().timeIntervalSince1970 * 1000 + 2000
        while messageDetails.isEmpty && endTime > Date().timeIntervalSince1970 * 1000 {}
        return messageDetails
    }
}
