//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation

#if canImport(Starscream)
import Starscream
    
class StarscreamWebSocketProvider: WebSocketEngine {
    private let webSocket: Starscream.WebSocket
    var request: URLRequest { webSocket.request }
    var callbackQueue: DispatchQueue { webSocket.callbackQueue }
    weak var delegate: WebSocketEngineDelegate?
        
    required init(request: URLRequest, sessionConfiguration: URLSessionConfiguration, callbackQueue: DispatchQueue) {
        // Starscream doesn't support taking session configuration as a parameter se we need to copy
        // the headers manually.
        let requestHeaders = request.allHTTPHeaderFields ?? [:]
        let sessionHeaders = sessionConfiguration.httpAdditionalHeaders as? [String: String] ?? [:]
            
        let allHeaders = requestHeaders.merging(sessionHeaders, uniquingKeysWith: { fromRequest, _ in
            // In case of duplicity, use the request header value
            fromRequest
        })
            
        var request = request
        request.allHTTPHeaderFields = allHeaders
            
        webSocket = Starscream.WebSocket(request: request)
        webSocket.delegate = self
        webSocket.callbackQueue = callbackQueue
    }
        
    func connect() {
        webSocket.connect()
    }
        
    func disconnect() {
        webSocket.disconnect()
    }
        
    func sendPing() {
        webSocket.write(ping: Data([]))
    }
}
    
extension StarscreamWebSocketProvider: Starscream.WebSocketDelegate {
    func didReceive(event: WebSocketEvent, client: WebSocket) {
        switch event {
        case .connected:
            delegate?.webSocketDidConnect()
        case let .text(text):
            delegate?.webSocketDidReceiveMessage(text)
        case let .error(error):
            delegate?.webSocketDidDisconnect(error: error.map(WebSocketEngineError.init))
        case let .disconnected(reason, code):
            let error = WebSocketEngineError(reason: reason, code: Int(code), engineError: nil)
            delegate?.webSocketDidDisconnect(error: error)
        case .cancelled:
            let error = WebSocketEngineError(
                reason: "Cancelled",
                code: -1,
                engineError: nil
            )
            delegate?.webSocketDidDisconnect(error: error)
        default:
            break
        }
    }
}
    
#endif
