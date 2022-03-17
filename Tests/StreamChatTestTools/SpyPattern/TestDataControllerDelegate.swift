//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

// A concrete `DataControllerDelegate` implementation allowing capturing the delegate calls
final class TestDataControllerDelegate: QueueAwareDelegate, DataControllerStateDelegate {
    var state: DataController.State = .initialized

    func controller(_ controller: DataController, didChangeState state: DataController.State) {
        self.state = state
        validateQueue()
    }
}
