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
    private var channelConfigs = ChannelConfigs()
    
    var messageList: [[String: Any]] {
        get {
            return self._messageList
        }
        set {
            self._messageList = newValue
        }
    }
    
    var channelList: [String: Any] {
        get {
            return self._channelList
        }
        set {
            self._channelList = newValue
        }
    }
    
    var currentChannelId: String {
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

// MARK: Config

extension StreamMockServer {

    func config(forChannelId id: String) -> ChannelConfig_Mock? {
        channelConfigs.config(forChannelId: id, server: self)
    }

    func updateConfig(config: ChannelConfig_Mock, forChannelWithId id: String) {
        channelConfigs.updateConfig(config: config, forChannelWithId: id, server: self)
    }

    func updateConfig(in channel: inout [String: Any], withId id: String) {
        channelConfigs.updateChannel(channel: &channel, withId: id)
    }
}

extension StreamMockServer {

    func setCooldown(enabled: Bool, duration: Int, inChannelWithId id: String) {
        channelConfigs.setCooldown(enabled: enabled, duration: duration)

        var json = channelList
        guard
            var channels = json[JSONKey.channels] as? [[String: Any]],
            let channelIndex = channelIndex(withId: id),
            var channel = channel(withId: id),
            var innerChannel = channel[JSONKey.channel] as? [String: Any]
        else {
            return
        }

        setCooldown(in: &innerChannel)
        channel[JSONKey.channel] = innerChannel
        channels[channelIndex] = channel
        json[JSONKey.channels] = channels
        channelList = json
    }

    func setCooldown(in channel: inout [String: Any]) {
        let cooldown = channelConfigs.coolDown
        channel["cooldown"] = cooldown.isEnabled ? cooldown.duration : nil
    }
}
