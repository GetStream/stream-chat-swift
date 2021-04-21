//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation

/// A delegate to control `WebSocketClient` connection by `WebSocketPingController`.
protocol WebSocketPingControllerDelegate: AnyObject {
    /// `WebSocketPingController` will call it method periodically to keep a connection alive.
    func sendPing()
    
    /// `WebSocketPingController` will call it to force disconnect `WebSocketClient`.
    func disconnectOnNoPongReceived()
}

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
    
    /// A delegate to control `WebSocketClient` connection by `WebSocketPingController`.
    weak var delegate: WebSocketPingControllerDelegate?
    
    /// Creates a ping controller.
    /// - Parameters:
    ///   - timerType: a timer type.
    ///   - timerQueue: a timer dispatch queue.
    ///   - ping: an action for `WebSocketClient` to send a ping.
    ///   - forceReconnect: an action for `WebSocketClient` to force disconnect and reconnect.
    init(timerType: Timer.Type, timerQueue: DispatchQueue) {
        self.timerType = timerType
        self.timerQueue = timerQueue
    }
    
    /// `WebSocketClient` should call this when the connection state did change.
    func connectionStateDidChange(_ connectionState: WebSocketConnectionState) {
        guard delegate != nil else { return }
        
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
            self?.delegate?.disconnectOnNoPongReceived()
        }
        
        log.info("WebSocket Ping")
        delegate?.sendPing()
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
