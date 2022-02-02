//
// Copyright © 2022 Stream.io Inc. All rights reserved.
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
class WebSocketPingController {
    /// The time interval to ping connection to keep it alive.
    static let pingTimeInterval: TimeInterval = 25
    /// The time interval for pong timeout.
    static let pongTimeoutTimeInterval: TimeInterval = 3
    
    private let timerType: Timer.Type
    private let timerQueue: DispatchQueue
    
    /// The timer used for scheduling `ping` calls
    private var pingTimerControl: RepeatingTimerControl?
    
    /// The pong timeout timer.
    private var pongTimeoutTimer: TimerControl?
    
    /// A delegate to control `WebSocketClient` connection by `WebSocketPingController`.
    weak var delegate: WebSocketPingControllerDelegate?
    
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
        
        if connectionState.isConnected {
            log.info("Resume WebSocket Ping timer")
            pingTimerControl?.resume()
        } else {
            pingTimerControl?.suspend()
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
        guard pingTimerControl == nil else { return }
        pingTimerControl = timerType.scheduleRepeating(timeInterval: Self.pingTimeInterval, queue: timerQueue) { [weak self] in
            self?.sendPing()
        }
    }
    
    private func schedulePongTimeoutTimer() {
        cancelPongTimeoutTimer()
        // Start pong timeout timer.
        pongTimeoutTimer = timerType.schedule(timeInterval: Self.pongTimeoutTimeInterval, queue: timerQueue) { [weak self] in
            log.info("WebSocket Pong timeout. Reconnect")
            self?.delegate?.disconnectOnNoPongReceived()
        }
    }
    
    private func cancelPongTimeoutTimer() {
        pongTimeoutTimer?.cancel()
        pongTimeoutTimer = nil
    }
}
