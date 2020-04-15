//
//  Application.swift
//  StreamChatCore
//
//  Created by Alexey Bukhtin on 06/02/2020.
//  Copyright © 2020 Stream.io Inc. All rights reserved.
//

import UIKit

final class Application {
    typealias OnStateChanged = (UIApplication.State) -> Void
    static let shared = Application()
    
    private var lastState: UIApplication.State?
    private var subscribers = [NSObjectProtocol]()
    
    /// An application state.
    var onStateChanged: OnStateChanged? {
        didSet {
            if Environment.isTests || Environment.isExtention {
                onStateChanged?(.active)
                return
            }
            
            DispatchQueue.main.async(execute: subscribeForApplicationStateChanges)
        }
    }
    
    private func subscribeForApplicationStateChanges() {
        let center = NotificationCenter.default
        subscribers.forEach { center.removeObserver($0) }
        subscribers = []
        
        guard let onState = onStateChanged else {
            return
        }
        
        func subscribe(for name: Notification.Name, state: UIApplication.State) -> NSObjectProtocol {
            return center.addObserver(forName: name, object: nil, queue: nil) { [unowned self] _ in
                if self.lastState != state {
                    self.lastState = state
                    onState(state)
                }
            }
        }
        
        subscribers.append(subscribe(for: UIApplication.willEnterForegroundNotification, state: .inactive))
        subscribers.append(subscribe(for: UIApplication.didBecomeActiveNotification, state: .active))
        subscribers.append(subscribe(for: UIApplication.willResignActiveNotification, state: .inactive))
        subscribers.append(subscribe(for: UIApplication.didEnterBackgroundNotification, state: .background))
        onState(UIApplication.shared.applicationState)
    }
}

extension UIApplication.State: Equatable, CustomStringConvertible {
    
    public var description: String {
        switch self {
        case .active: return "active"
        case .inactive: return "inactive"
        case .background: return "background"
        @unknown default: return "unknown"
        }
    }
    
    public static func == (lhs: UIApplication.State, rhs: UIApplication.State) -> Bool {
        switch (lhs, rhs) {
        case (.active, .active), (.inactive, .inactive), (.background, .background): return true
        default: return false
        }
    }
}
