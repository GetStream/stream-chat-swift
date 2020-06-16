//
// URLSessionWebSocketEngine.swift
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation

@available(iOS 13, *)
final class URLSessionWebSocketEngine: NSObject, WebSocketEngine, URLSessionDataDelegate, URLSessionWebSocketDelegate {
    private var task: URLSessionWebSocketTask?
    let request: URLRequest
    var isConnected = false
    let callbackQueue: DispatchQueue
    weak var delegate: WebSocketEngineDelegate?
    
    init(request: URLRequest, callbackQueue: DispatchQueue) {
        self.request = request
        self.callbackQueue = callbackQueue
    }
    
    func connect() {
        let session = URLSession(configuration: URLSessionConfiguration.default, delegate: self, delegateQueue: nil)
        task = session.webSocketTask(with: request)
        doRead()
        task?.resume()
    }
    
    func disconnect() {
        isConnected = false
        task?.cancel(with: .abnormalClosure, reason: nil)
    }
    
    func sendPing() {
        task?.sendPing { _ in }
    }
    
    private func doRead() {
        task?.receive { [weak self] result in
            guard let self = self else {
                return
            }
            
            switch result {
            case let .success(message):
                if case let .string(string) = message {
                    self.callDelegateInCallbackQueue { $0?.websocketDidReceiveMessage(string) }
                }
                self.doRead()
                
            case let .failure(error):
                self.disconnect(with: WebSocketEngineError(reason: error.localizedDescription,
                                                           code: (error as NSError).code,
                                                           engineError: error))
            }
        }
    }
    
    public func urlSession(
        _ session: URLSession,
        webSocketTask: URLSessionWebSocketTask,
        didOpenWithProtocol protocol: String?
    ) {
        isConnected = true
        callDelegateInCallbackQueue { $0?.websocketDidConnect() }
    }
    
    func urlSession(_ session: URLSession,
                    webSocketTask: URLSessionWebSocketTask,
                    didCloseWith closeCode: URLSessionWebSocketTask.CloseCode,
                    reason: Data?) {
        var error: WebSocketEngineError?
        
        if let reasonData = reason, let reasonString = String(data: reasonData, encoding: .utf8) {
            error = WebSocketEngineError(reason: reasonString,
                                         code: closeCode.rawValue,
                                         engineError: nil)
        }
        
        disconnect(with: error)
    }
    
    private func disconnect(with error: WebSocketEngineError?) {
        isConnected = false
        callDelegateInCallbackQueue { $0?.websocketDidDisconnect(error: error) }
    }
    
    private func callDelegateInCallbackQueue(execute block: @escaping (WebSocketEngineDelegate?) -> Void) {
        callbackQueue.async { [weak self] in
            block(self?.delegate)
        }
    }
}
