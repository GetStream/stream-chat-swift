//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

/// A delegate to control `WebSocketClient` connection by `WebSocketPingController`.
protocol WebSocketPingControllerDelegate: AnyObject {
    /// `WebSocketPingController` will call this function periodically to keep a connection alive.
    func sendPing()

    /// `WebSocketPingController` will call this function to force disconnect `WebSocketClient`.
    func disconnectOnNoPongReceived()
}

/// The controller manages ping and pong timers. It sends ping periodically to keep a web socket connection alive.
/// After ping is sent, a pong waiting timer is started, and if pong does not come, a forced disconnect is called.
class WebSocketPingController: @unchecked Sendable {
    /// The time interval to ping connection to keep it alive.
    static let pingTimeInterval: TimeInterval = 25
    /// The time interval for pong timeout.
    static let pongTimeoutTimeInterval: TimeInterval = 3

    private let timerType: Timer.Type
    private let timerQueue: DispatchQueue
    private let queue = DispatchQueue(label: "io.getstream.web-socket-ping-controller", target: .global())

    /// The timer used for scheduling `ping` calls
    private var _pingTimerControl: RepeatingTimerControl?

    /// The pong timeout timer.
    private var _pongTimeoutTimer: TimerControl?

    /// A delegate to control `WebSocketClient` connection by `WebSocketPingController`.
    var delegate: WebSocketPingControllerDelegate? {
        get { queue.sync { _delegate } }
        set { queue.sync { _delegate = newValue } }
    }

    weak var _delegate: WebSocketPingControllerDelegate?

    deinit {
        cancelPongTimeoutTimer()
    }

    /// Creates a ping controller.
    /// - Parameters:
    ///   - timerType: a timer type.
    ///   - timerQueue: a timer dispatch queue.
    init(timerType: Timer.Type, timerQueue: DispatchQueue) {
        self.timerType = timerType
        self.timerQueue = timerQueue
    }

    /// `WebSocketClient` should call this when the connection state did change.
    func connectionStateDidChange(_ connectionState: WebSocketConnectionState) {
        guard delegate != nil else { return }

        cancelPongTimeoutTimer()
        schedulePingTimerIfNeeded()

        queue.sync { [weak self] in
            if connectionState.isConnected {
                log.info("Resume WebSocket Ping timer")
                self?._pingTimerControl?.resume()
            } else {
                self?._pingTimerControl?.suspend()
            }
        }
    }

    // MARK: - Ping

    private func sendPing() {
        schedulePongTimeoutTimer()

        log.info("WebSocket Ping")
        delegate?.sendPing()
    }

    func pongReceived() {
        log.info("WebSocket Pong")
        cancelPongTimeoutTimer()
    }

    // MARK: Timers

    private func schedulePingTimerIfNeeded() {
        queue.sync {
            guard _pingTimerControl == nil else { return }
            _pingTimerControl = timerType.scheduleRepeating(timeInterval: Self.pingTimeInterval, queue: self.timerQueue) { [weak self] in
                self?.sendPing()
            }
        }
    }

    private func schedulePongTimeoutTimer() {
        cancelPongTimeoutTimer()
        // Start pong timeout timer.
        queue.sync {
            self._pongTimeoutTimer = self.timerType.schedule(timeInterval: Self.pongTimeoutTimeInterval, queue: self.timerQueue) { [weak self] in
                log.info("WebSocket Pong timeout. Reconnect")
                self?.delegate?.disconnectOnNoPongReceived()
            }
        }
    }

    private func cancelPongTimeoutTimer() {
        // Called from deinit, must be sync
        queue.sync {
            _pongTimeoutTimer?.cancel()
            _pongTimeoutTimer = nil
        }
    }
}
