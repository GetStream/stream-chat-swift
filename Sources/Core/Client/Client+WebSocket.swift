//
//  Client+WebSocket.swift
//  StreamChatCore
//
//  Created by Alexey Bukhtin on 20/04/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import Foundation

extension Client {
    func setupWebSocket(user: User, token: Token) -> WebSocket? {
        if apiKey.isEmpty {
            return nil
        }
        
        let logger = logOptions.logger(icon: "🦄", for: [.webSocketError, .webSocket, .webSocketInfo])
        let jsonParameter = WebSocketPayload(user: user, token: token)
        
        var urlComponents = URLComponents()
        urlComponents.scheme = baseURL.wsURL.scheme
        urlComponents.host = baseURL.wsURL.host
        urlComponents.path = baseURL.wsURL.path.appending("connect")
        
        urlComponents.queryItems = [URLQueryItem(name: "api_key", value: apiKey),
                                    URLQueryItem(name: "authorization", value: token),
                                    URLQueryItem(name: "stream-auth-type", value: "jwt")]
        
        do {
            let jsonData = try JSONEncoder.default.encode(jsonParameter)
            
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                urlComponents.queryItems?.append(URLQueryItem(name: "json", value: jsonString))
            } else {
                logger?.log("❌ Can't create a JSON parameter string from the json: \(jsonParameter)", level: .error)
                return nil
            }
        } catch {
            logger?.log(error)
            return nil
        }
        
        guard let url = urlComponents.url else {
            logger?.log("❌ Bad URL: \(urlComponents)", level: .error)
            return nil
        }
        
        var request = URLRequest(url: url)
        request.allHTTPHeaderFields = authHeaders(token: token)
        
        return WebSocket(request, stayConnectedInBackground: stayConnectedInBackground, logger: logger)
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
