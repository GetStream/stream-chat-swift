//
// ChannelEventsHandler_Tests.swift
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import CoreData
@testable import StreamChatClient_v3
import XCTest

class ChannelEventsHandler_Tests: XCTestCase {
    var worker: ChannelEventsHandler<DefaultDataTypes>!
    
    var database: DatabaseContainer!
    var webSocketClient: WebSocketClientMock!
    var apiClient: APIClientMock!
    
    override func setUp() {
        super.setUp()
        
        database = try! DatabaseContainer(kind: .inMemory)
        webSocketClient = WebSocketClientMock()
        apiClient = APIClientMock()
        
        worker = ChannelEventsHandler<DefaultDataTypes>(database: database,
                                                        webSocketClient: webSocketClient,
                                                        apiClient: apiClient)
    }
    
    func test_AddedToChannelEvent_isHandled() {
        // TODO: Saving the data must happen in the middleware so we're sure the data is saved before the event is published
        
//    let member = User(id: "test_user_\(UUID().uuidString)", name: "Luke", avatarURL: nil)
//    let channel = ChannelEndpointPayload(id: "test_channel_\(UUID().uuidString)", extraData: nil, members: [member])
//    let event = AddedToChannel(channel: channel)
//
//    webSocketClient.simulate(event: event)
//
//    var loadedChannel: Channel? { database.viewContext.loadChannel(id: channel.id.id) }
//    AssertAsync {
//      Assert.willBeEqual(loadedChannel?.id, channel.id)
//      Assert.willBeEqual(loadedChannel?.members, channel.members)
//    }
    }
}

// Where to put these????

class WebSocketClientMock: WebSocketClient {
    func simulate(event: Event) {
        notificationCenter.post(Notification(newEventReceived: event, sender: self))
    }
    
    init() {
        struct MockDecoder: AnyEventDecoder {
            func decode(data: Data) throws -> Event { fatalError() }
        }
        
        super.init(urlRequest: URLRequest(url: URL(string: "test")!),
                   eventDecoder: MockDecoder(),
                   eventMiddlewares: [])
    }
}

class APIClientMock: APIClient {
    init() {
        super.init(apiKey: APIKey("test_app"), baseURL: URL(string: "test")!, sessionConfiguration: .default)
    }
}
