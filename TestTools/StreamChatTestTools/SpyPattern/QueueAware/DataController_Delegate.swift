//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

// A concrete `DataControllerDelegate` implementation allowing capturing the delegate calls
final class DataController_Delegate: QueueAwareDelegate, DataControllerStateDelegate {
    nonisolated(unsafe) var state: DataController.State = .initialized

    func controller(_ controller: DataController, didChangeState state: DataController.State) {
        self.state = state
        validateQueue()
    }
}
