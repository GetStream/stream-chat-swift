//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import XCTest

public extension StreamMockServer {
    
    func saveMessage(_ message: [String: Any]?) {
        guard let newMessage = message else { return }
        if let index = messageList.firstIndex(where: { (message) -> Bool in
            (newMessage[messageKey.id.rawValue] as? String) == (message[messageKey.id.rawValue] as? String)
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
            ($0[messageKey.parentId.rawValue] as? String) == parentId
        }
    }
    
    func findMessagesByChannelId(_ channelId: String) -> [[String: Any]] {
        return messageList.filter {
            String(describing: $0[messageKey.cid.rawValue]).contains(":\(channelId)")
        }
    }
    
    func removeMessage(_ deletedMessage: [String: Any]?) {
        if let deletedIndex = messageList.firstIndex(where: { (message) -> Bool in
            (message[messageKey.id.rawValue] as? String) == (deletedMessage?[messageKey.id.rawValue] as? String)
        }) {
            messageList.remove(at: deletedIndex)
        }
    }
    
    func removeMessage(id: String) {
        let deletedMessage = try? XCTUnwrap(waitForMessageWithId(id))
        removeMessage(deletedMessage)
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
                ($0[messageKey.id.rawValue] as? String) == id
            }
        }
        return newMessageList.first
    }
    
    private func waitForMessageWithUserId(_ userId: String) -> [String: Any]? {
        let endTime = TestData.waitingEndTime
        var newMessageList: [[String: Any]] = []
        while newMessageList.isEmpty && endTime > TestData.currentTimeInterval {
            newMessageList = messageList.filter {
                let user = $0[messageKey.user.rawValue] as? [String: Any]
                return (user?[userKey.id.rawValue] as? String) == userId
            }
        }
        return newMessageList.first
    }
    
    func waitForWebsocketMessage(withText text: String,
                                 timeout: Double = StreamMockServer.waitTimeout) {
        let endTime = Date().timeIntervalSince1970 * 1000 + timeout * 1000
        while latestWebsocketMessage != text
                && endTime > Date().timeIntervalSince1970 * 1000 {
            print("Waiting for websocket message with text: '\(text)'")
        }
    }
    
    func waitForHttpMessage(withText text: String,
                            timeout: Double = StreamMockServer.waitTimeout) {
        let endTime = Date().timeIntervalSince1970 * 1000 + timeout * 1000
        while latestHttpMessage != text
                && endTime > Date().timeIntervalSince1970 * 1000 {
            print("Waiting for http message with text: '\(text)'")
        }
    }
}
