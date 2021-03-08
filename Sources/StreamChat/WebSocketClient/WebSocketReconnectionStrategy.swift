//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation

protocol WebSocketClientReconnectionStrategy {
    /// Called when the web socket connection is successfully established.
    mutating func sucessfullyConnected()
    
    /// Called when the web socket connection is disconnected or fails to connect.
    ///
    /// - Parameter error: The error reported by the engine when disconnected. If `nil`, no error was reported.
    /// - Returns: The delay before the next connection attempt. `nil` if no reconnection should happen.
    mutating func reconnectionDelay(forConnectionError error: Error?) -> TimeInterval?
}

class DefaultReconnectionStrategy: WebSocketClientReconnectionStrategy {
    static let maximumReconnectionDelay: TimeInterval = 25
    
    private var consecutiveFailures = 0
    
    func sucessfullyConnected() {
        consecutiveFailures = 0
    }
    
    func reconnectionDelay(forConnectionError error: Error?) -> TimeInterval? {
        if let wsEngineError = error as? WebSocketEngineError {
            if wsEngineError.code == WebSocketEngineError.stopErrorCode {
                // Don't reconnect on `stop` errors
                return nil
            }
            
            if wsEngineError.engineError?.isInternetOfflineError == true {
                // Don't try to reconnect when internet is not available
                return nil
            }
        }
        
        if let serverInitiatedError = error as? ErrorPayload {
            if ErrorPayload.tokenInvadlidErrorCodes ~= serverInitiatedError.code {
                // Don't reconnect on invalid token errors
                return nil
            }
        
            if 400...499 ~= serverInitiatedError.statusCode {
                // Don't reconnect on client side errors
                return nil
            }
        }
        
        let maxDelay: TimeInterval = min(0.5 + Double(consecutiveFailures * 2), Self.maximumReconnectionDelay)
        let minDelay: TimeInterval = min(max(0.25, (Double(consecutiveFailures) - 1) * 2), Self.maximumReconnectionDelay)
        consecutiveFailures += 1
        let delay = TimeInterval.random(in: minDelay...maxDelay)
        
        return delay
    }
}
