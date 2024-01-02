//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import Foundation
import XCTest

public final class StreamMockServer {

    // Delays all HTTP responses by given time interval, 0 by default
    public static var httpResponseDelay: TimeInterval = 0.0
    // Waits for all HTTP and Websocket responses during given time interval, 10 by default
    public static var waitTimeout = 10.0
    // Expires JWT after given timeout if `MOCK_JWT environment variable is provided
    public static let jwtTimeout: UInt32 = 5

    public private(set) var server: HttpServer = HttpServer()
    private weak var globalSession: WebSocketSession?
    private var channelConfigs = ChannelConfigs()
    public var threadList: [[String: Any]] = []
    public var messageList: [[String: Any]] = []
    public var channelList = TestData.toJson(.httpChannels)
    public var currentChannelId = ""
    public var channelsEndpointWasCalled = false
    public var channelQueryEndpointWasCalled = false
    public var allChannelsWereLoaded = false
    public var latestWebsocketMessage = ""
    public var latestHttpMessage = ""
    public let forbiddenWords: Set<String> = ["wth"]
    public var pushNotificationPayload: [String: Any] = [:]
    public var userDetails: [String: Any]? = [:]

    public init() {}

    public func start(port: UInt16) -> Bool {
        do {
            try server.start(port)
            print("Server status: \(server.state). Port: \(port)")
            return true
        } catch {
            print("Server start error: \(error)")
            return false
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
        configureMembersEndpoints()
    }

    public func writeText(_ text: String) {
        globalSession?.writeText(text)
    }

    private func configureWebsockets() {
        let websocket = websocket(connected: { [weak self] session in
            self?.globalSession = session
            self?.healthCheck()
        }, disconnected: { [weak self] _ in
            self?.globalSession = nil
        })
        
        server.register(MockEndpoint.connect) { [weak self] request in
            self?.userDetails = request.queryParams.first { $0.0 == "json" }?.1.removingPercentEncoding?.json
            return websocket(request)
        }
    }

    private func healthCheck() {
        writeText(TestData.getMockResponse(fromFile: .wsHealthCheck))
    }
}

// MARK: Shared

extension StreamMockServer {
    func findChannelById(_ id: String) -> [String: Any]? {
        try? XCTUnwrap(waitForChannelWithId(id))
    }
    
    func waitForChannelWithId(_ id: String) -> [String: Any]? {
        let endTime = TestData.waitingEndTime
        var newChannelList: [[String: Any]] = []
        while newChannelList.isEmpty && endTime > TestData.currentTimeInterval {
            guard let channels = channelList[JSONKey.channels] as? [[String: Any]] else { return nil }
            newChannelList = channels.filter {
                let channel = $0[JSONKey.channel] as? [String: Any]
                return id == channel?[channelKey.id.rawValue] as? String
            }
        }
        return newChannelList.first
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
        if cooldown.isEnabled {
            channel[channelKey.cooldownDuration.rawValue] = cooldown.duration
            var ownCapabilities = channel[channelKey.ownCapabilities.rawValue] as? [String]
            ownCapabilities?.removeAll { $0 == ChannelCapability.skipSlowMode.rawValue }
            channel[channelKey.ownCapabilities.rawValue] = ownCapabilities
        } else {
            channel[channelKey.cooldownDuration.rawValue] = nil
        }
    }
}
