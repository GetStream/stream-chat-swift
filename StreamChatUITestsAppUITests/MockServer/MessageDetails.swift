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
    
    func getMessageDetails(messageId: String) -> [MessageDetail: String] {
        waitForMessageDetails().first(where: { $0[.messageId] == messageId })
    }
    
    func getMessageDetails() -> [MessageDetail: String] {
        waitForMessageDetails().last!
    }
    
    func removeMessageDetails(messageId: String) {
        let deletedMessage = messageDetails.first(where: { $0[.messageId] == messageId })
        let deletedIndex = messageDetails.firstIndex(of: deletedMessage)!
        messageDetails.remove(at: deletedIndex)
    }
    
    func clearMessageDetails() {
        messageDetails = []
    }
    
    private func waitForMessageDetails() -> [[MessageDetail: String]] {
        let endTime = Date().timeIntervalSince1970 * 1000 + 2000
        while messageDetails.isEmpty && endTime > Date().timeIntervalSince1970 * 1000 {}
        return messageDetails
    }
}
