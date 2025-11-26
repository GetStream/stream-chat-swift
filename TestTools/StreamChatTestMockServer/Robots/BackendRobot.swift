//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation
import XCTest

public class BackendRobot {
    private let mockServer: StreamMockServer

    public init(_ mockServer: StreamMockServer) {
        self.mockServer = mockServer
    }

    @discardableResult
    public func generateChannels(
        channelsCount: Int,
        messagesCount: Int = 0,
        repliesCount: Int = 0,
        attachments: Bool = false,
        messagesText: String? = nil,
        repliesText: String? = nil
    ) -> BackendRobot {
        waitForMockServerToStart()
        var messagesTextQueryParam = ""
        if let messagesText {
            messagesTextQueryParam = "messages_text=\(messagesText)&"
        }
        var repliesTextQueryParam = ""
        if let repliesText {
            repliesTextQueryParam = "replies_text=\(repliesText)&"
        }
        var attachmentsQueryParam = ""
        if attachments {
            attachmentsQueryParam = "attachments=true&"
        }
        let endpoint = "mock?" +
            messagesTextQueryParam +
            repliesTextQueryParam +
            attachmentsQueryParam +
            "channels=\(channelsCount)&" +
            "messages=\(messagesCount)&" +
            "replies=\(repliesCount)"
        _ = mockServer.postRequest(endpoint: endpoint)
        return self
    }

    @discardableResult
    public func failNewMessages() -> BackendRobot {
        _ = mockServer.postRequest(endpoint: "fail_messages")
        return self
    }
    
    @discardableResult
    public func delayNewMessages(by seconds: Int) -> BackendRobot {
        _ = mockServer.postRequest(endpoint: "delay_messages?delay=\(seconds)")
        return self
    }

    public func revokeToken(duration: Int = 5) {
        waitForMockServerToStart()
        _ = mockServer.postRequest(endpoint: "jwt/revoke_token?duration=\(duration)")
    }

    public func invalidateToken(duration: Int = 5) {
        waitForMockServerToStart()
        _ = mockServer.postRequest(endpoint: "jwt/invalidate_token?duration=\(duration)")
    }

    public func invalidateTokenDate(duration: Int = 5) {
        waitForMockServerToStart()
        _ = mockServer.postRequest(endpoint: "jwt/invalidate_token_date?duration=\(duration)")
    }

    public func invalidateTokenSignature(duration: Int = 5) {
        waitForMockServerToStart()
        _ = mockServer.postRequest(endpoint: "jwt/invalidate_token_signature?duration=\(duration)")
    }

    public func breakTokenGeneration(duration: Int = 5) {
        waitForMockServerToStart()
        _ = mockServer.postRequest(endpoint: "jwt/break_token_generation?duration=\(duration)")
    }
    
    public func setReadEvents(to value: Bool) {
        waitForMockServerToStart()
        _ = mockServer.postRequest(endpoint: "config/read_events?value=\(value)")
    }
    
    public func setCooldown(enabled: Bool, duration: Int) {
        waitForMockServerToStart()
        _ = mockServer.postRequest(endpoint: "config/cooldown?enabled=\(enabled)&duration=\(duration)")
    }

    private func waitForMockServerToStart() {
        let startTime = Date().timeIntervalSince1970
        while Date().timeIntervalSince1970 - startTime < 5.0 {
            var request = URLRequest(url: URL(string: "\(StreamMockServer.url!)/ping")!)
            request.httpMethod = "GET"
            request.timeoutInterval = 1.0

            let semaphore = DispatchSemaphore(value: 0)
            var responseCode: Int?
            let task = URLSession.shared.dataTask(with: request) { _, response, _ in
                if let httpResponse = response as? HTTPURLResponse {
                    responseCode = httpResponse.statusCode
                }
                semaphore.signal()
            }
            task.resume()
            semaphore.wait()

            if responseCode == 200 {
                return
            }

            Thread.sleep(forTimeInterval: 0.5)
        }
        XCTFail("MockServer did not start within 5 seconds")
    }
}
