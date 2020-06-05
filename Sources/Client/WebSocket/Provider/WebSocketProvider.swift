//
//  WebSocketProvider.swift
//  StreamChatClient
//
//  Created by Alexey Bukhtin on 30/04/2020.
//  Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation

protocol WebSocketProvider {
    var request: URLRequest { get set }
    var isConnected: Bool { get }
    var callbackQueue: DispatchQueue { get }
    var delegate: WebSocketProviderDelegate? { get set }
    
    init(request: URLRequest, callbackQueue: DispatchQueue)
    func connect()
    func disconnect()
    func sendPing()
}

protocol WebSocketProviderDelegate: class {
    func websocketDidConnect()
    func websocketDidDisconnect(error: WebSocketProviderError?)
    func websocketDidReceiveMessage(_ message: String)
}

struct WebSocketProviderError: Error {
    static let stopErrorCode = 1000
    
    let reason: String
    let code: Int
    let providerType: WebSocketProvider.Type
    let providerError: Error?
    
    var localizedDescription: String { reason }
}
