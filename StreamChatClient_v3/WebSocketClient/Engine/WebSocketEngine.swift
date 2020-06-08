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
