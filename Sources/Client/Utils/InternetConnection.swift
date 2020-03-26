//
//  InternetConnection.swift
//  StreamChatCore
//
//  Created by Alexey Bukhtin on 02/07/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import UIKit
import Reachability

/// The Internect connection manager.
public final class InternetConnection {
    
    /// The Internet connection reachability.
    public enum State {
        /// Notification of an Internet connection has not begun.
        /// Basically, this is the offline mode.
        case none
        /// The Internet is available.
        case available
        /// The Internet is unavailable.
        case unavailable
    }
    
    /// A callback type of the Internet connection state.
    public typealias OnStateChanged = (State) -> Void

    /// A shared Internet Connection.
    public static let shared = InternetConnection()
    
    /// A callback of the Internet connection state.
    public var onStateChanged: OnStateChanged?
    
    /// The current Internet connection state.
    public private(set) var state: State = .none {
        didSet {
            if lastState != state {
                lastState = state
                self.log("State: \(state)")
                onStateChanged?(state)
            }
        }
    }
    
    /// Checks if the Internet is available.
    public var isAvailable: Bool {
        state == .available
    }
    
    private var lastState: State = .none
    
    private lazy var reachability: Reachability? = {
        let reachability = Reachability(hostname: Client.shared.baseURL.wsURL.host ?? "getstream.io")
        
        func handleReachability(_ reachability: Reachability) {
            if case .none = reachability.connection {
                state = .unavailable
            } else {
                state = .available
            }
        }
        
        reachability?.whenReachable = handleReachability
        reachability?.whenUnreachable = handleReachability
        
        return reachability
    }()
    
    public func startObserving() {
        guard state == .none else {
            return
        }
        
        DispatchQueue.main.async {
            do {
                guard let reachability = self.reachability else { return }
                
                try reachability.startNotifier()
                self.log("Notifying started 🏃‍♂️")

                if case .none = reachability.connection {
                    self.state = .unavailable
                } else {
                    self.state = .available
                }
            } catch {
                self.log("❌ Can't start observation: \(error.localizedDescription)")
            }
        }
    }
    
    /// Stop observing the Internet connection.
    public func stopObserving() {
        DispatchQueue.main.async {
            self.reachability?.stopNotifier()
            self.state = .none
            self.log("Notifying stopped 🚶‍♂️")
        }
    }
    
    // MARK: Logs
    
    func log(_ message: String) {
        if !Client.shared.logOptions.isEmpty {
            ClientLogger.log("🕸", message)
        }
    }
}
