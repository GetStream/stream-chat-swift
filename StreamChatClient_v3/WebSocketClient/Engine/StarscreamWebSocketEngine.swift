//
// StarscreamWebSocketEngine.swift
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation

#if canImport(Starscream)
import Starscream

final class StarscreamWebSocketProvider: WebSocketEngine {
  private let webSocket: Starscream.WebSocket
  var request: URLRequest { webSocket.request }
  var isConnected: Bool { webSocket.isConnected }
  var callbackQueue: DispatchQueue { webSocket.callbackQueue }
  weak var delegate: WebSocketEngineDelegate?

  init(request: URLRequest, callbackQueue: DispatchQueue) {
    self.webSocket = Starscream.WebSocket(request: request)
    webSocket.delegate = self
    webSocket.callbackQueue = callbackQueue
  }

  func connect() {
    webSocket.connect()
  }

  func disconnect() {
    webSocket.disconnect(forceTimeout: 0)
  }

  func sendPing() {
    webSocket.write(ping: Data([]))
  }
}

extension StarscreamWebSocketProvider: Starscream.WebSocketDelegate {
  func websocketDidConnect(socket: Starscream.WebSocketClient) {
    delegate?.websocketDidConnect()
  }

  func websocketDidDisconnect(socket: Starscream.WebSocketClient, error: Error?) {
    var webSocketProviderError: WebSocketProviderError?

    if let error = error {
      webSocketProviderError = .init(
        reason: error.localizedDescription,
        code: (error as? WSError)?.code ?? 0,
        providerType: StarscreamWebSocketProvider.self,
        providerError: error
      )
    }

    delegate?.websocketDidDisconnect(error: webSocketProviderError)
  }

  func websocketDidReceiveMessage(socket: Starscream.WebSocketClient, text: String) {
    delegate?.websocketDidReceiveMessage(text)
  }

  func websocketDidReceiveData(socket: Starscream.WebSocketClient, data: Data) {}
}

#endif
