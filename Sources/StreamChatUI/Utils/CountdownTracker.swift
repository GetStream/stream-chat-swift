//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import UIKit

public protocol StreamTimer {
    func start()
    func stop()
    var onChange: (() -> Void)? { get set }
    var isRunning: Bool { get }
}

class PeriodicStreamTimer: StreamTimer {
    let period: TimeInterval
    var runLoop = RunLoop.current
    var timer: Timer?
    var onChange: (() -> Void)?
    
    var isRunning: Bool {
        timer?.isValid ?? false
    }
    
    init(period: TimeInterval) {
        self.period = period
    }
    
    func start() {
        timer = Timer.scheduledTimer(
            withTimeInterval: period,
            repeats: true
        ) { _ in
            self.onChange?()
        }
        runLoop.add(timer!, forMode: .common)
        timer?.fire()
    }
    
    func stop() {
        timer?.invalidate()
    }
}

open class CooldownTracker {
    private var timer: StreamTimer
    
    open var onChange: ((Int) -> Void)?
    
    public init(timer: StreamTimer) {
        self.timer = timer
    }
    
    open func start(with cooldown: Int) {
        guard cooldown > 0 else { return }
        
        var duration = cooldown
        
        timer.onChange = { [weak self] in
            self?.onChange?(duration)
            
            if duration == 0 {
                self?.timer.stop()
            } else {
                duration -= 1
            }
        }
        
        timer.start()
    }
    
    open func stop() {
        if timer.isRunning {
            timer.stop()
        }
    }
    
    deinit {
        guard timer.isRunning else { return }
        timer.stop()
    }
}
