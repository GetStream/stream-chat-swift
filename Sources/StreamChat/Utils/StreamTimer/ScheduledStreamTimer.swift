//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation

public class ScheduledStreamTimer: StreamTimer {
    let period: TimeInterval
    var runLoop = RunLoop.current
    var timer: Foundation.Timer?
    public var onChange: (() -> Void)?
    
    public var isRunning: Bool {
        timer?.isValid ?? false
    }
    
    public init(period: TimeInterval) {
        self.period = period
    }
    
    public func start() {
        timer = Foundation.Timer.scheduledTimer(
            withTimeInterval: period,
            repeats: true
        ) { _ in
            self.onChange?()
        }
        runLoop.add(timer!, forMode: .common)
        timer?.fire()
    }
    
    public func stop() {
        timer?.invalidate()
    }
}
