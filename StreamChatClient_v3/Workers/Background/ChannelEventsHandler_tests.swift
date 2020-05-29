//
// ChannelEventsHandler_tests.swift
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import CoreData
@testable import StreamChatClient_v3
import XCTest

class ChannelEventsHandlerTests: XCTestCase {
  var worker: ChannelEventsHandler<DefaultDataTypes>!

  var database: DatabaseContainer!
  var webSocketClient: WebSocketClientMock!
  var apiClient: APIClientMock!

  override func setUp() {
    super.setUp()

    database = try! DatabaseContainer(kind: .inMemory)
    webSocketClient = WebSocketClientMock()
    apiClient = APIClientMock()

    worker = ChannelEventsHandler<DefaultDataTypes>(
      database: database,
      webSocketClient: webSocketClient,
      apiClient: apiClient
    )
  }

  func test_AddedToChannelEvent_isHandled() {
    let member = User(id: "test_user_\(UUID().uuidString)", name: "Luke", avatarURL: nil)
    let channel = Channel(id: "test_channel_\(UUID().uuidString)", extraData: nil, members: [member])
    let event = AddedToChannel(channel: channel)

    webSocketClient.simulate(event: event)

    var loadedChannel: Channel? { database.viewContext.loadChannel(id: channel.id) }
    AssertAsync {
      Assert.willBeEqual(loadedChannel?.id, channel.id)
      Assert.willBeEqual(loadedChannel?.members, channel.members)
    }
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

    super.init(
      urlRequest: URLRequest(url: URL(string: "test")!),
      eventDecoder: MockDecoder(),
      callbackQueue: .main
    )
  }
}

class APIClientMock: APIClient {
  init() {
    super.init(apiKey: "", baseURL: URL(string: "test")!, sessionConfiguration: .default)
  }
}
