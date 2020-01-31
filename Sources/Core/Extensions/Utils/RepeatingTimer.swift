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
    
    private let queue: DispatchQueue?
    private var state: State = .suspended
    let timeInterval: DispatchTimeInterval
    var eventHandler: EventHandler?
    
    private lazy var timer: DispatchSourceTimer = {
        let timer = DispatchSource.makeTimerSource(queue: queue)
        timer.schedule(deadline: .now() + timeInterval, repeating: timeInterval)
        timer.setEventHandler { [weak self] in self?.eventHandler?() }
        return timer
    }()
    
    init(timeInterval: DispatchTimeInterval, queue: DispatchQueue? = nil, eventHandler: EventHandler? = nil) {
        self.timeInterval = timeInterval
        self.queue = queue
        self.eventHandler = eventHandler
    }
    
    deinit {
        timer.setEventHandler {}
        timer.cancel()
        // If the timer is suspended, calling cancel without resuming
        // triggers a crash. This is documented here https://forums.developer.apple.com/thread/15902
        resume()
        eventHandler = nil
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
