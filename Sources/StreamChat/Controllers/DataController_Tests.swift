//
// Copyright © 2021 Stream.io Inc. All rights reserved.
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
}

private class TestDelegate: QueueAwareDelegate, DataControllerStateDelegate {
    var state: DataController.State = .initialized
    
    func controller(_ controller: DataController, didChangeState state: DataController.State) {
        self.state = state
        validateQueue()
    }
}
