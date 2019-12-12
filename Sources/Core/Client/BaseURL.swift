//
//  BaseURL.swift
//  StreamChatCore
//
//  Created by Alexey Bukhtin on 01/04/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import Foundation

/// A base URL for the `Client`.
public struct BaseURL: CustomStringConvertible {
    static let placeholderURL = URL(string: "https://getstream.io")!
    
    let baseURL: URL
    let wsURL: URL
    
    public var description: String { return baseURL.absoluteString }
    
    /// Create a base URL.
    /// - Parameter serverLocation: a Stream Chat server location.
    public init(serverLocation: ServerLocation = .usEast) {
        self.init(customURL: URL(string: serverLocation.rawValue)!)
    }
    
    /// Init with a custom server URL.
    ///
    /// - Parameter url: an URL
    public init(customURL url: URL) {
        var urlString = url.absoluteString
        
        // Remove a scheme prefix.
        for prefix in ["https:", "http:", "wss:", "ws:"] {
            if urlString.hasPrefix(prefix) {
                urlString = String(urlString.suffix(urlString.count - prefix.count))
                break
            }
        }
        
        urlString = urlString.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        baseURL = URL(string: "https://\(urlString)/")!
        wsURL = URL(string: "wss://\(urlString)/")!
    }
}

// MARK: - Base URL Location

extension BaseURL {
    /// A server location.
    public enum ServerLocation: String {
        /// An US-East.
        case usEast = "https://chat-us-east-1.stream-io-api.com/"
        /// A proxy server.
        case proxyEast = "https://chat-proxy-us-east.stream-io-api.com/"
        /// A staging server.
        case staging = "https://chat-us-east-staging.stream-io-api.com/"
    }
}
