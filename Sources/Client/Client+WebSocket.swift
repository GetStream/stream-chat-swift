//
//  Client+WebSocket.swift
//  GetStreamChat
//
//  Created by Alexey Bukhtin on 20/04/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import Foundation

extension Client {
    func setupWebSocket() -> WebSocket? {
        guard let wsURL = baseURL.url(.webSocket), let user = user, let token = token else {
            return nil
        }
        
        let jsonParameter = WebSocketPayload(user: user, token: token)
        
        guard let jsonData = try? JSONEncoder.stream.encode(jsonParameter),
            let jsonString = String(data: jsonData, encoding: .utf8) else {
                return nil
        }
        
        var urlComponents = URLComponents()
        urlComponents.scheme = wsURL.scheme
        urlComponents.host = wsURL.host
        urlComponents.path = wsURL.path.appending("connect")
        
        urlComponents.queryItems = [URLQueryItem(name: "json", value: jsonString),
                                    URLQueryItem(name: "api_key", value: apiKey),
                                    URLQueryItem(name: "authorization", value: token),
                                    URLQueryItem(name: "stream-auth-type", value: "jwt")]
        
        guard let url = urlComponents.url else {
            return nil
        }
        
        return WebSocket(URLRequest(url: url),
                         logger: (logOptions == .all || logOptions == .webSocket ? ClientLogger(icon: "🦄") : nil))
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
