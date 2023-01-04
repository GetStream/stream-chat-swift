//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import XCTest

public extension StreamMockServer {

    func saveMessage(_ message: [String: Any]?) {
        guard let newMessage = message else { return }

        let newMessageId = newMessage[messageKey.id.rawValue] as? String
        if let messageIndex = messageList.firstIndex(where: { (message) -> Bool in
            let existedMessageId = message[messageKey.id.rawValue] as? String
            return newMessageId == existedMessageId
        }) {
            messageList[messageIndex] = newMessage
        } else {
            messageList.append(newMessage)
        }
    }

    func saveReply(_ message: [String: Any]?) {
        guard let newMessage = message else { return }

        let newMessageId = newMessage[messageKey.id.rawValue] as? String
        if let messageIndex = threadList.firstIndex(where: { (message) -> Bool in
            let existedMessageId = message[messageKey.id.rawValue] as? String
            return newMessageId == existedMessageId
        }) {
            threadList[messageIndex] = newMessage
        } else {
            threadList.append(newMessage)
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

    func findMessagesByParentId(_ parentId: String) -> [[String: Any]] {
        _ = waitForMessageWithId(parentId)
        return (messageList + threadList).filter {
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

    func mockMessagePagination(
        messageList: [[String: Any]],
        limit: Int,
        idLt: String?,
        idGt: String?,
        idLte: String?,
        idGte: String?
    ) -> [[String: Any]] {
        var newMessageList: [[String: Any]] = []
        if let idLt = idLt {
            let messageIndex = messageList.firstIndex {
                idLt == $0[messageKey.id.rawValue] as? String
            }
            if let messageIndex = messageIndex {
                let startWith = messageIndex - limit > 0 ? messageIndex - limit : 0
                let endWith = messageIndex - 1 > 0 ? messageIndex - 1 : 0
                newMessageList = Array(messageList[startWith...endWith])
            }
        } else if let idGt = idGt {
            let messageIndex = messageList.firstIndex {
                idGt == $0[messageKey.id.rawValue] as? String
            }
            if let messageIndex = messageIndex {
                let messageCount = messageList.count - 1
                let plusLimit = messageIndex + limit
                let endWith = plusLimit < messageCount ? plusLimit : messageCount
                newMessageList = Array(messageList[messageIndex + 1...endWith])
            }
        } else if let idLte = idLte {
            let messageIndex = messageList.firstIndex {
                idLte == $0[messageKey.id.rawValue] as? String
            }
            if let messageIndex = messageIndex {
                let minusLimit = messageIndex - limit
                let startWith = minusLimit > 0 ? minusLimit : 0
                newMessageList = Array(messageList[startWith + 1...messageIndex])
            }
        } else if let idGte = idGte {
            let messageIndex = messageList.firstIndex {
                idGte == $0[messageKey.id.rawValue] as? String
            }
            if let messageIndex = messageIndex {
                let messageCount = messageList.count - 1
                let plusLimit = messageIndex + limit
                let endWith = plusLimit < messageCount ? plusLimit - 1 : messageCount
                newMessageList = Array(messageList[messageIndex...endWith])
            }
        } else {
            newMessageList = Array(messageList.suffix(limit))
        }
        return newMessageList
    }
}
