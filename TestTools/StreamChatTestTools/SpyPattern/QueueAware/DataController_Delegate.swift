//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import XCTest
import Foundation
@testable import StreamChat

// A concrete `DataControllerDelegate` implementation allowing capturing the delegate calls
final class DataController_Delegate: QueueAwareDelegate, DataControllerStateDelegate {
    var state: DataController.State = .initialized
    var didChangeStateCallCount = 0
    var didChangeStateExp = XCTestExpectation(description: "didChangeState called")

    func controller(_ controller: DataController, didChangeState state: DataController.State) {
        self.state = state
        didChangeStateCallCount += 1
        didChangeStateExp.fulfill()
        validateQueue()
    }
}
