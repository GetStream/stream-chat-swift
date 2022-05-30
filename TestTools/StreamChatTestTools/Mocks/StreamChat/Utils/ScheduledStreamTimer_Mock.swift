//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChat

public final class ScheduledStreamTimer_Mock: StreamTimer {
    public var stopCallCount: Int = 0
    public var startCallCount: Int = 0
    
    public var isRunning: Bool = false
    public var onChange: (() -> Void)?
    
    public init() {}
    
    public func start() {
        startCallCount += 1
    }
    
    public func stop() {
        stopCallCount += 1
    }
}
