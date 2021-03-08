//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation

protocol WebSocketEngine: AnyObject {
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

struct WebSocketEngineError: Error {
    static let stopErrorCode = 1000
    
    let reason: String
    let code: Int
    let engineError: Error?
    
    var localizedDescription: String { reason }
}

extension WebSocketEngineError {
    init(error: Error?) {
        if let error = error {
            self.init(
                reason: error.localizedDescription,
                code: (error as NSError).code,
                engineError: error
            )
        } else {
            self.init(
                reason: "Unknown",
                code: 0,
                engineError: nil
            )
        }
    }
}
