//
// WebSocketEngine.swift
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation

protocol WebSocketEngine: AnyObject {
  var request: URLRequest { get }
  var isConnected: Bool { get }
  var callbackQueue: DispatchQueue { get }
  var delegate: WebSocketEngineDelegate? { get set }

  init(request: URLRequest, callbackQueue: DispatchQueue)
  func connect()
  func disconnect()
  func sendPing()
}

protocol WebSocketEngineDelegate: AnyObject {
  func websocketDidConnect()
  func websocketDidDisconnect(error: WebSocketProviderError?)
  func websocketDidReceiveMessage(_ message: String)
}

struct WebSocketProviderError: Error {
  static let stopErrorCode = 1000

  let reason: String
  let code: Int
  let providerType: WebSocketEngine.Type
  let providerError: Error?

  var localizedDescription: String { reason }
}

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
      case .success(let message):
        if case .string(let string) = message {
          self.callDelegateInCallbackQueue { $0?.websocketDidReceiveMessage(string) }
        }
        self.doRead()

      case .failure(let error):
        self.disconnect(with: WebSocketProviderError(
          reason: error.localizedDescription,
          code: (error as NSError).code,
          providerType: URLSessionWebSocketEngine.self,
          providerError: error
        ))
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
    var error: WebSocketProviderError?

    if let reasonData = reason, let reasonString = String(data: reasonData, encoding: .utf8) {
      error = WebSocketProviderError(
        reason: reasonString,
        code: 0,
        providerType: URLSessionWebSocketEngine.self,
        providerError: nil
      )
    }

    disconnect(with: error)
  }

  private func disconnect(with error: WebSocketProviderError?) {
    isConnected = true
    callDelegateInCallbackQueue { $0?.websocketDidDisconnect(error: error) }
  }

  private func callDelegateInCallbackQueue(execute block: @escaping (WebSocketEngineDelegate?) -> Void) {
    callbackQueue.async { [weak self] in
      block(self?.delegate)
    }
  }
}
