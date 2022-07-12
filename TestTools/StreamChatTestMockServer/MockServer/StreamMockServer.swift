//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import Swifter
import Foundation

public final class StreamMockServer {

    // Delays all HTTP responses by given time interval, 0 by default
    public static var httpResponseDelay: TimeInterval = 0.0
    // Waits for all HTTP and Websocket responses during given time interval, 10 by default
    public static var waitTimeout = 10.0

    public private(set) var server: HttpServer = HttpServer()
    private weak var globalSession: WebSocketSession?
    private var channelConfigs = ChannelConfigs()
    public var messageList: [[String: Any]] = []
    public var channelList = TestData.toJson(.httpChannels)
    public var currentChannelId = ""
    public var channelsEndpointWasCalled = false
    public var channelQueryEndpointWasCalled = false
    public var latestWebsocketMessage = ""
    public var latestHttpMessage = ""
    public let forbiddenWords: Set<String> = ["wth"]

    public init() {}

    public func start(port: UInt16) {
        do {
            try server.start(port)
            print("Server status: \(server.state). Port: \(port)")
        } catch {
            print("Server start error: \(error)")
        }
    }
    
    public func stop() {
        server.stop()
    }

    public func configure() {
        StreamMockServer.httpResponseDelay = 0.0
        configureWebsockets()
        configureEventEndpoints()
        configureChannelEndpoints()
        configureReactionEndpoints()
        configureMessagingEndpoints()
        configureAttachmentEndpoints()
    }
    
    public func writeText(_ text: String) {
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

public extension StreamMockServer {

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

public extension StreamMockServer {

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
        channel[ChannelCodingKeys.cooldownDuration.rawValue] = cooldown.isEnabled ? cooldown.duration : nil
    }
}
