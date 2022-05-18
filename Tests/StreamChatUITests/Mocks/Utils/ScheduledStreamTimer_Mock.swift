//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChat

final class ScheduledStreamTimer_Mock: StreamTimer {
    var numberOftimesStopped: Int = 0
    var numberOfTimesStarted: Int = 0
    var numberOfTimerScheduled: Int = 0
    
    var isRunning: Bool = false
    var onChange: (() -> Void)?
    
    public func start() {
        numberOfTimesStarted += 1
        onChange?()
    }
    
    public func stop() {
        numberOftimesStopped += 1
    }
}
