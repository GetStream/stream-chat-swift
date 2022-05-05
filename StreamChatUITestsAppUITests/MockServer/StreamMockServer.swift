//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import Swifter
import Foundation

final class StreamMockServer {

    // Delays all HTTP responses by given time interval, 0 by default
    static var httpResponseDelay: TimeInterval = 0.0

    // This constant is used inside `websocketDelay` func that delays websocket requests and responses by given time interval, 1 by default
    var websocketDelay: TimeInterval = 1.0

    private(set) var server: HttpServer = HttpServer()
    private weak var globalSession: WebSocketSession?
    private var _messageList: [[String: Any]] = []
    private var _channelList = TestData.toJson(.httpChannels)
    private var _currentChannelId: String = ""
    
    public var messageList: [[String: Any]] {
        get {
            return self._messageList
        }
        set {
            self._messageList = newValue
        }
    }
    
    public var channelList: [String: Any] {
        get {
            return self._channelList
        }
        set {
            self._channelList = newValue
        }
    }
    
    public var currentChannelId: String {
        get {
            return self._currentChannelId
        }
        set {
            self._currentChannelId = newValue
        }
    }
    
    func start(port: UInt16) {
        do {
            try server.start(port)
            print("Server status: \(server.state). Port: \(port)")
        } catch {
            print("Server start error: \(error)")
        }
    }
    
    func stop() {
        server.stop()
    }

    func configure() {
        StreamMockServer.httpResponseDelay = 0.0
        configureWebsockets()
        configureEventEndpoints()
        configureChannelEndpoints()
        configureReactionEndpoints()
        configureMessagingEndpoints()
    }
    
    func writeText(_ text: String) {
        globalSession?.writeText(text)
    }
    
    private func configureWebsockets() {
        server[MockEndpoint.connect] = websocket(connected: { [weak self] session in
            self?.globalSession = session
            self?.healthCheck()
        }, disconnected: { [weak self] _ in
            self?.globalSession = nil
        })
    }
    
    private func healthCheck() {
        writeText(TestData.getMockResponse(fromFile: .wsHealthCheck))
    }
}
