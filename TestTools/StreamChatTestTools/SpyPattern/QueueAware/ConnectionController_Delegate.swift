//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

// A concrete `ConnectionControllerDelegate` implementation allowing capturing the delegate calls
final class ConnectionController_Delegate: QueueAwareDelegate, ChatConnectionControllerDelegate {
    @Atomic var state: DataController.State?
    @Atomic var didUpdateConnectionStatus_statuses = [ConnectionStatus]()

    func controller(_ controller: DataController, didChangeState state: DataController.State) {
        self.state = state
        validateQueue()
    }

    func connectionController(_ controller: ChatConnectionController, didUpdateConnectionStatus status: ConnectionStatus) {
        _didUpdateConnectionStatus_statuses.mutate { $0.append(status) }
        validateQueue()
    }
}
