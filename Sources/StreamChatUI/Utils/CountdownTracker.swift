//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import UIKit

open class CooldownTracker {
    private let runLoop: RunLoop
    private var timer: Timer.Type
    private var currentTimer: Timer?
    
    public init(runloop: RunLoop = .current, timer: Timer.Type = Timer.self) {
        runLoop = runloop
        self.timer = timer
    }
    
    open func start(with cooldown: Int, onChange: @escaping (Int) -> Void) {
        guard cooldown > 0 else { return }
        
        var duration = cooldown
        currentTimer = timer.scheduledTimer(
            withTimeInterval: 1,
            repeats: true
        ) { timer in
            onChange(duration)
            
            if duration == 0 {
                timer.invalidate()
            } else {
                duration -= 1
            }
        }
        
        runLoop.add(currentTimer!, forMode: .common)
        currentTimer?.fire()
    }
    
    deinit {
        guard let timer = self.currentTimer, timer.isValid else { return }
        
        runLoop.perform(inModes: [.common], block: {
            timer.invalidate()
        })
    }
}
