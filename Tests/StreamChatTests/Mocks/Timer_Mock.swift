//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChat

final class ScheduledStreamTimer_Mock: StreamTimer {
    var stopCallCount: Int = 0
    var startCallCount: Int = 0
    
    var isRunning: Bool = false
    var onChange: (() -> Void)?
    
    func start() {
        startCallCount += 1
    }
    
    func stop() {
        stopCallCount += 1
    }
}
