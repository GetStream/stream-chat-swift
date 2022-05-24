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
    
    func saveEphemeralMessage(_ message: [String: Any]?) {
        guard let newMessage = message else { return }
        let idKey = MessagePayloadsCodingKeys.id.rawValue
        if let index = ephemeralMessageList.firstIndex(where: { (message) -> Bool in
            (newMessage[idKey] as? String) == (message[idKey] as? String)
        }) {
            ephemeralMessageList[index] = newMessage
        } else {
            ephemeralMessageList.append(newMessage)
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
    
    func findEphemeralMessageById(_ id: String) -> [String: Any]? {
        return ephemeralMessageList.first(where: {
            ($0[MessagePayloadsCodingKeys.id.rawValue] as? String) == id
        })
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
        let ephemeralMessages = ephemeralMessageList.filter {
            String(describing: $0[cid]).contains(":\(channelId)")
        }
        var messages = messageList.filter {
            String(describing: $0[cid]).contains(":\(channelId)")
        }
        messages += ephemeralMessages
        return messages
    }
    
    func removeEphemeralMessage(id: String) {
        let deletedMessage = findEphemeralMessageById(id)
        let idKey = MessagePayloadsCodingKeys.id.rawValue
        if let deletedIndex = ephemeralMessageList.firstIndex(where: { (message) -> Bool in
            (message[idKey] as? String) == (deletedMessage?[idKey] as? String)
        }) {
            ephemeralMessageList.remove(at: deletedIndex)
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
