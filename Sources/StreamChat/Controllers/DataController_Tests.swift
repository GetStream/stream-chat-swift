//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import XCTest

class DataController_Tests: XCTestCase {
    func test_delegateMethodIsCalled() {
        let controller = DataController()
        let delegateQueueId = UUID()
        let delegate = TestDelegate(expectedQueueId: delegateQueueId)
        
        controller.stateMulticastDelegate.add(additionalDelegate: delegate)
        controller.callbackQueue = DispatchQueue.testQueue(withId: delegateQueueId)
        
        // Check if state is `initialized` initially.
        XCTAssertEqual(delegate.state, .initialized)
        
        // Simulate state change.
        controller.state = .localDataFetched
        
        // Check if state of delegate method is called after state change.
        AssertAsync.willBeEqual(delegate.state, .localDataFetched)
    }

    func test_isAvailableOnRemoteTrueWhenStateIs_remoteDataFetched() {
        let controller = DataController()
        controller.state = .remoteDataFetched
        XCTAssertTrue(controller.isAvailableOnRemote)
    }

    func test_isAvailableOnRemoteTrueWhenStateIs_remoteDataFetchFailed() {
        let controller = DataController()
        controller.state = .remoteDataFetchFailed(ClientError(""))
        XCTAssertTrue(controller.isAvailableOnRemote)
    }

    func test_isAvailableOnRemoteTrueWhenStateIs_initialized() {
        let controller = DataController()
        controller.state = .initialized
        XCTAssertFalse(controller.isAvailableOnRemote)
    }

    func test_isAvailableOnRemoteTrueWhenStateIs_localDataFetched() {
        let controller = DataController()
        controller.state = .localDataFetched
        XCTAssertFalse(controller.isAvailableOnRemote)
    }

    func test_isAvailableOnRemoteTrueWhenStateIs_localDataFetchFailed() {
        let controller = DataController()
        controller.state = .localDataFetchFailed(ClientError(""))
        XCTAssertFalse(controller.isAvailableOnRemote)
    }
}

private class TestDelegate: QueueAwareDelegate, DataControllerStateDelegate {
    var state: DataController.State = .initialized
    
    func controller(_ controller: DataController, didChangeState state: DataController.State) {
        self.state = state
        validateQueue()
    }
}
