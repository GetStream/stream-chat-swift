//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

class ChannelUpdater_Tests: StressTestCase {
    var webSocketClient: WebSocketClientMock!
    var apiClient: APIClientMock!
    var database: DatabaseContainerMock!
    
    var channelUpdater: ChannelUpdater!
    
    override func setUp() {
        super.setUp()
        
        webSocketClient = WebSocketClientMock()
        apiClient = APIClientMock()
        database = DatabaseContainerMock()
        
        channelUpdater = ChannelUpdater(database: database, apiClient: apiClient)
    }
    
    override func tearDown() {
        apiClient.cleanUp()
        AssertAsync.canBeReleased(&database)
        
        super.tearDown()
    }
    
    // MARK: - UpdateChannelQuery
    
    func test_updateChannelQuery_makesCorrectAPICall() {
        // Simulate `update(channelQuery:)` call
        let query = ChannelQuery(cid: .unique)
        channelUpdater.update(channelQuery: query)
        
        let referenceEndpoint: Endpoint<ChannelPayload> = .channel(query: query)
        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(referenceEndpoint))
    }
    
    func test_updateChannelQuery_successfulResponseData_areSavedToDB() {
        // Simulate `update(channelQuery:)` call
        let query = ChannelQuery(cid: .unique)
        var completionCalled = false
        channelUpdater.update(channelQuery: query, completion: { result in
            XCTAssertNil(result.error)
            completionCalled = true
        })
        
        // Simulate API response with channel data
        let cid = ChannelId(type: .messaging, id: .unique)
        let payload = dummyPayload(with: cid)
        apiClient.test_simulateResponse(.success(payload))
        
        // Assert the data is stored in the DB
        var channel: ChatChannel? {
            database.viewContext.channel(cid: cid)?.asModel()
        }
        AssertAsync {
            Assert.willBeTrue(channel != nil)
            Assert.willBeTrue(completionCalled)
        }
    }
    
    func test_updateChannelQuery_errorResponse_isPropagatedToCompletion() {
        // Simulate `update(channelQuery:)` call
        let query = ChannelQuery(cid: .unique)
        var completionCalledError: Error?
        channelUpdater.update(channelQuery: query, completion: { completionCalledError = $0.error })
        
        // Simulate API response with failure
        let error = TestError()
        apiClient.test_simulateResponse(Result<ChannelPayload, Error>.failure(error))
        
        // Assert the completion is called with the error
        AssertAsync.willBeEqual(completionCalledError as? TestError, error)
    }

    func test_updateChannelQuery_completionForCreatedChannelCalled() {
        // Simulate `update(channelQuery:)` call
        let query = ChannelQuery(channelPayload: .unique)
        var cid: ChannelId = .unique

        var channel: ChatChannel? {
            database.viewContext.channel(cid: cid)?.asModel()
        }

        let callback: (ChannelId) -> Void = {
            cid = $0
            // Assert channel is not saved to DB before callback returns
            AssertAsync.staysTrue(channel == nil)
        }

        // Simulate `updateChannel` call
        channelUpdater.update(channelQuery: query, channelCreatedCallback: callback, completion: nil)

        // Simulate API response with channel data
        let payload = dummyPayload(with: query.cid!)
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
        
        _ = try waitFor { completion in
            database.write({ (session) in
                let currentUserPayload: CurrentUserPayload = .dummy(
                    userId: currentUserId,
                    role: .admin,
                    extraData: [:]
                )

                try session.saveCurrentUser(payload: currentUserPayload)
                
                try session.saveChannel(payload: self.dummyPayload(with: cid))
                
            }, completion: completion)
        }
        
        // New message values
        let text: String = .unique
        let command: String = .unique
        let arguments: String = .unique
        let extraData: [String: RawJSON] = [:]

        let imageAttachmentEnvelope = AnyAttachmentPayload.mockImage
        let fileAttachmentEnvelope = AnyAttachmentPayload.mockFile
        let customAttachmentEnvelope = AnyAttachmentPayload(payload: TestAttachmentPayload.unique)

        let attachmentEnvelopes: [AnyAttachmentPayload] = [
            imageAttachmentEnvelope,
            fileAttachmentEnvelope,
            customAttachmentEnvelope
        ]

        // Create new message
        let newMessageId: MessageId = try waitFor { completion in
            channelUpdater.createNewMessage(
                in: cid,
                text: text,
                pinning: MessagePinning(expirationDate: .unique),
                isSilent: false,
                command: command,
                arguments: arguments,
                attachments: attachmentEnvelopes,
                mentionedUserIds: [currentUserId],
                quotedMessageId: nil,
                extraData: extraData
            ) { result in
                do {
                    let newMessageId = try result.get()
                    completion(newMessageId)
                } catch {
                    XCTFail("Saving the message failed. \(error)")
                }
            }
        }

        func id(for envelope: AnyAttachmentPayload) -> AttachmentId {
            .init(cid: cid, messageId: newMessageId, index: attachmentEnvelopes.firstIndex(of: envelope)!)
        }
        
        let message: ChatMessage = try XCTUnwrap(
            database.viewContext.message(id: newMessageId)?.asModel()
        )

        XCTAssertEqual(message.text, text)
        XCTAssertEqual(message.command, command)
        XCTAssertEqual(message.arguments, arguments)
        XCTAssertEqual(message.attachmentCounts.count, 3)
        XCTAssertEqual(message.imageAttachments, [imageAttachmentEnvelope.attachment(id: id(for: imageAttachmentEnvelope))])
        XCTAssertEqual(message.fileAttachments, [fileAttachmentEnvelope.attachment(id: id(for: fileAttachmentEnvelope))])
        XCTAssertEqual(
            message.attachments(payloadType: TestAttachmentPayload.self),
            [customAttachmentEnvelope.attachment(id: id(for: customAttachmentEnvelope))]
        )
        
        XCTAssertEqual(message.extraData, [:])
        XCTAssertEqual(message.localState, .pendingSend)
        XCTAssertEqual(message.isPinned, true)
        XCTAssertEqual(message.isSilent, false)
        XCTAssertEqual(message.mentionedUsers.map(\.id), [currentUserId])
    }
    
    func test_createNewMessage_propagatesErrorWhenSavingFails() throws {
        // Prepare the current user and channel first
        let cid: ChannelId = .unique
        let currentUserId: UserId = .unique
        
        _ = try waitFor { completion in
            database.write({ (session) in
                let currentUserPayload: CurrentUserPayload = .dummy(
                    userId: currentUserId,
                    role: .admin,
                    extraData: [:]
                )

                try session.saveCurrentUser(payload: currentUserPayload)
                
                try session.saveChannel(payload: self.dummyPayload(with: cid))
                
            }, completion: completion)
        }

        // Simulate the DB failing with `TestError`
        let testError = TestError()
        database.write_errorResponse = testError
        
        let result: Result<MessageId, Error> = try waitFor { completion in
            channelUpdater.createNewMessage(
                in: .unique,
                text: .unique,
                isSilent: false,
                command: .unique,
                arguments: .unique,
                mentionedUserIds: [.unique],
                quotedMessageId: nil,
                extraData: [:]
            ) { completion($0) }
        }
        
        AssertResultFailure(result, testError)
    }
    
    // MARK: - Update channel

    func test_updateChannel_makesCorrectAPICall() {
        let channelPayload: ChannelEditDetailPayload = .unique

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

    // MARK: - Truncate channel

    func test_truncateChannel_makesCorrectAPICall() {
        let channelID = ChannelId.unique

        // Simulate `truncateChannel(cid:, completion:)` call
        channelUpdater.truncateChannel(cid: channelID)

        // Assert correct endpoint is called
        let referenceEndpoint: Endpoint<EmptyResponse> = .truncateChannel(cid: channelID)
        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(referenceEndpoint))
    }

    func test_truncateChannel_successfulResponse_isPropagatedToCompletion() {
        // Simulate `truncateChannel(cid:, completion:)` call
        var completionCalled = false
        channelUpdater.truncateChannel(cid: .unique) { error in
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

    func test_truncateChannel_errorResponse_isPropagatedToCompletion() {
        // Simulate `truncateChannel(cid:, completion:)` call
        var completionCalledError: Error?
        channelUpdater.truncateChannel(cid: .unique) { completionCalledError = $0 }

        // Simulate API response with failure
        let error = TestError()
        apiClient.test_simulateResponse(Result<EmptyResponse, Error>.failure(error))

        // Assert the completion is called with the error
        AssertAsync.willBeEqual(completionCalledError as? TestError, error)
    }

    // MARK: - Hide channel

    func test_hideChannel_makesCorrectAPICall() {
        let channelID = ChannelId.unique
        let clearHistory = true

        // Simulate `hideChannel(cid:, clearHistory:, completion:)` call
        channelUpdater.hideChannel(cid: channelID, clearHistory: clearHistory)

        // Assert correct endpoint is called
        let referenceEndpoint: Endpoint<EmptyResponse> = .hideChannel(cid: channelID, clearHistory: clearHistory)
        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(referenceEndpoint))
    }

    func test_hideChannel_successfulResponse_isPropagatedToCompletion() throws {
        // This part is for the case where the channel is already hidden on backend
        // But SDK is not aware of this (so channel.hiddenAt is not set)
        // Consecutive `hideChannel` calls won't generate `channel.hidden` events
        // and SDK has no way to learn channel was hidden
        // So, ChannelUpdater marks the Channel as hidden on successful API response
        // Create a channel in DB
        let cid = ChannelId.unique
        
        try database.writeSynchronously {
            try $0.saveChannel(payload: self.dummyPayload(with: cid))
        }
        
        var channel: ChannelDTO? { database.viewContext.channel(cid: cid) }
        
        // Assert that channel is not hidden
        XCTAssertNil(channel?.hiddenAt)
        
        // Simulate `hideChannel(cid:, clearHistory:, completion:)` call
        let exp = expectation(description: "should hide channel")
        channelUpdater.hideChannel(cid: cid, clearHistory: true) { error in
            XCTAssertNil(error)
            exp.fulfill()
        }

        // Simulate API response with success
        apiClient.test_simulateResponse(Result<EmptyResponse, Error>.success(.init()))

        wait(for: [exp], timeout: 1)
        
        // Ensure channel is marked as hidden
        XCTAssertNotNil(channel?.hiddenAt)
    }

    func test_hideChannel_errorResponse_isPropagatedToCompletion() throws {
        // Create a channel in DB
        let cid = ChannelId.unique
        
        try database.writeSynchronously {
            try $0.saveChannel(payload: self.dummyPayload(with: cid))
        }
        
        var channel: ChannelDTO? {
            database.viewContext.channel(cid: cid)
        }
        
        // Assert that channel is not hidden
        XCTAssertNil(channel?.hiddenAt)
        
        // Simulate `hideChannel(cid:, clearHistory:, completion:)` call
        var completionCalledError: Error?
        channelUpdater.hideChannel(cid: .unique, clearHistory: true) { completionCalledError = $0 }

        // Simulate API response with failure
        let error = TestError()
        apiClient.test_simulateResponse(Result<EmptyResponse, Error>.failure(error))

        // Assert the completion is called with the error
        AssertAsync.willBeEqual(completionCalledError as? TestError, error)
        
        // Assert that channel is not hidden
        XCTAssertNil(channel?.hiddenAt)
    }

    // MARK: - Show channel

    func test_showChannel_makesCorrectAPICall() {
        let channelID = ChannelId.unique

        // Simulate `showChannel(cid:)` call
        channelUpdater.showChannel(cid: channelID)

        // Assert correct endpoint is called
        let referenceEndpoint: Endpoint<EmptyResponse> = .showChannel(cid: channelID)
        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(referenceEndpoint))
    }

    func test_showChannel_successfulResponse_isPropagatedToCompletion() {
        // Simulate `showChannel(cid:)` call
        var completionCalled = false
        channelUpdater.showChannel(cid: .unique) { error in
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
        // Simulate `showChannel(cid:)` call
        var completionCalledError: Error?
        channelUpdater.showChannel(cid: .unique) { completionCalledError = $0 }

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
    
    // MARK: - Invite members

    func test_inviteMembers_makesCorrectAPICall() {
        let channelID = ChannelId.unique
        let userIds: Set<UserId> = Set([UserId.unique])

        // Simulate `inviteMembers(cid:, mute:, userIds:)` call
        channelUpdater.inviteMembers(cid: channelID, userIds: userIds)

        // Assert correct endpoint is called
        let referenceEndpoint: Endpoint<EmptyResponse> = .inviteMembers(cid: channelID, userIds: userIds)
        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(referenceEndpoint))
    }

    func test_inviteMembers_successfulResponse_isPropagatedToCompletion() {
        let channelID = ChannelId.unique
        let userIds: Set<UserId> = Set([UserId.unique])
        
        // Simulate `inviteMembers(cid:, mute:, userIds:)` call
        var completionCalled = false
        channelUpdater.inviteMembers(cid: channelID, userIds: userIds) { error in
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

    func test_inviteMembers_errorResponse_isPropagatedToCompletion() {
        let channelID = ChannelId.unique
        let userIds: Set<UserId> = Set([UserId.unique])
        
        // Simulate `muteChannel(cid:, mute:, completion:)` call
        var completionCalledError: Error?
        channelUpdater.inviteMembers(cid: channelID, userIds: userIds) { completionCalledError = $0 }

        // Simulate API response with failure
        let error = TestError()
        apiClient.test_simulateResponse(Result<EmptyResponse, Error>.failure(error))

        // Assert the completion is called with the error
        AssertAsync.willBeEqual(completionCalledError as? TestError, error)
    }
    
    // MARK: - Accept invite

    func test_acceptInvite_makesCorrectAPICall() {
        let channelID = ChannelId.unique
        let message = "Hooray"

        channelUpdater.acceptInvite(cid: channelID, message: message)

        // Assert correct endpoint is called
        let referenceEndpoint: Endpoint<EmptyResponse> = .acceptInvite(cid: channelID, message: message)
        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(referenceEndpoint))
    }

    func test_acceptInvite_successfulResponse_isPropagatedToCompletion() {
        let channelID = ChannelId.unique
        let message = "Hooray"

        // Simulate `acceptInvite(cid:, mute:, userIds:)` call
        var completionCalled = false
        channelUpdater.acceptInvite(cid: channelID, message: message) { error in
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

    func test_acceptInvite_errorResponse_isPropagatedToCompletion() {
        let channelID = ChannelId.unique
        
        var completionCalledError: Error?
        channelUpdater.acceptInvite(cid: channelID, message: "Hooray") { completionCalledError = $0 }

        // Simulate API response with failure
        let error = TestError()
        apiClient.test_simulateResponse(Result<EmptyResponse, Error>.failure(error))

        // Assert the completion is called with the error
        AssertAsync.willBeEqual(completionCalledError as? TestError, error)
    }
    
    // MARK: - Reject invite

    func test_rejectInvite_makesCorrectAPICall() {
        let channelID = ChannelId.unique

        channelUpdater.rejectInvite(cid: channelID)

        // Assert correct endpoint is called
        let referenceEndpoint: Endpoint<EmptyResponse> = .rejectInvite(cid: channelID)
        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(referenceEndpoint))
    }

    func test_rejectInvite_successfulResponse_isPropagatedToCompletion() {
        let channelID = ChannelId.unique

        // Simulate `rejectInvite(cid:, mute:, userIds:)` call
        var completionCalled = false
        channelUpdater.rejectInvite(cid: channelID) { error in
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

    func test_rejectInvite_errorResponse_isPropagatedToCompletion() {
        let channelID = ChannelId.unique
        
        var completionCalledError: Error?
        channelUpdater.rejectInvite(cid: channelID) { completionCalledError = $0 }

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
    
    // MARK: - Enable slow mode (cooldown)
    
    func test_enableSlowMode_makesCorrectAPICall() {
        let cid = ChannelId.unique
        let cooldownDuration = Int.random(in: 0...120)
        
        channelUpdater.enableSlowMode(cid: cid, cooldownDuration: cooldownDuration)
        
        let referenceEndpoint = Endpoint<EmptyResponse>.enableSlowMode(cid: cid, cooldownDuration: cooldownDuration)
        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(referenceEndpoint))
    }
    
    func test_enableSlowMode_successfulResponse_isPropagatedToCompletion() {
        var completionCalled = false
        channelUpdater.enableSlowMode(cid: .unique, cooldownDuration: .random(in: 0...120)) { error in
            XCTAssertNil(error)
            completionCalled = true
        }
        
        XCTAssertFalse(completionCalled)
        
        apiClient.test_simulateResponse(Result<EmptyResponse, Error>.success(.init()))
        
        AssertAsync.willBeTrue(completionCalled)
    }
    
    func test_enableSlowMode_errorResponse_isPropagatedToCompletion() {
        var completionCalledError: Error?
        channelUpdater.enableSlowMode(cid: .unique, cooldownDuration: .random(in: 0...120)) { completionCalledError = $0 }
        
        let error = TestError()
        apiClient.test_simulateResponse(Result<EmptyResponse, Error>.failure(error))
        
        AssertAsync.willBeEqual(completionCalledError as? TestError, error)
    }
    
    // MARK: - Start watching
    
    func test_startWatching_makesCorrectAPICall() {
        let cid = ChannelId.unique
        
        channelUpdater.startWatching(cid: cid)
        
        var query = ChannelQuery(cid: cid)
        query.options = .all
        let referenceEndpoint: Endpoint<ChannelPayload> = .channel(query: query)
        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(referenceEndpoint))
    }
    
    func test_startWatching_successfulResponse_isPropagatedToCompletion() {
        var completionCalled = false
        let cid = ChannelId.unique
        channelUpdater.startWatching(cid: cid) { error in
            XCTAssertNil(error)
            completionCalled = true
        }
        
        XCTAssertFalse(completionCalled)
        
        // Simulate API response with channel data
        let payload = dummyPayload(with: cid)
        apiClient.test_simulateResponse(.success(payload))
        
        AssertAsync.willBeTrue(completionCalled)
    }
    
    func test_startWatching_errorResponse_isPropagatedToCompletion() {
        var completionCalledError: Error?
        channelUpdater.startWatching(cid: .unique) { completionCalledError = $0 }
        
        let error = TestError()
        apiClient.test_simulateResponse(Result<ChannelPayload, Error>.failure(error))
        
        AssertAsync.willBeEqual(completionCalledError as? TestError, error)
    }
    
    // MARK: - Stop watching
    
    func test_stopWatching_makesCorrectAPICall() {
        let cid = ChannelId.unique
        
        channelUpdater.stopWatching(cid: cid)

        let referenceEndpoint: Endpoint<EmptyResponse> = .stopWatching(cid: cid)
        
        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(referenceEndpoint))
    }
    
    func test_stopWatching_successfulResponse_isPropagatedToCompletion() {
        var completionCalled = false
        let cid = ChannelId.unique
        channelUpdater.stopWatching(cid: cid) { error in
            XCTAssertNil(error)
            completionCalled = true
        }
        
        XCTAssertFalse(completionCalled)
        
        apiClient.test_simulateResponse(Result<EmptyResponse, Error>.success(.init()))
        
        AssertAsync.willBeTrue(completionCalled)
    }
    
    func test_stopWatching_errorResponse_isPropagatedToCompletion() {
        var completionCalledError: Error?
        channelUpdater.stopWatching(cid: .unique) { completionCalledError = $0 }
        
        let error = TestError()
        apiClient.test_simulateResponse(Result<EmptyResponse, Error>.failure(error))
        
        AssertAsync.willBeEqual(completionCalledError as? TestError, error)
    }
    
    // MARK: - Channel watchers
    
    func test_channelWatchers_makesCorrectAPICall() {
        let cid = ChannelId.unique
        let query = ChannelWatcherListQuery(cid: cid)
        
        channelUpdater.channelWatchers(query: query)
        
        let referenceEndpoint: Endpoint<ChannelPayload> = .channelWatchers(query: query)
        
        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(referenceEndpoint))
    }
    
    func test_channelWatchers_successfulResponse_isPropagatedToCompletion() {
        var completionCalled = false
        let cid = ChannelId.unique
        let query = ChannelWatcherListQuery(cid: cid)
        channelUpdater.channelWatchers(query: query) { error in
            XCTAssertNil(error)
            completionCalled = true
        }
        
        XCTAssertFalse(completionCalled)
        
        apiClient.test_simulateResponse(
            Result<ChannelPayload, Error>.success(dummyPayload(with: cid))
        )
        
        AssertAsync.willBeTrue(completionCalled)
    }
    
    func test_channelWatchers_errorResponse_isPropagatedToCompletion() {
        var completionCalledError: Error?
        let query = ChannelWatcherListQuery(cid: .unique)
        channelUpdater.channelWatchers(query: query) { completionCalledError = $0 }
        
        let error = TestError()
        apiClient.test_simulateResponse(Result<ChannelPayload, Error>.failure(error))
        
        AssertAsync.willBeEqual(completionCalledError as? TestError, error)
    }
    
    func test_channelWatchers_clearsWatchers_whenFirstPageIsRequestedAndEmpty() throws {
        // Create a dummy channel
        let cid = ChannelId.unique
        try database.createChannel(cid: cid, withMessages: false)
        
        var channel: ChatChannel? {
            database.viewContext.channel(cid: cid)?.asModel()
        }
        
        // Assert that the dummy channel has a watcher
        assert(!(channel?.lastActiveWatchers.isEmpty ?? true))
        
        // Save first watcher's id so we can compare later
        let firstWatcherId = channel?.lastActiveWatchers.first?.id
        
        // Call `channelWatchers` for this channel
        // This query doesn't provide any `offset` so it's requesting the first page of watchers
        let query = ChannelWatcherListQuery(cid: cid)
        channelUpdater.channelWatchers(query: query)
        
        // Simulate successful response
        apiClient.test_simulateResponse(
            Result<ChannelPayload, Error>.success(dummyPayload(with: cid, watchers: []))
        )
        
        // Assert that the old watcher is replaced
        AssertAsync {
            Assert.willBeFalse(channel?.lastActiveWatchers.contains(where: { $0.id == firstWatcherId }) ?? true)
        }
    }
    
    // MARK: - Freeze channel
    
    func test_freezeChannel_makesCorrectAPICall() {
        let cid = ChannelId.unique
        let freeze = Bool.random()
        
        channelUpdater.freezeChannel(freeze, cid: cid)
        
        let referenceEndpoint: Endpoint<EmptyResponse> = .freezeChannel(freeze, cid: cid)
        
        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(referenceEndpoint))
    }
    
    func test_freezeChannel_successfulResponse_isPropagatedToCompletion() {
        var completionCalled = false
        let cid = ChannelId.unique
        let freeze = Bool.random()
        channelUpdater.freezeChannel(freeze, cid: cid) { error in
            XCTAssertNil(error)
            completionCalled = true
        }
        
        XCTAssertFalse(completionCalled)
        
        apiClient.test_simulateResponse(Result<EmptyResponse, Error>.success(.init()))
        
        AssertAsync.willBeTrue(completionCalled)
    }
    
    func test_freezeChannel_errorResponse_isPropagatedToCompletion() {
        var completionCalledError: Error?
        channelUpdater.freezeChannel(.random(), cid: .unique) { completionCalledError = $0 }
        
        let error = TestError()
        apiClient.test_simulateResponse(Result<EmptyResponse, Error>.failure(error))
        
        AssertAsync.willBeEqual(completionCalledError as? TestError, error)
    }
}
