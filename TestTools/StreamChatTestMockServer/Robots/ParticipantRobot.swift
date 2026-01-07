//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

public class ParticipantRobot {
    private let mockServer: StreamMockServer

    public let name: String = "Count Dooku"
    public let id: String = "count_dooku"

    public init(_ mockServer: StreamMockServer) {
        self.mockServer = mockServer
    }

    @discardableResult
    public func startTyping() -> ParticipantRobot {
        _ = mockServer.postRequest(endpoint: "participant/typing/start")
        return self
    }

    @discardableResult
    public func startTypingInThread() -> ParticipantRobot {
        _ = mockServer.postRequest(endpoint: "participant/typing/start?thread=true")
        return self
    }

    @discardableResult
    public func stopTyping() -> ParticipantRobot {
        _ = mockServer.postRequest(endpoint: "participant/typing/stop")
        return self
    }

    @discardableResult
    public func stopTypingInThread() -> ParticipantRobot {
        _ = mockServer.postRequest(endpoint: "participant/typing/stop?thread=true")
        return self
    }

    @discardableResult
    public func sleep(_ timeOutSeconds: TimeInterval) -> ParticipantRobot {
        Thread.sleep(forTimeInterval: timeOutSeconds)
        return self
    }

    @discardableResult
    public func readMessage() -> ParticipantRobot {
        _ = mockServer.postRequest(endpoint: "participant/read")
        return self
    }

    @discardableResult
    public func sendMessage(_ text: String, delay: Int = 0) -> ParticipantRobot {
        var endpoint = "participant/message"
        if delay > 0 {
            endpoint += "?delay=\(delay)"
        }
        let body = text.data(using: .utf8) ?? Data()
        _ = mockServer.postRequest(endpoint: endpoint, body: body)
        return self
    }

    @discardableResult
    public func sendPushNotification(
        title: String?,
        body: String,
        bundleId: String,
        rest: String? = nil
    ) -> ParticipantRobot {
        let udid = ProcessInfo.processInfo.environment["SIMULATOR_UDID"]!
        var endpoint = "participant/push?" +
            "bundle_id=\(bundleId)&" +
            "udid=\(udid)&" +
            "body=\(body)"
        if let title {
            endpoint += "&title=\(title)"
        }
        if let rest {
            endpoint += "&rest=\(rest)"
        }
        _ = mockServer.postRequest(endpoint: endpoint)
        return self
    }

    @discardableResult
    public func sendMultipleMessages(_ text: String, count: Int) -> ParticipantRobot {
        var texts = [String]()
        for index in 1...count {
            texts.append("\(text)-\(index)")
        }

        texts.forEach {
            sendMessage($0)
            sleep(0.3)
        }
        return self
    }

    @discardableResult
    public func sendMessageInThread(_ text: String, alsoSendInChannel: Bool = false) -> ParticipantRobot {
        let body = text.data(using: .utf8) ?? Data()
        _ = mockServer.postRequest(
            endpoint: "participant/message?thread=true&thread_and_channel=\(alsoSendInChannel)",
            body: body
        )
        return self
    }

    @discardableResult
    public func editMessage(_ text: String) -> ParticipantRobot {
        let body = text.data(using: .utf8) ?? Data()
        _ = mockServer.postRequest(
            endpoint: "participant/message?action=edit",
            body: body
        )
        return self
    }

    @discardableResult
    public func deleteMessage(hard: Bool = false) -> ParticipantRobot {
        _ = mockServer.postRequest(endpoint: "participant/message?action=delete&hard_delete=\(hard)")
        return self
    }

    @discardableResult
    public func quoteMessage(_ text: String, last: Bool = true) -> ParticipantRobot {
        let quote = last ? "quote_last=true" : "quote_first=true"
        let body = text.data(using: .utf8) ?? Data()
        _ = mockServer.postRequest(endpoint: "participant/message?\(quote)", body: body)
        return self
    }

    @discardableResult
    public func quoteMessageInThread(
        _ text: String,
        alsoSendInChannel: Bool = false,
        last: Bool = true
    ) -> ParticipantRobot {
        let quote = last ? "quote_last=true" : "quote_first=true"
        let body = text.data(using: .utf8) ?? Data()
        _ = mockServer.postRequest(
            endpoint: "participant/message?\(quote)&thread=true&thread_and_channel=\(alsoSendInChannel)",
            body: body
        )
        return self
    }

    @discardableResult
    public func uploadGiphy() -> ParticipantRobot {
        _ = mockServer.postRequest(endpoint: "participant/message?giphy=true")
        return self
    }

    @discardableResult
    public func uploadGiphyInThread() -> ParticipantRobot {
        _ = mockServer.postRequest(endpoint: "participant/message?giphy=true&thread=true")
        return self
    }

    @discardableResult
    public func quoteMessageWithGiphy(last: Bool = true) -> ParticipantRobot {
        let quote = last ? "quote_last=true" : "quote_first=true"
        _ = mockServer.postRequest(endpoint: "participant/message?giphy=true&\(quote)")
        return self
    }

    @discardableResult
    public func quoteMessageWithGiphyInThread(
        alsoSendInChannel: Bool = false,
        last: Bool = true
    ) -> ParticipantRobot {
        let quote = last ? "quote_last=true" : "quote_first=true"
        let endpoint = "participant/message?giphy=true&\(quote)&thread=true&thread_and_channel=\(alsoSendInChannel)"
        _ = mockServer.postRequest(endpoint: endpoint)
        return self
    }

    @discardableResult
    public func pinMesage() -> ParticipantRobot {
        _ = mockServer.postRequest(endpoint: "participant/message?action=pin")
        return self
    }

    @discardableResult
    public func unpinMesage() -> ParticipantRobot {
        _ = mockServer.postRequest(endpoint: "participant/message?action=unpin")
        return self
    }

    @discardableResult
    public func uploadAttachment(type: AttachmentType, count: Int = 1) -> ParticipantRobot {
        _ = mockServer.postRequest(endpoint: "participant/message?\(type.attachment)=\(count)")
        return self
    }

    @discardableResult
    public func quoteMessageWithAttachment(
        type: AttachmentType,
        count: Int = 1,
        last: Bool = true
    ) -> ParticipantRobot {
        let quote = last ? "quote_last=true" : "quote_first=true"
        _ = mockServer.postRequest(endpoint: "participant/message?\(quote)&\(type.attachment)=\(count)")
        return self
    }

    @discardableResult
    public func uploadAttachmentInThread(
        type: AttachmentType,
        count: Int = 1,
        alsoSendInChannel: Bool = false
    ) -> ParticipantRobot {
        let endpoint = "participant/message?\(type.attachment)=\(count)&thread=true&thread_and_channel=\(alsoSendInChannel)"
        _ = mockServer.postRequest(endpoint: endpoint)
        return self
    }

    @discardableResult
    public func quoteMessageWithAttachmentInThread(
        type: AttachmentType,
        count: Int = 1,
        alsoSendInChannel: Bool = false,
        last: Bool = true
    ) -> ParticipantRobot {
        let quote = last ? "quote_last=true" : "quote_first=true"
        let endpoint = "participant/message?" +
            "\(quote)&\(type.attachment)=\(count)&thread=true&thread_and_channel=\(alsoSendInChannel)"
        _ = mockServer.postRequest(endpoint: endpoint)
        return self
    }

    @discardableResult
    public func addReaction(type: ReactionType, delay: Int = 0) -> ParticipantRobot {
        var endpoint = "participant/reaction?type=\(type.reaction)"
        if delay > 0 {
            endpoint += "&delay=\(delay)"
        }
        _ = mockServer.postRequest(endpoint: endpoint)
        return self
    }

    @discardableResult
    public func deleteReaction(type: ReactionType) -> ParticipantRobot {
        _ = mockServer.postRequest(endpoint: "participant/reaction?type=\(type.reaction)&delete=true")
        return self
    }
}
