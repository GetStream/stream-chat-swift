//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation

/// The controller manages ping and pont timers. It send ping periodically to keep a web socket connection alive.
/// After ping is sent, a pong waiting timer is started and if it does not come, a force disconnect is called.
class WebSocketPingController {
    /// The time interval to ping connection to keep it alive.
    static let pingTimeInterval: TimeInterval = 25
    /// The time interval for pong timeout.
    static let pongTimeoutTimeInterval: TimeInterval = 3
    
    private let timerType: Timer.Type
    private let timerQueue: DispatchQueue
    
    /// The timer used for scheduling `ping` calls
    private lazy var pingTimerControl: RepeatingTimerControl =
        timerType.scheduleRepeating(timeInterval: Self.pingTimeInterval, queue: timerQueue) { [weak self] in self?.sendPing() }
    
    /// The pong timeout timer.
    private var pongTimeoutTimer: TimerControl?
    /// An action for `WebSocketClient` to send a ping.
    private let ping: () -> Void
    /// An action for `WebSocketClient` to force disconnect and reconnect.
    private let forceReconnect: () -> Void
    
    /// Creates a ping controller.
    /// - Parameters:
    ///   - timerType: a timer type.
    ///   - timerQueue: a timer dispatch queue.
    ///   - ping: an action for `WebSocketClient` to send a ping.
    ///   - forceReconnect: an action for `WebSocketClient` to force disconnect and reconnect.
    init(timerType: Timer.Type,
         timerQueue: DispatchQueue,
         ping: @escaping () -> Void,
         forceReconnect: @escaping () -> Void) {
        self.timerType = timerType
        self.timerQueue = timerQueue
        self.ping = ping
        self.forceReconnect = forceReconnect
    }
    
    func connectionStateDidChange(_ connectionState: ConnectionState) {
        cancelPongTimeoutTimer()
        
        if connectionState.isConnected {
            log.info("Resume WebSocket Ping timer")
            pingTimerControl.resume()
        } else {
            pingTimerControl.suspend()
        }
    }
    
    // MARK: - Ping
    
    private func sendPing() {
        // Start pong timeout timer.
        pongTimeoutTimer = timerType.schedule(timeInterval: Self.pongTimeoutTimeInterval, queue: timerQueue) { [weak self] in
            log.info("WebSocket Pong timeout. Reconnect")
            self?.forceReconnect()
        }
        
        log.info("WebSocket Ping")
        ping()
    }
    
    func pongRecieved() {
        log.info("WebSocket Pong")
        cancelPongTimeoutTimer()
    }
    
    private func cancelPongTimeoutTimer() {
        pongTimeoutTimer?.cancel()
        pongTimeoutTimer = nil
    }
}
