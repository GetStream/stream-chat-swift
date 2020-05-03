//
//  InternetConnection.swift
//  StreamChatCore
//
//  Created by Alexey Bukhtin on 02/07/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import UIKit

/// The Internect connection manager.
public final class InternetConnection {
    
    /// The Internet connection reachability.
    public enum State {
        /// Notification of an Internet connection has not begun.
        /// Basically, this is the offline mode.
        case unknown
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
    public private(set) var state: State = .unknown {
        didSet {
            if lastState != state {
                lastState = state
                self.log("State: \(state) (\(reachability?.description ?? ""))")
                onStateChanged?(state)
            }
        }
    }
    
    /// Checks if the Internet is available.
    public var isAvailable: Bool {
        state == .available
    }
    
    private var lastState: State = .unknown
    private lazy var reachability: Reachability? = {
        do {
            let reachability: Reachability
            
            if let hostname = Client.shared.baseURL.wsURL.host {
                reachability = try Reachability(hostname: hostname)
            } else {
                reachability = try Reachability()
            }
            
            reachability.whenReachable = { [unowned self] _ in self.state = .available }
            reachability.whenUnreachable = { [unowned self] _ in self.state = .unavailable }
            return reachability
        } catch {
            log("❌ Can't initiate Reachability: \(error)")
            return nil
        }
    }()
    
    /// Start observing the Internet connection state.
    func startNotifier() {
        guard state == .unknown else {
            DispatchQueue.main.async {
                try? self.reachability?.startNotifier()
                self.onStateChanged?(self.state)
            }
            
            return
        }
        
        DispatchQueue.main.async {
            do {
                guard let reachability = self.reachability else { return }
                
                try reachability.startNotifier()
                self.log("Notifying started 🏃‍♂️")
                
                if case .unavailable = reachability.connection {
                    self.state = .unavailable
                } else {
                    self.state = .available
                }
            } catch {
                self.log("❌ Can't start observation: \(error.localizedDescription)")
            }
        }
    }
    
    /// Stop observing the Internet connection state.
    func stopNotifier() {
        DispatchQueue.main.async {
            self.reachability?.stopNotifier()
            self.state = .unknown
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
