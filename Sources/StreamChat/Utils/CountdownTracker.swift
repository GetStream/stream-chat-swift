//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

public class CooldownTracker: @unchecked Sendable {
    private var timer: StreamTimer
    @Atomic private var remainingDuration = 0
    
    public var onChange: ((Int) -> Void)?

    public init(timer: StreamTimer) {
        self.timer = timer
    }

    public func start(with cooldown: Int) {
        guard cooldown > 0 else { return }
        remainingDuration = cooldown
        
        timer.onChange = { [weak self] in
            guard let self else { return }
            onChange?(remainingDuration)

            if remainingDuration == 0 {
                self.timer.stop()
            } else {
                _remainingDuration.mutate { value in
                    value -= 1
                }
            }
        }
        
        timer.start()
    }
    
    public func stop() {
        guard timer.isRunning else { return }

        timer.stop()
    }
    
    deinit {
        stop()
    }
}
