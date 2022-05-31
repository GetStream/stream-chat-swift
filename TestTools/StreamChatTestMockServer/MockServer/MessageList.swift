//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import XCTest

public extension StreamMockServer {
    
    func saveMessage(_ message: [String: Any]?) {
        guard let newMessage = message else { return }
        let idKey = MessagePayloadsCodingKeys.id.rawValue
        if let index = messageList.firstIndex(where: { (message) -> Bool in
            (newMessage[idKey] as? String) == (message[idKey] as? String)
        }) {
            messageList[index] = newMessage
        } else {
            messageList.append(newMessage)
        }
    }
    
    var firstMessage: [String: Any]? {
        try? XCTUnwrap(waitForMessageList().first)
    }
    
    var lastMessage: [String: Any]? {
        try? XCTUnwrap(waitForMessageList().last)
    }
    
    func findMessageByIndex(_ index: Int) -> [String: Any]? {
        try? XCTUnwrap(waitForMessageList()[index])
    }
    
    func findMessageById(_ id: String) -> [String: Any]? {
        try? XCTUnwrap(waitForMessageWithId(id))
    }
    
    func findMessageByUserId(_ userId: String) -> [String: Any]? {
        try? XCTUnwrap(waitForMessageWithUserId(userId))
    }
    
    func findMessagesByParrentId(_ parentId: String) -> [[String: Any]] {
        _ = waitForMessageWithId(parentId)
        return messageList.filter {
            ($0[MessagePayloadsCodingKeys.parentId.rawValue] as? String) == parentId
        }
    }
    
    func findMessagesByChannelId(_ channelId: String) -> [[String: Any]] {
        let cid = MessagePayloadsCodingKeys.cid.rawValue
        return messageList.filter {
            String(describing: $0[cid]).contains(":\(channelId)")
        }
    }
    
    func removeMessage(id: String) {
        let deletedMessage = try? XCTUnwrap(waitForMessageWithId(id))
        let idKey = MessagePayloadsCodingKeys.id.rawValue
        if let deletedIndex = messageList.firstIndex(where: { (message) -> Bool in
            (message[idKey] as? String) == (deletedMessage?[idKey] as? String)
        }) {
            messageList.remove(at: deletedIndex)
        }
    }
    
    @discardableResult
    private func waitForMessageList() -> [[String: Any]] {
        let endTime = TestData.waitingEndTime
        while messageList.isEmpty && endTime > TestData.currentTimeInterval {}
        return messageList
    }
    
    private func waitForMessageWithId(_ id: String) -> [String: Any]? {
        let endTime = TestData.waitingEndTime
        var newMessageList: [[String: Any]] = []
        while newMessageList.isEmpty && endTime > TestData.currentTimeInterval {
            newMessageList = messageList.filter {
                ($0[MessagePayloadsCodingKeys.id.rawValue] as? String) == id
            }
        }
        return newMessageList.first
    }
    
    private func waitForMessageWithUserId(_ userId: String) -> [String: Any]? {
        let endTime = TestData.waitingEndTime
        var newMessageList: [[String: Any]] = []
        while newMessageList.isEmpty && endTime > TestData.currentTimeInterval {
            newMessageList = messageList.filter {
                let user = $0[MessagePayloadsCodingKeys.user.rawValue] as? [String: Any]
                return (user?[UserPayloadsCodingKeys.id.rawValue] as? String) == userId
            }
        }
        return newMessageList.first
    }
}
