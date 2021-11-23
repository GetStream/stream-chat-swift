//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation
import Network

extension Notification.Name {
    /// Posted when any the Internet connection update is detected (including quality updates).
    static let internetConnectionStatusDidChange = Self("io.getstream.StreamChat.internetConnectionStatus")
    
    /// Posted only when the Internet connection availability is changed (excluding quality updates).
    static let internetConnectionAvailabilityDidChange = Self("io.getstream.StreamChat.internetConnectionAvailability")
}

extension Notification {
    static let internetConnectionStatusUserInfoKey = "internetConnectionStatus"
    
    var internetConnectionStatus: InternetConnection.Status? {
        userInfo?[Self.internetConnectionStatusUserInfoKey] as? InternetConnection.Status
    }
}

/// An Internet Connection monitor.
///
/// Basically, it's a wrapper over legacy monitor based on `Reachability` (iOS 11 only)
/// and default monitor based on `Network`.`NWPathMonitor` (iOS 12+).
class InternetConnection {
    /// The current Internet connection status.
    private(set) var status: InternetConnection.Status {
        didSet {
            guard oldValue != status else { return }
            
            log.info("Internet Connection: \(status)")
            
            postNotification(.internetConnectionStatusDidChange, with: status)
            
            guard oldValue.isAvailable != status.isAvailable else { return }
            
            postNotification(.internetConnectionAvailabilityDidChange, with: status)
        }
    }
    
    /// The notification center that posts notifications when connection state changes..
    var notificationCenter: NotificationCenter
    
    /// A specific Internet connection monitor.
    private var monitor: InternetConnectionMonitor
    
    /// Creates a `InternetConnection` with a given monitor.
    /// - Parameter monitor: an Internet connection monitor. Use nil for a default `InternetConnectionMonitor`.
    init(
        notificationCenter: NotificationCenter = .default,
        monitor: InternetConnectionMonitor? = nil
    ) {
        self.notificationCenter = notificationCenter
        
        if let monitor = monitor {
            self.monitor = monitor
        } else if #available(iOS 12, *) {
            self.monitor = Monitor()
        } else {
            self.monitor = LegacyMonitor()
        }
        
        status = self.monitor.status
        self.monitor.delegate = self
        self.monitor.start()
    }
    
    deinit {
        monitor.stop()
    }
}

extension InternetConnection: InternetConnectionDelegate {
    func internetConnectionStatusDidChange(status: Status) {
        self.status = status
    }
}

private extension InternetConnection {
    func postNotification(_ name: Notification.Name, with status: Status) {
        notificationCenter.post(
            name: name,
            object: self,
            userInfo: [Notification.internetConnectionStatusUserInfoKey: status]
        )
    }
}

// MARK: - Internet Connection Monitors

/// A delegate to receive Internet connection events.
protocol InternetConnectionDelegate: AnyObject {
    /// Calls when the Internet connection status did change.
    /// - Parameter status: an Internet connection status.
    func internetConnectionStatusDidChange(status: InternetConnection.Status)
}

/// A protocol for Internet connection monitors.
protocol InternetConnectionMonitor {
    /// A delegate for receiving Internet connection events.
    var delegate: InternetConnectionDelegate? { get set }
    
    /// The current status of Internet connection.
    var status: InternetConnection.Status { get }
    
    /// Start Internet connection monitoring.
    func start()
    /// Stop Internet connection monitoring.
    func stop()
}

// MARK: Internet Connection Subtypes

extension InternetConnection {
    /// The Internet connectivity status.
    enum Status: Equatable {
        /// Notification of an Internet connection has not begun.
        case unknown
        
        /// The Internet is available with a specific `Quality` level.
        case available(Quality)
        
        /// The Internet is unavailable.
        case unavailable
    }
    
    /// The Internet connectivity status quality.
    enum Quality: Equatable {
        /// The Internet connection is great (like Wi-Fi).
        case great
        
        /// Internet connection uses an interface that is considered expensive, such as Cellular or a Personal Hotspot.
        case expensive
        
        /// Internet connection uses Low Data Mode.
        /// Recommendations for Low Data Mode: don't autoplay video, music (high-quality) or gifs (big files).
        /// Supports only by iOS 13+
        case constrained
    }
}

extension InternetConnection.Status {
    /// Returns `true` if the internet connection is available, ignoring the quality of the connection.
    var isAvailable: Bool {
        if case .available = self {
            return true
        } else {
            return false
        }
    }
}

// MARK: - Internet Connection Monitor

private extension InternetConnection {
    /// The default Internet connection monitor for iOS 12+.
    /// It uses Apple Network API.
    @available(iOS 12, *)
    class Monitor: InternetConnectionMonitor {
        private var monitor: NWPathMonitor?
        
        weak var delegate: InternetConnectionDelegate?
        
        var status: InternetConnection.Status {
            if let path = monitor?.currentPath {
                return status(from: path)
            }
            
            return .unknown
        }
        
        func start() {
            guard monitor == nil else { return }
            
            monitor = createMonitor()
            monitor?.start(queue: .global())
        }
        
        func stop() {
            monitor?.cancel()
            monitor = nil
        }
        
        private func createMonitor() -> NWPathMonitor {
            let monitor = NWPathMonitor()
            
            // We should be able to do `[weak self]` here, but it seems `NWPathMonitor` sometimes calls the handler
            // event after `cancel()` has been called on it.
            monitor.pathUpdateHandler = { [weak self] in
                self?.updateStatus(with: $0)
            }
            return monitor
        }
        
        private func updateStatus(with path: NWPath) {
            log.info("Internet Connection info: \(path.debugDescription)")
            delegate?.internetConnectionStatusDidChange(status: status(from: path))
        }
        
        private func status(from path: NWPath) -> InternetConnection.Status {
            guard path.status == .satisfied else {
                return .unavailable
            }
            
            let quality: InternetConnection.Quality
            
            if #available(iOS 13.0, *) {
                quality = path.isConstrained ? .constrained : (path.isExpensive ? .expensive : .great)
            } else {
                quality = path.isExpensive ? .expensive : .great
            }
            
            return .available(quality)
        }
        
        deinit {
            stop()
        }
    }
}

// MARK: Legacy Internet Connection Monitor for iOS 11 only

private extension InternetConnection {
    class LegacyMonitor: InternetConnectionMonitor {
        /// A Reachability instance for Internet connection monitoring.
        private lazy var reachability = createReachability()
        
        weak var delegate: InternetConnectionDelegate?
        
        var status: InternetConnection.Status {
            if let reachability = reachability {
                return status(from: reachability)
            }
            
            return .unknown
        }
        
        func start() {
            do {
                try reachability?.startNotifier()
            } catch {
                log.error(error)
            }
        }
        
        func stop() {
            reachability?.stopNotifier()
        }
        
        private func createReachability() -> Reachability? {
            var reachability: Reachability?
            
            do {
                reachability = try Reachability()
                reachability?.whenReachable = { [weak self] in self?.updateStatus(with: $0) }
                reachability?.whenUnreachable = { [weak self] in self?.updateStatus(with: $0) }
            } catch {
                log.error(error)
            }
            
            return reachability
        }
        
        private func updateStatus(with reachability: Reachability) {
            log.info("Internet Connection info: \(reachability.description)")
            
            if case .unavailable = reachability.connection {
                delegate?.internetConnectionStatusDidChange(status: .unavailable)
                return
            }
            
            let quality: InternetConnection.Quality
            
            if case .cellular = reachability.connection {
                quality = .expensive
            } else {
                quality = .great
            }
            
            delegate?.internetConnectionStatusDidChange(status: .available(quality))
        }
        
        private func status(from reachability: Reachability) -> InternetConnection.Status {
            if case .unavailable = reachability.connection {
                return .unavailable
            }
            
            let quality: InternetConnection.Quality
            
            if case .cellular = reachability.connection {
                quality = .expensive
            } else {
                quality = .great
            }
            
            return .available(quality)
        }
    }
}
