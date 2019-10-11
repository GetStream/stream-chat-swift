//
//  Client+WebSocket.swift
//  StreamChatCore
//
//  Created by Alexey Bukhtin on 20/04/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import Foundation

extension Client {
    func setupWebSocket(user: User, token: Token) -> WebSocket {
        let logger: ClientLogger? = (logOptions == .all || logOptions == .webSocket ? ClientLogger(icon: "🦄") : nil)
        let jsonParameter = WebSocketPayload(user: user, token: token)
        var jsonString = ""
        
        do {
            let jsonData = try JSONEncoder.stream.encode(jsonParameter)
            jsonString = String(data: jsonData, encoding: .utf8) ?? ""
        } catch {
            ClientLogger.log("🦄", error)
        }
        
        if jsonString.isEmpty {
            logger?.log("⚠️", "JSON payload URL is empty")
        }
        
        var urlComponents = URLComponents()
        urlComponents.scheme = baseURL.wsURL.scheme
        urlComponents.host = baseURL.wsURL.host
        urlComponents.path = baseURL.wsURL.path.appending("connect")
        
        urlComponents.queryItems = [URLQueryItem(name: "json", value: jsonString),
                                    URLQueryItem(name: "api_key", value: apiKey),
                                    URLQueryItem(name: "authorization", value: token),
                                    URLQueryItem(name: "stream-auth-type", value: "jwt")]
        
        let url = urlComponents.url
        
        if url == nil {
            logger?.log("⚠️", "Bad URL")
        }
        
        return WebSocket(URLRequest(url: url ?? baseURL.wsURL),
                         stayConnectedInBackground: stayConnectedInBackground,
                         logger: logger)
    }
}

fileprivate struct WebSocketPayload: Encodable {
    private enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case user = "user_details"
        case token = "user_token"
        case serverDeterminesConnectionId = "server_determines_connection_id"
    }
    
    let user: User
    let userId: String
    let token: Token
    let serverDeterminesConnectionId = true
    
    init(user: User, token: Token) {
        self.user = user
        userId = user.id
        self.token = token
    }
}
