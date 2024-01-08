//
// Copyright © 2024 Stream.io Inc. All rights reserved.
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
    let notificationCenter: NotificationCenter

    /// A specific Internet connection monitor.
    private var monitor: InternetConnectionMonitor

    /// Creates a `InternetConnection` with a given monitor.
    /// - Parameter monitor: an Internet connection monitor. Use nil for a default `InternetConnectionMonitor`.
    init(
        notificationCenter: NotificationCenter = .default,
        monitor: InternetConnectionMonitor
    ) {
        self.notificationCenter = notificationCenter
        self.monitor = monitor

        status = monitor.status
        monitor.delegate = self
        monitor.start()
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
protocol InternetConnectionMonitor: AnyObject {
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

extension InternetConnection {
    class Monitor: InternetConnectionMonitor {
        private var monitor: NWPathMonitor?
        private let queue = DispatchQueue(label: "io.getstream.internet-monitor")

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
            monitor?.start(queue: queue)
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
