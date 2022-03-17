//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class EventSender_Tests: XCTestCase {
    var apiClient: APIClientMock!
    var database: DatabaseContainer!
    var sender: EventSender!
    
    override func setUp() {
        super.setUp()
        
        apiClient = APIClientMock()
        database = DatabaseContainerMock()
        sender = EventSender(database: database, apiClient: apiClient)
    }
    
    override func tearDown() {
        apiClient.cleanUp()
        apiClient = nil
        database = nil
        sender = nil

        super.tearDown()
    }
    
    // MARK: - Send event
    
    func test_sendEvent_makesCorrectAPICall() {
        let payload: IdeaEventPayload = .unique
        let cid: ChannelId = .unique
        
        // Simulate `sendEvent` call
        sender.sendEvent(payload, to: cid)
        
        // Assert correct endpoint is called
        let referenceEndpoint: Endpoint<EmptyResponse> = .sendEvent(payload, cid: cid)
        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(referenceEndpoint))
    }
    
    func test_sendEvent_propagatesSuccessfulResponse() {
        // Simulate `sendEvent` call
        var completionCalled = false
        sender.sendEvent(IdeaEventPayload.unique, to: .unique) { error in
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

    func test_sendEvent_propagatesError() {
        // Simulate `sendEvent` call
        var completionCalledError: Error?
        sender.sendEvent(IdeaEventPayload.unique, to: .unique) { error in
            completionCalledError = error
        }

        // Simulate API response with failure
        let error = TestError()
        apiClient.test_simulateResponse(Result<EmptyResponse, Error>.failure(error))

        // Assert the completion is called with the error
        AssertAsync.willBeEqual(completionCalledError as? TestError, error)
    }
}
