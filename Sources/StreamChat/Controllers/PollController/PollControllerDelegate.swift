//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public protocol PollControllerDelegate: DataControllerStateDelegate {
    func pollController(
        _ pollController: PollController,
        didUpdatePoll poll: EntityChange<Poll>
    )
}
