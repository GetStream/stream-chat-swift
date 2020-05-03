//
//  URLSessionWebSocketProvider.swift
//  StreamChatClient
//
//  Created by Alexey Bukhtin on 30/04/2020.
//  Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation

@available(iOS 13, *)
final class URLSessionWebSocketProvider: NSObject, WebSocketProvider, URLSessionDataDelegate, URLSessionWebSocketDelegate {
    private var task: URLSessionWebSocketTask?
    let request: URLRequest
    var isConnected = false
    let callbackQueue: DispatchQueue
    weak var delegate: WebSocketProviderDelegate?
    
    init(request: URLRequest, callbackQueue: DispatchQueue?) {
        self.request = request
        self.callbackQueue = callbackQueue ?? .global()
    }
    
    func connect() {
        let session = URLSession(configuration: URLSessionConfiguration.default, delegate: self, delegateQueue: nil)
        task = session.webSocketTask(with: request)
        doRead()
        task?.resume()
    }
    
    func disconnect() {
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
            case .success(let message):
                switch message {
                case .string(let string):
                    self.delegate?.websocketDidReceiveMessage(self, message: string)
                default:
                    break
                }
            case .failure(let error):
                let providerError = WebSocketProviderError(reason: error.localizedDescription,
                                                           code: (error as NSError).code,
                                                           providerType: URLSessionWebSocketProvider.self,
                                                           providerError: error)
                
                self.delegate?.websocketDidDisconnect(self, error: providerError)
            }
            
            self.doRead()
        }
    }
    
    public func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        delegate?.websocketDidConnect(self)
    }
    
    func urlSession(_ session: URLSession,
                    webSocketTask: URLSessionWebSocketTask,
                    didCloseWith closeCode: URLSessionWebSocketTask.CloseCode,
                    reason: Data?) {
        var error: WebSocketProviderError?
        
        if let reasonData = reason, let reasonString = String(data: reasonData, encoding: .utf8) {
            error = WebSocketProviderError(reason: reasonString,
                                           code: 0,
                                           providerType: URLSessionWebSocketProvider.self,
                                           providerError: nil)
        }
        
        delegate?.websocketDidDisconnect(self, error: error)
    }
}
