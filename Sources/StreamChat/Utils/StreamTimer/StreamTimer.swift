//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

public protocol StreamTimer {
    func start()
    func stop()
    var onChange: (() -> Void)? { get set }
    var isRunning: Bool { get }
}
