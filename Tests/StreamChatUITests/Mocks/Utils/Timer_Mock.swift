//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation

final class Timer_Mock: Foundation.Timer {
    private var hasBeenInvalidated: Bool = false
    
    static var block: (Foundation.Timer) -> Void = { _ in }
    
    override var isValid: Bool { hasBeenInvalidated == false }
    
    override func fire() {
        for _ in 0...Int.max {
            Self.block(self)
            
            if hasBeenInvalidated {
                break
            }
        }
    }
    
    override func invalidate() {
        hasBeenInvalidated = true
    }
    
    override class func scheduledTimer(
        withTimeInterval interval: TimeInterval,
        repeats: Bool,
        block: @escaping (Foundation.Timer) -> Void
    ) -> Foundation.Timer {
        Self.block = block
        
        return self.init()
    }
}
