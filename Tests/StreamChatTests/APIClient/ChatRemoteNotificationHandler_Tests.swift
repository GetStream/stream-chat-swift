//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
@testable import UserNotifications
import XCTest

final class ChatRemoteNotificationHandler_Tests: XCTestCase {
    var webSocketClient: WebSocketClient_Mock!
    var apiClient: APIClient_Spy!
    var database: DatabaseContainer_Spy!
    var channelRepository: ChannelRepository_Mock!
    var messageRepository: MessageRepository_Mock!
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
        channelRepository = ChannelRepository_Mock(database: database, apiClient: apiClient)
        messageRepository = MessageRepository_Mock(database: database, apiClient: apiClient)

        var env = ChatClient.Environment()
        env.databaseContainerBuilder = { _, _ in self.database }
        env.apiClientBuilder = { _, _, _, _, _ in self.apiClient }
        env.messageRepositoryBuilder = { _, _ in self.messageRepository }
        env.channelRepositoryBuilder = { _, _ in self.channelRepository }

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
        messageRepository = nil
        channelRepository = nil
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
    
    func test_handleNotification_whenChannelIsFetchedWithoutMessage_thenChannelAndMessageAreFetched() throws {
        let cid = ChannelId.unique
        let expectation = XCTestExpectation()
        let expectedChannel = ChatChannel.mock(cid: cid)
        let expectedMessage = ChatMessage.mock()
        channelRepository.getChannel_result = .success(expectedChannel)
        messageRepository.getMessageResult = .success(expectedMessage)
        
        let content = createNotificationContent(cid: expectedChannel.cid, messageId: expectedMessage.id)
        let handler = ChatRemoteNotificationHandler(client: clientWithOffline, content: content)
        let canHandle = handler.handleNotification { pushNotificationContent in
            switch pushNotificationContent {
            case .message(let messageNotificationContent):
                let messageResult = messageNotificationContent.message
                XCTAssertEqual(expectedMessage, messageResult)
                let channelResult = messageNotificationContent.channel
                XCTAssertEqual(expectedChannel, channelResult)
            case .unknown(let unknownNotificationContent):
                XCTFail(unknownNotificationContent.content.debugDescription)
            }
            expectation.fulfill()
        }
        XCTAssertEqual(true, canHandle)
        wait(for: [expectation], timeout: defaultTimeout)
        
        XCTAssertEqual(["getChannel(for:store:completion:)"], channelRepository.recordedFunctions)
        XCTAssertEqual(["getMessage(cid:messageId:store:completion:)"], messageRepository.recordedFunctions)
        XCTAssertEqual(false, channelRepository.getChannel_store)
        XCTAssertEqual(false, messageRepository.getMessage_store)
    }
    
    func test_handleNotification_whenChannelIsFetchedWithMessage_thenOnlyChannelIsFetched() throws {
        let cid = ChannelId.unique
        let expectation = XCTestExpectation()
        let expectedMessage = ChatMessage.mock()
        let expectedChannel = ChatChannel.mock(cid: cid, latestMessages: [expectedMessage])
        channelRepository.getChannel_result = .success(expectedChannel)
        messageRepository.getMessageResult = .failure(TestError())
        
        let content = createNotificationContent(cid: expectedChannel.cid, messageId: expectedMessage.id)
        let handler = ChatRemoteNotificationHandler(client: clientWithOffline, content: content)
        let canHandle = handler.handleNotification { pushNotificationContent in
            switch pushNotificationContent {
            case .message(let messageNotificationContent):
                let messageResult = messageNotificationContent.message
                XCTAssertEqual(expectedMessage, messageResult)
                let channelResult = messageNotificationContent.channel
                XCTAssertEqual(expectedChannel, channelResult)
            case .unknown(let unknownNotificationContent):
                XCTFail(unknownNotificationContent.content.debugDescription)
            }
            expectation.fulfill()
        }
        XCTAssertEqual(true, canHandle)
        wait(for: [expectation], timeout: defaultTimeout)
        
        XCTAssertEqual(["getChannel(for:store:completion:)"], channelRepository.recordedFunctions)
        XCTAssertEqual([], messageRepository.recordedFunctions, "Message was fetched with channel")
        XCTAssertEqual(false, channelRepository.getChannel_store)
        XCTAssertEqual(nil, messageRepository.getMessage_store)
    }
    
    func test_handleNotification_whenChannelFetchFails_thenMessageIsStillFetched() throws {
        let cid = ChannelId.unique
        let expectation = XCTestExpectation()
        let expectedChannel: ChatChannel? = nil
        let expectedMessage = ChatMessage.mock()
        channelRepository.getChannel_result = .failure(TestError())
        messageRepository.getMessageResult = .success(expectedMessage)
        
        let content = createNotificationContent(cid: cid, messageId: expectedMessage.id)
        let handler = ChatRemoteNotificationHandler(client: clientWithOffline, content: content)
        let canHandle = handler.handleNotification { pushNotificationContent in
            switch pushNotificationContent {
            case .message(let messageNotificationContent):
                let messageResult = messageNotificationContent.message
                XCTAssertEqual(expectedMessage, messageResult)
                let channelResult = messageNotificationContent.channel
                XCTAssertEqual(expectedChannel, channelResult)
            case .unknown(let unknownNotificationContent):
                XCTFail(unknownNotificationContent.content.debugDescription)
            }
            expectation.fulfill()
        }
        XCTAssertEqual(true, canHandle)
        wait(for: [expectation], timeout: defaultTimeout)
        
        XCTAssertEqual(["getChannel(for:store:completion:)"], channelRepository.recordedFunctions)
        XCTAssertEqual(["getMessage(cid:messageId:store:completion:)"], messageRepository.recordedFunctions)
        XCTAssertEqual(false, channelRepository.getChannel_store)
        XCTAssertEqual(false, messageRepository.getMessage_store)
    }
    
    func test_handleNotification_whenChannelAndMessageFetchFails_thenErrorIsReturned() throws {
        let cid = ChannelId.unique
        let expectation = XCTestExpectation()
        channelRepository.getChannel_result = .failure(TestError())
        messageRepository.getMessageResult = .failure(TestError())
        
        let content = createNotificationContent(cid: cid, messageId: .unique)
        let handler = ChatRemoteNotificationHandler(client: clientWithOffline, content: content)
        let canHandle = handler.handleNotification { pushNotificationContent in
            switch pushNotificationContent {
            case .message:
                XCTFail("Should fail with error")
            case .unknown:
                break
            }
            expectation.fulfill()
        }
        XCTAssertEqual(true, canHandle)
        wait(for: [expectation], timeout: defaultTimeout)
        
        XCTAssertEqual(["getChannel(for:store:completion:)"], channelRepository.recordedFunctions)
        XCTAssertEqual(["getMessage(cid:messageId:store:completion:)"], messageRepository.recordedFunctions)
        XCTAssertEqual(false, channelRepository.getChannel_store)
        XCTAssertEqual(false, messageRepository.getMessage_store)
    }

    func test_handleNotification_whenPushNotificationTypeIsRecognizable() throws {
        let cid = ChannelId.unique
        let expectation = XCTestExpectation()
        let expectedChannel = ChatChannel.mock(cid: cid)
        let expectedMessage = ChatMessage.mock()
        channelRepository.getChannel_result = .success(expectedChannel)
        messageRepository.getMessageResult = .success(expectedMessage)

        let notificationTypes: [String: PushNotificationType] = [
            "message.new": .messageNew,
            "reaction.new": .reactionNew,
            "notification.reminder_due": .messageReminderDue,
            "message.updated": .messageUpdated
        ]

        var assertions: [Bool] = []
        expectation.expectedFulfillmentCount = notificationTypes.count

        for notificationType in notificationTypes {
            let content = createNotificationContent(
                cid: expectedChannel.cid,
                messageId: expectedMessage.id,
                type: notificationType.key
            )
            let handler = ChatRemoteNotificationHandler(client: clientWithOffline, content: content)
            let canHandle = handler.handleNotification { pushNotificationContent in
                switch pushNotificationContent {
                case .message(let messageNotificationContent):
                    assertions.append(messageNotificationContent.type == notificationType.value)
                case .unknown(let unknownNotificationContent):
                    XCTFail(unknownNotificationContent.content.debugDescription)
                }
                expectation.fulfill()
            }

            XCTAssertEqual(true, canHandle)
        }

        wait(for: [expectation], timeout: defaultTimeout)
        XCTAssertEqual(assertions, Array(repeatElement(true, count: notificationTypes.count)))
    }

    func test_handleNotification_whenPushNotificationTypeNotRecognizable() throws {
        let cid = ChannelId.unique
        let expectation = XCTestExpectation()
        let expectedChannel = ChatChannel.mock(cid: cid)
        let expectedMessage = ChatMessage.mock()
        channelRepository.getChannel_result = .success(expectedChannel)
        messageRepository.getMessageResult = .success(expectedMessage)

        let content = createNotificationContent(
            cid: expectedChannel.cid,
            messageId: expectedMessage.id,
            type: "unknown.new"
        )
        let handler = ChatRemoteNotificationHandler(client: clientWithOffline, content: content)
        let canHandle = handler.handleNotification { pushNotificationContent in
            switch pushNotificationContent {
            case .message:
                XCTFail()
            case .unknown:
                expectation.fulfill()
            }
        }

        XCTAssertEqual(true, canHandle)
        wait(for: [expectation], timeout: defaultTimeout)
    }

    // MARK: -
    
    func createNotificationContent(cid: ChannelId, messageId: MessageId, type: String = "message.new") -> UNNotificationContent {
        let content = UNMutableNotificationContent()
        let payload: [String: String] = [
            "type": type,
            "cid": cid.rawValue,
            "id": messageId
        ]
        content.userInfo["stream"] = payload
        content.categoryIdentifier = "stream.chat"
        return content
    }
}
