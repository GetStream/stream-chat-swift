//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation

@available(iOS 13, *)
class URLSessionWebSocketEngine: NSObject, WebSocketEngine, URLSessionDataDelegate, URLSessionWebSocketDelegate {
    private var task: URLSessionWebSocketTask?
    
    let request: URLRequest
    private var session: URLSession!
    let delegateOperationQueue: OperationQueue
    
    var callbackQueue: DispatchQueue { delegateOperationQueue.underlyingQueue! }
    
    weak var delegate: WebSocketEngineDelegate?
    
    required init(request: URLRequest, sessionConfiguration: URLSessionConfiguration, callbackQueue: DispatchQueue) {
        self.request = request
        
        delegateOperationQueue = OperationQueue()
        delegateOperationQueue.underlyingQueue = callbackQueue
        
        super.init()
        
        session = URLSession(
            configuration: sessionConfiguration,
            delegate: self,
            delegateQueue: delegateOperationQueue
        )
    }
    
    func connect() {
        task = session.webSocketTask(with: request)
        doRead()
        task?.resume()
    }
    
    func disconnect() {
        task?.cancel(with: .normalClosure, reason: nil)
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
                    self.delegate?.webSocketDidReceiveMessage(string)
                }
                self.doRead()
                
            case let .failure(error):
                log.error("Failed receiving Web Socket Message with error: \(error)", subsystems: .webSocket)
            }
        }
    }
    
    public func urlSession(
        _ session: URLSession,
        webSocketTask: URLSessionWebSocketTask,
        didOpenWithProtocol protocol: String?
    ) {
        delegate?.webSocketDidConnect()
    }
    
    func urlSession(
        _ session: URLSession,
        webSocketTask: URLSessionWebSocketTask,
        didCloseWith closeCode: URLSessionWebSocketTask.CloseCode,
        reason: Data?
    ) {
        var error: WebSocketEngineError?
        
        if let reasonData = reason, let reasonString = String(data: reasonData, encoding: .utf8) {
            error = WebSocketEngineError(
                reason: reasonString,
                code: closeCode.rawValue,
                engineError: nil
            )
        }
        
        delegate?.webSocketDidDisconnect(error: error)
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        // If we received this callback because we closed the WS connection
        // intentionally, `error` param will be `nil`.
        // Delegate is already informed with `didCloseWith` callback,
        // so we don't need to call delegate again.
        guard let error = error else { return }
        delegate?.webSocketDidDisconnect(error: WebSocketEngineError(error: error))
    }
}
