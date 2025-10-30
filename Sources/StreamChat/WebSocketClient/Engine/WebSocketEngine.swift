//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

protocol WebSocketEngine: AnyObject, Sendable {
    var request: URLRequest { get }
    var callbackQueue: DispatchQueue { get }
    var delegate: WebSocketEngineDelegate? { get set }

    init(request: URLRequest, sessionConfiguration: URLSessionConfiguration, callbackQueue: DispatchQueue)

    func connect()
    func disconnect()
    func sendPing()
}

protocol WebSocketEngineDelegate: AnyObject {
    func webSocketDidConnect()
    func webSocketDidDisconnect(error: WebSocketEngineError?)
    func webSocketDidReceiveMessage(_ message: String)
}
