//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

@testable import StreamChatClient
import XCTest

class ChannelUpdater_Tests: StressTestCase {
    typealias ExtraData = DefaultDataTypes
    
    var webSocketClient: WebSocketClientMock!
    var apiClient: APIClientMock!
    var database: DatabaseContainerMock!
    
    var channelUpdater: ChannelUpdater<ExtraData>!
    
    override func setUp() {
        super.setUp()
        
        webSocketClient = WebSocketClientMock()
        apiClient = APIClientMock()
        database = try! DatabaseContainerMock(kind: .inMemory)
        
        channelUpdater = ChannelUpdater(database: database, webSocketClient: webSocketClient, apiClient: apiClient)
    }
    
    override func tearDown() {
        apiClient.cleanUp()
        
        super.tearDown()
    }
    
    // MARK: - UpdateChannelQuery
    
    func test_updateChannelQuery_makesCorrectAPICall() {
        // Simulate `update(channelQuery:)` call
        let query = ChannelQuery<ExtraData>(cid: .unique)
        channelUpdater.update(channelQuery: query)
        
        let referenceEndpoint: Endpoint<ChannelPayload<ExtraData>> = .channel(query: query)
        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(referenceEndpoint))
    }
    
    func test_updateChannelQuery_successfulResponseData_areSavedToDB() {
        // Simulate `update(channelQuery:)` call
        let query = ChannelQuery<ExtraData>(cid: .unique)
        var completionCalled = false
        channelUpdater.update(channelQuery: query, completion: { error in
            XCTAssertNil(error)
            completionCalled = true
        })
        
        // Simulate API response with channel data
        let cid = ChannelId(type: .messaging, id: .unique)
        let payload = dummyPayload(with: cid)
        apiClient.test_simulateResponse(.success(payload))
        
        // Assert the data is stored in the DB
        var channel: Channel? {
            database.viewContext.loadChannel(cid: cid)
        }
        AssertAsync {
            Assert.willBeTrue(channel != nil)
            Assert.willBeTrue(completionCalled)
        }
    }
    
    func test_updateChannelQuery_errorResponse_isPropagatedToCompletion() {
        // Simulate `update(channelQuery:)` call
        let query = ChannelQuery<ExtraData>(cid: .unique)
        var completionCalledError: Error?
        channelUpdater.update(channelQuery: query, completion: { completionCalledError = $0 })
        
        // Simulate API response with failure
        let error = TestError()
        apiClient.test_simulateResponse(Result<ChannelPayload<ExtraData>, Error>.failure(error))
        
        // Assert the completion is called with the error
        AssertAsync.willBeEqual(completionCalledError as? TestError, error)
    }

    func test_updateChannelQuery_completionForCreatedChannelCalled() {
        // Simulate `update(channelQuery:)` call
        let query = ChannelQuery(channelPayload: .unique)
        var cid: ChannelId = .unique

        var channel: Channel? {
            database.viewContext.loadChannel(cid: cid)
        }

        let callback: (ChannelId) -> Void = {
            cid = $0
            // Assert channel is not saved to DB before callback returns
            AssertAsync.staysTrue(channel == nil)
        }

        // Simulate `updateChannel` call
        channelUpdater.update(channelQuery: query, channelCreatedCallback: callback, completion: nil)

        // Simulate API response with channel data
        let payload = dummyPayload(with: query.cid)
        apiClient.test_simulateResponse(.success(payload))

        // Assert `channelCreatedCallback` is called
        XCTAssertEqual(cid, query.cid)
        // Assert channel is saved to DB after
        AssertAsync.willBeTrue(channel != nil)
    }

    // MARK: - Messages
    
    func test_createNewMessage() throws {
        // Prepare the current user and channel first
        let cid: ChannelId = .unique
        let currentUserId: UserId = .unique
        
        _ = try await { completion in
            database.write({ (session) in
                try session.saveCurrentUser(payload: .dummy(
                    userId: currentUserId,
                    role: .admin,
                    extraData: NameAndImageExtraData(name: nil, imageURL: nil)
                ))
                
                try session.saveChannel(payload: self.dummyPayload(with: cid))
                
            }, completion: completion)
        }
        
        // New message values
        let text: String = .unique
        let command: String = .unique
        let arguments: String = .unique
        let parentMessageId: MessageId = .unique
        let showReplyInChannel = true
        let extraData: DefaultDataTypes.Message = .defaultValue
        
        // Create new message
        let newMesageId: MessageId = try await { completion in
            channelUpdater.createNewMessage(
                in: cid,
                text: text,
                command: command,
                arguments: arguments,
                parentMessageId: parentMessageId,
                showReplyInChannel: showReplyInChannel,
                extraData: extraData
            ) { result in
                if let newMessageId = try? result.get() {
                    completion(newMessageId)
                } else {
                    XCTFail("Saving the message failed.")
                }
            }
        }
        
        var message: Message? {
            database.viewContext.message(id: newMesageId)?.asModel()
        }
        
        AssertAsync {
            Assert.willBeEqual(message?.text, text)
            Assert.willBeEqual(message?.command, command)
            Assert.willBeEqual(message?.arguments, arguments)
            Assert.willBeEqual(message?.parentMessageId, parentMessageId)
            Assert.willBeEqual(message?.showReplyInChannel, showReplyInChannel)
            Assert.willBeEqual(message?.extraData, extraData)
            Assert.willBeEqual(message?.localState, .pendingSend)
        }
    }
    
    func test_createNewMessage_propagatesErrorWhenSavingFails() throws {
        // Prepare the current user and channel first
        let cid: ChannelId = .unique
        let currentUserId: UserId = .unique
        
        _ = try await { completion in
            database.write({ (session) in
                try session.saveCurrentUser(payload: .dummy(
                    userId: currentUserId,
                    role: .admin,
                    extraData: NameAndImageExtraData(name: nil, imageURL: nil)
                ))
                
                try session.saveChannel(payload: self.dummyPayload(with: cid))
                
            }, completion: completion)
        }

        // Simulate the DB failing with `TestError`
        let testError = TestError()
        database.write_errorResponse = testError
        
        let result: Result<MessageId, Error> = try await { completion in
            channelUpdater.createNewMessage(
                in: .unique,
                text: .unique,
                command: .unique,
                arguments: .unique,
                parentMessageId: .unique,
                showReplyInChannel: true,
                extraData: .defaultValue
            ) { completion($0) }
        }
        
        AssertResultFailure(result, testError)
    }
    
    // MARK: - Update channel

    func test_updateChannel_makesCorrectAPICall() {
        let channelPayload: ChannelEditDetailPayload<DefaultDataTypes> = .unique

        // Simulate `updateChannel(channelPayload:, completion:)` call
        channelUpdater.updateChannel(channelPayload: channelPayload)

        // Assert correct endpoint is called
        let referenceEndpoint: Endpoint<EmptyResponse> = .updateChannel(channelPayload: channelPayload)
        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(referenceEndpoint))
    }

    func test_updateChannel_successfulResponse_isPropagatedToCompletion() {
        // Simulate `updateChannel(channelPayload:, completion:)` call
        var completionCalled = false
        channelUpdater.updateChannel(channelPayload: .unique) { error in
            XCTAssertNil(error)
            completionCalled = true
        }

        // Assert completion is not called yet
        XCTAssertFalse(completionCalled)

        // Simulate API response with success
        apiClient.test_simulateResponse(Result<EmptyResponse, Error>.success(.init()))

        // Assert completion is called
        AssertAsync.willBeTrue(completionCalled)
    }

    func test_updateChannel_errorResponse_isPropagatedToCompletion() {
        // Simulate `updateChannel(channelPayload:, completion:)` call
        var completionCalledError: Error?
        channelUpdater.updateChannel(channelPayload: .unique) { completionCalledError = $0 }

        // Simulate API response with failure
        let error = TestError()
        apiClient.test_simulateResponse(Result<EmptyResponse, Error>.failure(error))

        // Assert the completion is called with the error
        AssertAsync.willBeEqual(completionCalledError as? TestError, error)
    }
    
    // MARK: - Mute channel

    func test_muteChannel_makesCorrectAPICall() {
        let channelID = ChannelId.unique
        let mute = true

        // Simulate `muteChannel(cid:, mute:, completion:)` call
        channelUpdater.muteChannel(cid: channelID, mute: mute)

        // Assert correct endpoint is called
        let referenceEndpoint: Endpoint<EmptyResponse> = .muteChannel(cid: channelID, mute: mute)
        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(referenceEndpoint))
    }

    func test_muteChannel_successfulResponse_isPropagatedToCompletion() {
        // Simulate `muteChannel(cid:, mute:, completion:)` call
        var completionCalled = false
        channelUpdater.muteChannel(cid: .unique, mute: true) { error in
            XCTAssertNil(error)
            completionCalled = true
        }

        // Assert completion is not called yet
        XCTAssertFalse(completionCalled)

        // Simulate API response with success
        apiClient.test_simulateResponse(Result<EmptyResponse, Error>.success(.init()))

        // Assert completion is called
        AssertAsync.willBeTrue(completionCalled)
    }

    func test_muteChannel_errorResponse_isPropagatedToCompletion() {
        // Simulate `muteChannel(cid:, mute:, completion:)` call
        var completionCalledError: Error?
        channelUpdater.muteChannel(cid: .unique, mute: true) { completionCalledError = $0 }

        // Simulate API response with failure
        let error = TestError()
        apiClient.test_simulateResponse(Result<EmptyResponse, Error>.failure(error))

        // Assert the completion is called with the error
        AssertAsync.willBeEqual(completionCalledError as? TestError, error)
    }

    // MARK: - Delete channel

    func test_deleteChannel_makesCorrectAPICall() {
        let channelID = ChannelId.unique

        // Simulate `deleteChannel(cid:, completion:)` call
        channelUpdater.deleteChannel(cid: channelID)

        // Assert correct endpoint is called
        let referenceEndpoint: Endpoint<EmptyResponse> = .deleteChannel(cid: channelID)
        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(referenceEndpoint))
    }

    func test_deleteChannel_successfulResponse_isPropagatedToCompletion() {
        // Simulate `deleteChannel(cid:, completion:)` call
        var completionCalled = false
        channelUpdater.deleteChannel(cid: .unique) { error in
            XCTAssertNil(error)
            completionCalled = true
        }

        // Assert completion is not called yet
        XCTAssertFalse(completionCalled)

        // Simulate API response with success
        apiClient.test_simulateResponse(Result<EmptyResponse, Error>.success(.init()))

        // Assert completion is called
        AssertAsync.willBeTrue(completionCalled)
    }

    func test_deleteChannel_errorResponse_isPropagatedToCompletion() {
        // Simulate `deleteChannel(cid:, completion:)` call
        var completionCalledError: Error?
        channelUpdater.deleteChannel(cid: .unique) { completionCalledError = $0 }

        // Simulate API response with failure
        let error = TestError()
        apiClient.test_simulateResponse(Result<EmptyResponse, Error>.failure(error))

        // Assert the completion is called with the error
        AssertAsync.willBeEqual(completionCalledError as? TestError, error)
    }

    // MARK: - Hide channel

    func test_hideChannel_makesCorrectAPICall() {
        let channelID = ChannelId.unique
        let userID = UserId.unique
        let clearHistory = true

        // Simulate `hideChannel(cid:, userId:, clearHistory:, completion:)` call
        channelUpdater.hideChannel(cid: channelID, userId: userID, clearHistory: clearHistory)

        // Assert correct endpoint is called
        let referenceEndpoint: Endpoint<EmptyResponse> = .hideChannel(cid: channelID, userId: userID, clearHistory: clearHistory)
        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(referenceEndpoint))
    }

    func test_hideChannel_successfulResponse_isPropagatedToCompletion() {
        // Simulate `hideChannel(cid:, userId:, clearHistory:, completion:)` call
        var completionCalled = false
        channelUpdater.hideChannel(cid: .unique, userId: .unique, clearHistory: true) { error in
            XCTAssertNil(error)
            completionCalled = true
        }

        // Assert completion is not called yet
        XCTAssertFalse(completionCalled)

        // Simulate API response with success
        apiClient.test_simulateResponse(Result<EmptyResponse, Error>.success(.init()))

        // Assert completion is called
        AssertAsync.willBeTrue(completionCalled)
    }

    func test_hideChannel_errorResponse_isPropagatedToCompletion() {
        // Simulate `hideChannel(cid:, userId:, clearHistory:, completion:)` call
        var completionCalledError: Error?
        channelUpdater.hideChannel(cid: .unique, userId: .unique, clearHistory: true) { completionCalledError = $0 }

        // Simulate API response with failure
        let error = TestError()
        apiClient.test_simulateResponse(Result<EmptyResponse, Error>.failure(error))

        // Assert the completion is called with the error
        AssertAsync.willBeEqual(completionCalledError as? TestError, error)
    }

    // MARK: - Show channel

    func test_showChannel_makesCorrectAPICall() {
        let channelID = ChannelId.unique
        let userID = UserId.unique

        // Simulate `showChannel(cid:, userId:)` call
        channelUpdater.showChannel(cid: channelID, userId: userID)

        // Assert correct endpoint is called
        let referenceEndpoint: Endpoint<EmptyResponse> = .showChannel(cid: channelID, userId: userID)
        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(referenceEndpoint))
    }

    func test_showChannel_successfulResponse_isPropagatedToCompletion() {
        // Simulate `showChannel(cid:, userId:)` call
        var completionCalled = false
        channelUpdater.showChannel(cid: .unique, userId: .unique) { error in
            XCTAssertNil(error)
            completionCalled = true
        }

        // Assert completion is not called yet
        XCTAssertFalse(completionCalled)

        // Simulate API response with success
        apiClient.test_simulateResponse(Result<EmptyResponse, Error>.success(.init()))

        // Assert completion is called
        AssertAsync.willBeTrue(completionCalled)
    }

    func test_showChannel_errorResponse_isPropagatedToCompletion() {
        // Simulate `showChannel(cid:, userId:)` call
        var completionCalledError: Error?
        channelUpdater.showChannel(cid: .unique, userId: .unique) { completionCalledError = $0 }

        // Simulate API response with failure
        let error = TestError()
        apiClient.test_simulateResponse(Result<EmptyResponse, Error>.failure(error))

        // Assert the completion is called with the error
        AssertAsync.willBeEqual(completionCalledError as? TestError, error)
    }
    
    // MARK: - Add members

    func test_addMembers_makesCorrectAPICall() {
        let channelID = ChannelId.unique
        let userIds: Set<UserId> = Set([UserId.unique])

        // Simulate `addMembers(cid:, mute:, userIds:)` call
        channelUpdater.addMembers(cid: channelID, userIds: userIds)

        // Assert correct endpoint is called
        let referenceEndpoint: Endpoint<EmptyResponse> = .addMembers(cid: channelID, userIds: userIds)
        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(referenceEndpoint))
    }

    func test_addMembers_successfulResponse_isPropagatedToCompletion() {
        let channelID = ChannelId.unique
        let userIds: Set<UserId> = Set([UserId.unique])
        
        // Simulate `addMembers(cid:, mute:, userIds:)` call
        var completionCalled = false
        channelUpdater.addMembers(cid: channelID, userIds: userIds) { error in
            XCTAssertNil(error)
            completionCalled = true
        }

        // Assert completion is not called yet
        XCTAssertFalse(completionCalled)

        // Simulate API response with success
        apiClient.test_simulateResponse(Result<EmptyResponse, Error>.success(.init()))

        // Assert completion is called
        AssertAsync.willBeTrue(completionCalled)
    }

    func test_addMembers_errorResponse_isPropagatedToCompletion() {
        let channelID = ChannelId.unique
        let userIds: Set<UserId> = Set([UserId.unique])
        
        // Simulate `muteChannel(cid:, mute:, completion:)` call
        var completionCalledError: Error?
        channelUpdater.addMembers(cid: channelID, userIds: userIds) { completionCalledError = $0 }

        // Simulate API response with failure
        let error = TestError()
        apiClient.test_simulateResponse(Result<EmptyResponse, Error>.failure(error))

        // Assert the completion is called with the error
        AssertAsync.willBeEqual(completionCalledError as? TestError, error)
    }
    
    // MARK: - Remove members

    func test_removeMembers_makesCorrectAPICall() {
        let channelID = ChannelId.unique
        let userIds: Set<UserId> = Set([UserId.unique])

        // Simulate `removeMembers(cid:, mute:, userIds:)` call
        channelUpdater.removeMembers(cid: channelID, userIds: userIds)

        // Assert correct endpoint is called
        let referenceEndpoint: Endpoint<EmptyResponse> = .removeMembers(cid: channelID, userIds: userIds)
        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(referenceEndpoint))
    }

    func test_removeMembers_successfulResponse_isPropagatedToCompletion() {
        let channelID = ChannelId.unique
        let userIds: Set<UserId> = Set([UserId.unique])
        
        // Simulate `removeMembers(cid:, mute:, userIds:)` call
        var completionCalled = false
        channelUpdater.removeMembers(cid: channelID, userIds: userIds) { error in
            XCTAssertNil(error)
            completionCalled = true
        }

        // Assert completion is not called yet
        XCTAssertFalse(completionCalled)

        // Simulate API response with success
        apiClient.test_simulateResponse(Result<EmptyResponse, Error>.success(.init()))

        // Assert completion is called
        AssertAsync.willBeTrue(completionCalled)
    }

    func test_removeMembers_errorResponse_isPropagatedToCompletion() {
        let channelID = ChannelId.unique
        let userIds: Set<UserId> = Set([UserId.unique])
        
        // Simulate `removeMembers(cid:, mute:, completion:)` call
        var completionCalledError: Error?
        channelUpdater.removeMembers(cid: channelID, userIds: userIds) { completionCalledError = $0 }

        // Simulate API response with failure
        let error = TestError()
        apiClient.test_simulateResponse(Result<EmptyResponse, Error>.failure(error))

        // Assert the completion is called with the error
        AssertAsync.willBeEqual(completionCalledError as? TestError, error)
    }
    
    // MARK: - Mark channel as read
    
    func test_markRead_makesCorrectAPICall() {
        let cid = ChannelId.unique
        
        channelUpdater.markRead(cid: cid)
        
        let referenceEndpoint = Endpoint<EmptyResponse>.markRead(cid: cid)
        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(referenceEndpoint))
    }
    
    func test_markRead_successfulResponse_isPropagatedToCompletion() {
        var completionCalled = false
        channelUpdater.markRead(cid: .unique) { error in
            XCTAssertNil(error)
            completionCalled = true
        }
        
        XCTAssertFalse(completionCalled)
        
        apiClient.test_simulateResponse(Result<EmptyResponse, Error>.success(.init()))
        
        AssertAsync.willBeTrue(completionCalled)
    }
    
    func test_markRead_errorResponse_isPropagatedToCompletion() {
        var completionCalledError: Error?
        channelUpdater.markRead(cid: .unique) { completionCalledError = $0 }
        
        let error = TestError()
        apiClient.test_simulateResponse(Result<EmptyResponse, Error>.failure(error))
        
        AssertAsync.willBeEqual(completionCalledError as? TestError, error)
    }
}
