//
//  RepeatingTimer.swift
//  StreamChatCore
//
//  Created by Alexey Bukhtin on 18/04/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import Foundation

final class RepeatingTimer {
    private enum State {
        case suspended
        case resumed
    }
    
    typealias EventHandler = () -> Void
    
    private var state: State = .suspended
    private let timer: DispatchSourceTimer
    
    init(timeInterval: DispatchTimeInterval, queue: DispatchQueue, eventHandler: @escaping EventHandler) {
        timer = DispatchSource.makeTimerSource(queue: queue)
        timer.schedule(deadline: .now() + timeInterval, repeating: timeInterval, leeway: .seconds(1))
        timer.setEventHandler(handler: eventHandler)
    }
    
    deinit {
        timer.setEventHandler {}
        timer.cancel()
        // If the timer is suspended, calling cancel without resuming
        // triggers a crash. This is documented here https://forums.developer.apple.com/thread/15902
        resume()
    }
    
    func resume() {
        if state == .resumed {
            return
        }
        
        state = .resumed
        timer.resume()
    }
    
    func suspend() {
        if state == .suspended {
            return
        }
        
        state = .suspended
        timer.suspend()
    }
}
