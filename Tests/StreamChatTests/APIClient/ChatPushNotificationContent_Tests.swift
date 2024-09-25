//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
@testable import UserNotifications
import XCTest

final class ChatPushNotificationContent_Tests: XCTestCase {
    var webSocketClient: WebSocketClient_Mock!
    var apiClient: APIClient_Spy!
    var database: DatabaseContainer_Spy!
    var messageRepository: MessageRepository_Mock!
    var extensionLifecycle: NotificationExtensionLifecycle_Mock!
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

        webSocketClient = WebSocketClient_Mock()
        apiClient = APIClient_Spy()
        database = DatabaseContainer_Spy()
        messageRepository = MessageRepository_Mock(database: database, apiClient: apiClient)
        extensionLifecycle = NotificationExtensionLifecycle_Mock(appGroupIdentifier: "test")

        var env = ChatClient.Environment()
        env.databaseContainerBuilder = { _, _, _, _, _, _ in self.database }
        env.apiClientBuilder = { _, _, _, _, _ in self.apiClient }
        env.extensionLifecycleBuilder = { _ in self.extensionLifecycle }
        env.messageRepositoryBuilder = { _, _ in self.messageRepository }

        clientWithOffline = ChatClient_Mock(
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
        webSocketClient = nil
        apiClient.cleanUp()
        apiClient = nil
        database = nil
        currentUserUpdater = nil
        clientWithOffline = nil
        testMessage = nil
        exampleMessageNotificationContent = nil
        exampleMessagePayload = nil
        super.tearDown()
    }

    func test_notHandled_whenEmptyContent() throws {
        let content = UNNotificationContent()
        let handler = ChatRemoteNotificationHandler(client: clientWithOffline, content: content)
        XCTAssertFalse(handler.handleNotification(completion: { _ in }))
    }

    func test_notHandled_whenContentWithoutCategory() throws {
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

    func test_contentHandled_whenCorrectPayload() throws {
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

    func test_contentHandled_newMessage_appIsReceivingWebSocketEvents() {
        extensionLifecycle.mockIsAppReceivingWebSocketEvents = true

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
        // Should only store the fetched message if the host app is not listening to events
        XCTAssert(messageRepository.receivedGetMessageStore == false)
    }

    func test_contentHandled_newMessage_appIsNotReceivingWebSocketEvents() {
        extensionLifecycle.mockIsAppReceivingWebSocketEvents = false

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
        // Should only store the fetched message if the host app is not listening to events
        XCTAssert(messageRepository.receivedGetMessageStore == true)
    }

    func test_callsCompletion_whenHandled() throws {
        let handler = ChatRemoteNotificationHandler(client: clientWithOffline, content: exampleMessageNotificationContent)
        let expectation = XCTestExpectation(description: "Receive a message content")

        messageRepository.getMessageResult = .success(ChatMessage.mock())
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

    func test_callsCompletion_whenProcessingUnknownEvent() throws {
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
