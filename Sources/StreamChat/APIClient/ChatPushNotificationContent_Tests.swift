//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
@testable import UserNotifications
import XCTest

class ChatPushNotificationContent_Tests: XCTestCase {
    var webSocketClient: WebSocketClientMock!
    var apiClient: APIClientMock!
    var database: DatabaseContainerMock!
    var currentUserUpdater: CurrentUserUpdater!
    var clientWithOffline: ChatClient!
    let apiKey: APIKey = .init("123")
    var testMessage: ChatMessage!
    var exampleMessageNotificationContent: UNMutableNotificationContent!
    var exampleMessagePayload: MessagePayload.Boxed!
    
    override func setUp() {
        super.setUp()

        var configOffline = ChatClientConfig(apiKey: apiKey)
        configOffline.isLocalStorageEnabled = true

        clientWithOffline = ChatClient(config: configOffline)

        webSocketClient = WebSocketClientMock()
        apiClient = APIClientMock()
        database = DatabaseContainerMock()

        var env = ChatClient.Environment()
        env.databaseContainerBuilder = { _, _, _, _, _, _ in self.database }
        env.apiClientBuilder = { _, _, _, _, _ in self.apiClient }
        
        clientWithOffline = ChatClient(
            config: configOffline,
            workerBuilders: [],
            environment: env
        )
        
        let cid: ChannelId = .unique
        let msgID: MessageId = .unique

        exampleMessagePayload = .init(
            message: .dummy(messageId: msgID, authorUserId: .unique, channel: ChannelDetailPayload.dummy(cid: cid))
        )

        exampleMessageNotificationContent = UNMutableNotificationContent()
        exampleMessageNotificationContent.userInfo["stream"] = [
            "type": "message.new",
            "cid": cid.rawValue,
            "id": msgID
        ]
        exampleMessageNotificationContent.categoryIdentifier = "stream.chat"
    }

    override func tearDown() {
        apiClient.cleanUp()
        super.tearDown()
    }

    func testEmptyContentNotHandled() throws {
        let content = UNNotificationContent()
        let handler = ChatRemoteNotificationHandler(client: clientWithOffline, content: content)
        XCTAssertFalse(handler.handleNotification(completion: { _ in }))
    }

    func testContentWithoutCategoryNotHandled() throws {
        let content = UNMutableNotificationContent()
        let payload = [
            "type": "message.new",
            "cid": "a:b",
            "id": "42"
        ]
        content.userInfo["stream"] = payload
        let handler = ChatRemoteNotificationHandler(client: clientWithOffline, content: content)
        XCTAssertFalse(handler.handleNotification(completion: { _ in }))
    }

    func testContentHandled() throws {
        let content = UNMutableNotificationContent()
        let payload = [
            "type": "message.new",
            "cid": "a:b",
            "id": "42"
        ]
        content.userInfo["stream"] = payload
        content.categoryIdentifier = "stream.chat"
        let handler = ChatRemoteNotificationHandler(client: clientWithOffline, content: content)
        XCTAssertTrue(handler.handleNotification(completion: { _ in }))
    }
    
    func testCompletion() throws {
        let handler = ChatRemoteNotificationHandler(client: clientWithOffline, content: exampleMessageNotificationContent)
        let expectation = XCTestExpectation(description: "Receive a message content")

        XCTAssertTrue(handler.handleNotification(completion: { notification in
            expectation.fulfill()

            guard case .message = notification else {
                XCTFail()
                return
            }
        }))

        apiClient.test_simulateResponse(Result<MessagePayload.Boxed, Error>.success(exampleMessagePayload))
        wait(for: [expectation], timeout: defaultTimeout)
    }
    
    func testCompletion_withUnknownEvent() throws {
        let content = UNMutableNotificationContent()
        content.userInfo["stream"] = [
            "type": "message.deleted"
        ]
        content.categoryIdentifier = "stream.chat"

        let handler = ChatRemoteNotificationHandler(client: clientWithOffline, content: content)
        let expectation = XCTestExpectation(description: "Receive a message content")

        XCTAssertTrue(handler.handleNotification(completion: { notification in
            expectation.fulfill()
            
            guard case .unknown = notification else {
                XCTFail()
                return
            }
        }))
    }
}
