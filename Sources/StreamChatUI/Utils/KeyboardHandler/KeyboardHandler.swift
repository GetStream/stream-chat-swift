//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

/// A component responsible to handle keyboard events and act on them.
@MainActor public protocol KeyboardHandler {
    /// Start handling events.
    func start()
    /// Stop handling events.
    func stop()
}
