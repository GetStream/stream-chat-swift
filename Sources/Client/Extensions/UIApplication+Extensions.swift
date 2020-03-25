//
//  UIApplication+Rx.swift
//  StreamChatCore
//
//  Created by Alexey Bukhtin on 06/02/2020.
//  Copyright © 2020 Stream.io Inc. All rights reserved.
//

import UIKit

extension UIApplication {
    private static var onStateChangedKey: UInt8 = 0
    private static var lastStateKey: UInt8 = 0
    
    typealias OnStateChanged = (UIApplication.State) -> Void
    
    private var lastState: UIApplication.State {
        get { associated(to: self, key: &UIApplication.lastStateKey) { UIApplication.shared.applicationState } }
        set { associate(to: self, key: &UIApplication.lastStateKey, value: newValue) }
    }
    
    /// An application state.
    var onStateChanged: OnStateChanged? {
        get { nil }
        set {
            let center = NotificationCenter.default
            
            var subscribers = associated(to: self, key: &UIApplication.onStateChangedKey) { [NSObjectProtocol]() }
            subscribers.forEach({ center.removeObserver($0) })
            
            guard let onState = newValue else {
                return
            }
            
            subscribers = []
            
            func subscribe(for name: Notification.Name, state: UIApplication.State) -> NSObjectProtocol {
                return center.addObserver(forName: name, object: nil, queue: nil) { [unowned self] _ in
                    if self.lastState != state {
                        self.lastState = state
                        onState(state)
                    }
                }
            }
            
            subscribers.append(subscribe(for: UIApplication.didBecomeActiveNotification, state: .active))
            subscribers.append(subscribe(for: UIApplication.didEnterBackgroundNotification, state: .background))
            associate(to: self, key: &UIApplication.onStateChangedKey, value: subscribers)
        }
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
