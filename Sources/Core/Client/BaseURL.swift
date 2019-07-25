//
//  BaseURL.swift
//  StreamChatCore
//
//  Created by Alexey Bukhtin on 01/04/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import Foundation

/// A base URL for the `Client`.
public struct BaseURL {
    static let placeholderURL = URL(string: "https://getstream.io")!
    
    private let urlString: String
    
    /// Create a base URL.
    ///
    /// - Parameter location: a server location.
    public init(location: Location = .usEast) {
        urlString = "//chat\(location.rawValue.isEmpty ? "" : "-")\(location.rawValue).stream-io-api.com/"
    }
    
    func url(_ scheme: ClientScheme) -> URL {
        return URL(string: scheme.rawValue.appending(":").appending(urlString)) ?? URL(fileURLWithPath: "/")
    }
}

extension BaseURL {
    /// A server location.
    public enum Location: String {
        /// An US-East.
        case usEast = "us-east-1"
    }
}

extension BaseURL: CustomStringConvertible {
    public var description: String {
        return urlString
    }
}

/// An url scheme.
enum ClientScheme: String {
    case https = "https"
    case webSocket = "wss"
}
