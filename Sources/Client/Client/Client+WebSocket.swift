//
//  Client+WebSocket.swift
//  StreamChatCore
//
//  Created by Alexey Bukhtin on 20/04/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import Foundation

extension Client {
    
    func setupWebSocket(user: User, token: Token) throws -> WebSocket {
        let logger = logOptions.logger(icon: "🦄", for: [.webSocketError, .webSocket, .webSocketInfo])
        let jsonParameter = WebSocketPayload(user: user, token: token)
        
        var urlComponents = URLComponents()
        urlComponents.scheme = baseURL.wsURL.scheme
        urlComponents.host = baseURL.wsURL.host
        urlComponents.path = baseURL.wsURL.path.appending("connect")
        urlComponents.queryItems = [URLQueryItem(name: "api_key", value: apiKey)]
        
        if user.isAnonymous {
            urlComponents.queryItems?.append(URLQueryItem(name: "stream-auth-type", value: "anonymous"))
        } else {
            urlComponents.queryItems?.append(URLQueryItem(name: "authorization", value: token))
            urlComponents.queryItems?.append(URLQueryItem(name: "stream-auth-type", value: "jwt"))
        }
        
        let jsonData = try JSONEncoder.default.encode(jsonParameter)
        
        if let jsonString = String(data: jsonData, encoding: .utf8) {
            urlComponents.queryItems?.append(URLQueryItem(name: "json", value: jsonString))
        } else {
            logger?.log("❌ Can't create a JSON parameter string from the json: \(jsonParameter)", level: .error)
        }
        
        guard let url = urlComponents.url else {
            logger?.log("❌ Bad URL: \(urlComponents)", level: .error)
            throw ClientError.invalidURL(urlComponents.description)
        }
        
        var request = URLRequest(url: url)
        request.allHTTPHeaderFields = authHeaders(token: token)
        
        let callbackQueue = DispatchQueue(label: "io.getstream.Chat.WebSocket", qos: .userInitiated)
        let webSocketOptions = stayConnectedInBackground ? WebSocketOptions.stayConnectedInBackground : []
        let webSocketProvider = defaultWebSocketProviderType.init(request: request, callbackQueue: callbackQueue)
        
        let webSocket = WebSocket(webSocketProvider, options: webSocketOptions, logger: logger)
        webSocket.eventDelegate = self
        return webSocket
    }
    
    private func recoverConnection() {
        guard needsToRecoverConnection else {
            return
        }
        
        needsToRecoverConnection = false
        restoreWatchingChannels()
    }
    
    private func restoreWatchingChannels() {
        watchingChannelsAtomic.flush()
        
        let keys = watchingChannelsAtomic.get().keys
        guard !keys.isEmpty else {
            return
        }
        
        let cids = Array(keys).chunked(into: 50)
        
        cids.forEach { chunk in
            queryChannels(filter: .in("cid", chunk),
                          pagination: [.limit(1)],
                          messagesLimit: [.limit(1)],
                          options: .watch) { _ in }
        }
    }
}

extension Client: WebSocketEventDelegate {
    func shouldPublishEvent(_ event: Event) -> Bool {
        switch event {
        case .connectionChanged(let connectionState):
            if case .connected(let userConnection) = connectionState {
                unreadCountAtomic.set(userConnection.user.unreadCount)
                userAtomic.set(userConnection.user)
                recoverConnection()
                
                if isExpiredTokenInProgress {
                    performInCallbackQueue { [unowned self] in self.sendWaitingRequests() }
                }
            } else if case .reconnecting = connectionState {
                needsToRecoverConnection = true
            }
            
            return true
            
        case .notificationMutesUpdated(let user, _, _):
            userAtomic.set(user)
            return true
            
        case let .messageNew(message, _, _, _) where message.user != user && user.isMuted(user: message.user):
            // FIXIT: This shouldn't be by default.
            logger?.log("Skip a message (\(message.id)) from muted user (\(message.user.id)): \(message.textOrArgs)", level: .info)
            return false
            
        case let .typingStart(user, _, _), let .typingStop(user, _, _):
            if user != self.user, self.user.isMuted(user: user) {
                logger?.log("Skip typing events from muted user (\(user.id))", level: .info)
                return false
            }
            
        default: break
        }
        
        updateUserUnreadCount(event: event) // User unread counts should be updated before channels unread counts.
        updateChannelsForWatcherAndUnreadCount(event: event)
        
        return true
    }
}

private struct WebSocketPayload: Encodable {
    private enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case userDetails = "user_details"
        case token = "user_token"
        case serverDeterminesConnectionId = "server_determines_connection_id"
    }
    
    let userDetails: User
    let userId: String
    let token: Token
    let serverDeterminesConnectionId = true
    
    init(user: User, token: Token) {
        userDetails = user
        userId = user.id
        self.token = token
    }
}
