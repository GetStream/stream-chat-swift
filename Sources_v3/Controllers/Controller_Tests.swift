//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

@testable import StreamChatClient
import XCTest

class Controller_Tests: XCTestCase {
    func test_delegateMethodIsCalled() {
        let controller = Controller()
        let delegateQueueId = UUID()
        let delegate = TestDelegate()
        
        delegate.expectedQueueId = delegateQueueId
        controller.stateMulticastDelegate.mainDelegate = delegate
        controller.callbackQueue = DispatchQueue.testQueue(withId: delegateQueueId)
        
        // Check if state is `inactive` initially.
        XCTAssertEqual(delegate.state, .inactive)
        
        // Simulate state change.
        controller.state = .localDataFetched
        
        // Check if state of delegate method is called after state change.
        AssertAsync.willBeEqual(delegate.state, .localDataFetched)
    }
}

private class TestDelegate: QueueAwareDelegate, ControllerStateDelegate {
    var state: Controller.State = .inactive
    
    func controller(_ controller: Controller, didChangeState state: Controller.State) {
        self.state = state
        validateQueue()
    }
}
