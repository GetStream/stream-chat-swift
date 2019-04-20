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
        
        let jsonParameters: [String: Any] = ["user_id": user.id,
                                             "user_token": token,
                                             "server_determines_connection_id": true]
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: jsonParameters),
            let jsonString = String(data: jsonData, encoding: .utf8) else {
                return nil
        }
        
        var urlComponents = URLComponents()
        urlComponents.scheme = wsURL.scheme
        urlComponents.host = wsURL.host
        urlComponents.path = wsURL.path.appending("connect")
        
        urlComponents.queryItems = [URLQueryItem(name: "api_key", value: apiKey),
                                    URLQueryItem(name: "authorization", value: token),
                                    URLQueryItem(name: "stream-auth-type", value: "jwt"),
                                    URLQueryItem(name: "json", value: jsonString)]
        
        guard let url = urlComponents.url else {
            return nil
        }
        
        return WebSocket(URLRequest(url: url),
                         logger: (logOptions == .all || logOptions == .webSocket ? ClientLogger(icon: "🦄") : nil))
    }
}
