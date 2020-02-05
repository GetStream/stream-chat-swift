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
    /// A Internet Connection availability changes block type.
    public typealias OnChange = (Bool) -> Void
    /// A shared Internet Connection.
    public static let shared = InternetConnection()
    
    private lazy var reachability = Reachability(hostname: Client.shared.baseURL.wsURL.host ?? "getstream.io")
    
    /// A Internet Connection availability changes block.
    public var onChange: OnChange = { _ in }
    
    /// Forces to offline mode.
    public var offlineMode = false {
        didSet {
            log("✈️ Offline mode is \(offlineMode ? "On" : "Off").")
            onChange(false)
            
            if offlineMode {
                stopObserving()
            } else if UIApplication.shared.applicationState != .background {
                startObserving()
            }
        }
    }
    
    /// Check if the Internet is available.
    public var isAvailable: Bool {
        if offlineMode {
            return false
        }
        
        let connection = reachability?.connection ?? .none
        
        if case .none  = connection {
            return false
        }
        
        return true
    }
    
    /// Init InternetConnection.
    init() {
        if !isTestsEnvironment() {
            return
        }
        
        reachability?.whenReachable = { [unowned self] reachability in
            self.log("Available 🙋‍♂️")
            self.onChange(reachability.connection != .none)
        }
        
        reachability?.whenUnreachable = { [unowned self] reachability in
            self.log("Not Available 🤷‍♂️")
            self.onChange(reachability.connection != .none)
        }
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(appDidBecomeActiveNotification),
                                               name: UIApplication.didBecomeActiveNotification,
                                               object: nil)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(appDidEnterBackgroundNotification),
                                               name: UIApplication.didEnterBackgroundNotification,
                                               object: nil)
        
        DispatchQueue.main.async { self.startObserving() }
    }
    
    /// An active app state.
    @objc private func appDidBecomeActiveNotification() {
        if !offlineMode {
            startObserving()
        }
    }
    
    /// A background app state.
    @objc private func appDidEnterBackgroundNotification() {
        stopObserving()
    }
    
    // MARK: Observing Availability
    
    private func startObserving() {
        do {
            try reachability?.startNotifier()
            log("Notifying started 🏃‍♂️")
        } catch {
            log("InternetConnection tried to start notifying when app state became active.\n\(error)")
        }
    }
    
    /// Stop observing the Internet connection.
    public func stopObserving() {
        reachability?.stopNotifier()
        log("Notifying stopped 🚶‍♂️")
    }
    
    // MARK: Logs
    
    private func log(_ message: String) {
        if Client.shared.logOptions.isEnabled {
            ClientLogger.log("🕸", message)
        }
    }
}
