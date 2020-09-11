//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

@testable import StreamChatClient
import XCTest

class MessageSender_Tests: StressTestCase {
    typealias ExtraData = DefaultDataTypes
    
    var webSocketClient: WebSocketClientMock!
    var apiClient: APIClientMock!
    var database: DatabaseContainerMock!
    
    var sender: MessageSender<ExtraData>!
    
    var cid: ChannelId!
    
    override func setUp() {
        super.setUp()
        
        webSocketClient = WebSocketClientMock()
        apiClient = APIClientMock()
        database = try! DatabaseContainerMock(kind: .inMemory)
        
        sender = MessageSender(database: database, webSocketClient: webSocketClient, apiClient: apiClient)
        
        cid = .unique
        
        try! database.createCurrentUser()
        try! database.createChannel(cid: cid)
    }
    
    override func tearDown() {
        apiClient.cleanUp()
        
        AssertAsync {
            Assert.canBeReleased(&sender)
            Assert.canBeReleased(&webSocketClient)
            Assert.canBeReleased(&apiClient)
            Assert.canBeReleased(&database)
        }

        super.tearDown()
    }
    
    func test_senderSendsMessage_withPendingSendLocalState() throws {
        var message1Id: MessageId!
        var message2Id: MessageId!
        
        // Create 2 messages in the DB, only message 1 has `.pendingSend` local state
        try database.writeSynchronously { session in
            let message1 = try session.createNewMessage(
                in: self.cid,
                text: "Message pending send",
                extraData: ExtraData.Message.defaultValue
            )
            message1.localMessageState = .pendingSend
            message1Id = message1.id
            
            let message2 = try session.createNewMessage(
                in: self.cid,
                text: "Message without local state",
                extraData: ExtraData.Message.defaultValue
            )
            message2Id = message2.id
        }
        
        let message1Payload: MessageRequestBody<ExtraData> = try XCTUnwrap(
            database.viewContext.message(id: message1Id)?
                .asRequestBody()
        )
        let message2Payload: MessageRequestBody<ExtraData> = try XCTUnwrap(
            database.viewContext.message(id: message2Id)?
                .asRequestBody()
        )

        // Check only the message1 was sent
        AssertAsync {
            Assert.willBeTrue(self.apiClient.request_allRecordedCalls.contains(where: {
                $0.endpoint == AnyEndpoint(.sendMessage(cid: self.cid, messagePayload: message1Payload))
            }))
            
            Assert.staysFalse(self.apiClient.request_allRecordedCalls.contains(where: {
                $0.endpoint == AnyEndpoint(.sendMessage(cid: self.cid, messagePayload: message2Payload))
            }))
        }
    }
    
    func test_sender_changesMessageStates_whenSending() throws {
        var message1Id: MessageId!
        
        // Create a message with pendin state
        try database.writeSynchronously { session in
            let message1 = try session.createNewMessage(
                in: self.cid,
                text: "Message pending send",
                extraData: ExtraData.Message.defaultValue
            )
            message1.localMessageState = .pendingSend
            message1Id = message1.id
        }
        
        // Check the state is eventually changed to .sending
        AssertAsync.willBeEqual(database.viewContext.message(id: message1Id)?.localMessageState, .sending)
        
        // Wait for the API call to be initiated
        AssertAsync.willBeTrue(apiClient.request_endpoint != nil)
        
        // Simulate successfull API response
        let callback = apiClient.request_completion as! (Result<EmptyResponse, Error>) -> Void
        callback(.success(.init()))
        
        // Check the state is eventually changed to `nil`
        AssertAsync.willBeEqual(database.viewContext.message(id: message1Id)?.localMessageState, nil)
    }
    
    func test_sender_changesMessageStates_whenSendingFails() throws {
        var message1Id: MessageId!
        
        // Create a message with pendin state
        try database.writeSynchronously { session in
            let message1 = try session.createNewMessage(
                in: self.cid,
                text: "Message pending send",
                extraData: ExtraData.Message.defaultValue
            )
            message1.localMessageState = .pendingSend
            message1Id = message1.id
        }
        
        // Wait for the API call to be initiated
        AssertAsync.willBeTrue(apiClient.request_endpoint != nil)
        
        // Simulate error API response
        let callback = apiClient.request_completion as! (Result<EmptyResponse, Error>) -> Void
        callback(.failure(TestError()))
        
        // Check the state is eventually changed to `sendingFailed`
        AssertAsync.willBeEqual(database.viewContext.message(id: message1Id)?.localMessageState, .sendingFailed)
    }
    
    func test_senderSendsMessage_inTheOrderTheyWereCreatedLocally() throws {
        var message1Id: MessageId!
        var message2Id: MessageId!
        var message3Id: MessageId!
        
        // Create 3 messages in the DB, all with `.pendingSend` local state
        try database.writeSynchronously { session in
            let message1 = try session.createNewMessage(
                in: self.cid,
                text: "Message pending send 1",
                extraData: ExtraData.Message.defaultValue
            )
            message1.localMessageState = .pendingSend
            message1Id = message1.id

            let message2 = try session.createNewMessage(
                in: self.cid,
                text: "Message pending send 2",
                extraData: ExtraData.Message.defaultValue
            )
            message2.localMessageState = .pendingSend
            message2Id = message2.id

            let message3 = try session.createNewMessage(
                in: self.cid,
                text: "Message pending send 3",
                extraData: ExtraData.Message.defaultValue
            )
            message3.localMessageState = .pendingSend
            message3Id = message3.id
        }
        
        // Check the 1st API call
        let message1Payload: MessageRequestBody<ExtraData> = try XCTUnwrap(
            database.viewContext.message(id: message1Id)?
                .asRequestBody()
        )
        AssertAsync.willBeEqual(
            apiClient.request_endpoint,
            AnyEndpoint(.sendMessage(cid: cid, messagePayload: message1Payload))
        )
        
        // Simulate the first call response
        var callback: ((Result<EmptyResponse, Error>) -> Void) {
            apiClient.request_completion as! (Result<EmptyResponse, Error>) -> Void
        }
        callback(.success(.init()))
        
        // Check the 2nd API call
        let message2Payload: MessageRequestBody<ExtraData> = try XCTUnwrap(
            database.viewContext.message(id: message2Id)?
                .asRequestBody()
        )
        AssertAsync.willBeEqual(
            apiClient.request_endpoint,
            AnyEndpoint(.sendMessage(cid: cid, messagePayload: message2Payload))
        )
        
        // Simulate the second call response
        callback(.success(.init()))

        // Check the 3rd API call
        let message3Payload: MessageRequestBody<ExtraData> = try XCTUnwrap(
            database.viewContext.message(id: message3Id)?
                .asRequestBody()
        )
        AssertAsync.willBeEqual(
            apiClient.request_endpoint,
            AnyEndpoint(.sendMessage(cid: cid, messagePayload: message3Payload))
        )
        
        // Simulate the second call response
        callback(.success(.init()))
    }
    
    func test_senderSendsMessages_forMultipleChannelsInParalel_butStillInTheCorrectOrder() throws {
        let cidA = cid!
        let cidB = ChannelId.unique
        try database.createChannel(cid: cidB)
        
        var channelA_message1: MessageId!
        var channelA_message2: MessageId!

        var channelB_message1: MessageId!
        var channelB_message2: MessageId!

        // Create 2 new messages in two channel the DB
        try database.writeSynchronously { session in
            let messageA1 = try session.createNewMessage(
                in: cidA,
                text: "Channel A message 1",
                extraData: ExtraData.Message.defaultValue
            )
            messageA1.localMessageState = .pendingSend
            channelA_message1 = messageA1.id
            
            let messageA2 = try session.createNewMessage(
                in: cidA,
                text: "Channel A message 2",
                extraData: ExtraData.Message.defaultValue
            )
            messageA2.localMessageState = .pendingSend
            channelA_message2 = messageA2.id

            let messageB1 = try session.createNewMessage(
                in: cidB,
                text: "Channel B message 1",
                extraData: ExtraData.Message.defaultValue
            )
            messageB1.localMessageState = .pendingSend
            channelB_message1 = messageB1.id
            
            let messageB2 = try session.createNewMessage(
                in: cidB,
                text: "Channel B message 2",
                extraData: ExtraData.Message.defaultValue
            )
            messageB2.localMessageState = .pendingSend
            channelB_message2 = messageB2.id
        }
        
        // Wait for 2 API calls to be made
        AssertAsync.willBeEqual(apiClient.request_allRecordedCalls.count, 2)
        
        // Check the API calls are for the first messages from both channels
        let channelA_message1Payload: MessageRequestBody<ExtraData> = try XCTUnwrap(
            database.viewContext
                .message(id: channelA_message1)?.asRequestBody()
        )
        let channelB_message1Payload: MessageRequestBody<ExtraData> = try XCTUnwrap(
            database.viewContext
                .message(id: channelB_message1)?.asRequestBody()
        )

        XCTAssertTrue(apiClient.request_allRecordedCalls.contains(where: {
            $0.endpoint == AnyEndpoint(.sendMessage(cid: cidA, messagePayload: channelA_message1Payload))
        }))
        XCTAssertTrue(apiClient.request_allRecordedCalls.contains(where: {
            $0.endpoint == AnyEndpoint(.sendMessage(cid: cidB, messagePayload: channelB_message1Payload))
        }))

        // Simulate successfull responses for both API calls
        apiClient.request_allRecordedCalls.forEach {
            let callback = $0.completion as! (Result<EmptyResponse, Error>) -> Void
            callback(.success(.init()))
        }
                
        // Wait for 2 more API calls to be made
        AssertAsync.willBeEqual(apiClient.request_allRecordedCalls.count, 2 + 2)
        
        // Check the API calls are for the second messages from both channels
        let channelA_message2Payload: MessageRequestBody<ExtraData> = try XCTUnwrap(
            database.viewContext
                .message(id: channelA_message2)?.asRequestBody()
        )
        let channelB_message2Payload: MessageRequestBody<ExtraData> = try XCTUnwrap(
            database.viewContext
                .message(id: channelB_message2)?.asRequestBody()
        )
        
        XCTAssertTrue(apiClient.request_allRecordedCalls.contains(where: {
            $0.endpoint == AnyEndpoint(.sendMessage(cid: cidA, messagePayload: channelA_message2Payload))
        }))
        XCTAssertTrue(apiClient.request_allRecordedCalls.contains(where: {
            $0.endpoint == AnyEndpoint(.sendMessage(cid: cidB, messagePayload: channelB_message2Payload))
        }))
    }
    
    // MARK: - Life cycle tests
    
    func test_sender_doesNotRetainItself() throws {
        let messageId: MessageId = .unique
        
        // Create a message with pending state
        try database.createMessage(id: messageId, cid: cid, text: "Message pending send", localState: .pendingSend)
        
        // Wait for the API call to be initiated
        AssertAsync.willBeTrue(apiClient.request_endpoint != nil)
        
        // Assert sender can be released even though network response hasn't come yet
        AssertAsync.canBeReleased(&sender)
    }
}
