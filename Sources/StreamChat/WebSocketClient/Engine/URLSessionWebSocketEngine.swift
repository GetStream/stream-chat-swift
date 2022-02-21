//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation

@available(iOS 13, *)
class URLSessionWebSocketEngine: NSObject, WebSocketEngine {
    private weak var task: URLSessionWebSocketTask? {
        didSet {
            oldValue?.cancel()
        }
    }
    
    let request: URLRequest
    private var session: URLSession?
    let delegateOperationQueue: OperationQueue
    let sessionConfiguration: URLSessionConfiguration
    var urlSessionDelegateHandler: URLSessionDelegateHandler?
    
    var callbackQueue: DispatchQueue { delegateOperationQueue.underlyingQueue! }
    
    weak var delegate: WebSocketEngineDelegate?
    
    required init(request: URLRequest, sessionConfiguration: URLSessionConfiguration, callbackQueue: DispatchQueue) {
        self.request = request
        self.sessionConfiguration = sessionConfiguration
        
        delegateOperationQueue = OperationQueue()
        delegateOperationQueue.underlyingQueue = callbackQueue

        super.init()
    }
    
    func connect() {
        urlSessionDelegateHandler = makeURLSessionDelegateHandler()

        session = URLSession(
            configuration: sessionConfiguration,
            delegate: urlSessionDelegateHandler,
            delegateQueue: delegateOperationQueue
        )

        task = session?.webSocketTask(with: request)
        doRead()
        task?.resume()
    }
    
    func disconnect() {
        task?.cancel(with: .normalClosure, reason: nil)
        session?.invalidateAndCancel()

        session = nil
        task = nil
        urlSessionDelegateHandler = nil
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
                    self.callbackQueue.async { [weak self] in
                        self?.delegate?.webSocketDidReceiveMessage(string)
                    }
                }
                self.doRead()
                
            case let .failure(error):
                log.error("Failed receiving Web Socket Message with error: \(error)", subsystems: .webSocket)
            }
        }
    }

    private func makeURLSessionDelegateHandler() -> URLSessionDelegateHandler {
        let urlSessionDelegateHandler = URLSessionDelegateHandler()
        urlSessionDelegateHandler.didOpenWith = { [weak self] _ in
            self?.callbackQueue.async {
                self?.delegate?.webSocketDidConnect()
            }
        }

        urlSessionDelegateHandler.didCloseWith = { [weak self] closeCode, reason in
            var error: WebSocketEngineError?

            if let reasonData = reason, let reasonString = String(data: reasonData, encoding: .utf8) {
                error = WebSocketEngineError(
                    reason: reasonString,
                    code: closeCode.rawValue,
                    engineError: nil
                )
            }

            self?.callbackQueue.async { [weak self] in
                self?.delegate?.webSocketDidDisconnect(error: error)
            }
        }

        urlSessionDelegateHandler.didCompleteWith = { [weak self] error in
            // If we received this callback because we closed the WS connection
            // intentionally, `error` param will be `nil`.
            // Delegate is already informed with `didCloseWith` callback,
            // so we don't need to call delegate again.
            guard let error = error else { return }

            self?.callbackQueue.async { [weak self] in
                self?.delegate?.webSocketDidDisconnect(error: WebSocketEngineError(error: error))
            }
        }

        return urlSessionDelegateHandler
    }
}
    
@available(iOS 13, *)
class URLSessionDelegateHandler: NSObject, URLSessionDataDelegate, URLSessionWebSocketDelegate {
    var didOpenWith: ((_ protocol: String?) -> Void)?
    var didCloseWith: ((_ code: URLSessionWebSocketTask.CloseCode, _ reason: Data?) -> Void)?
    var didCompleteWith: ((Error?) -> Void)?

    public func urlSession(
        _ session: URLSession,
        webSocketTask: URLSessionWebSocketTask,
        didOpenWithProtocol protocol: String?
    ) {
        didOpenWith?(`protocol`)
    }

    func urlSession(
        _ session: URLSession,
        webSocketTask: URLSessionWebSocketTask,
        didCloseWith closeCode: URLSessionWebSocketTask.CloseCode,
        reason: Data?
    ) {
        didCloseWith?(closeCode, reason)
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        didCompleteWith?(error)
    }
}
