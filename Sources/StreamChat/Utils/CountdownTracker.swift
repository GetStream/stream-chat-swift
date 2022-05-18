//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation

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
