//
//  BaseURL.swift
//  GetStreamChat
//
//  Created by Alexey Bukhtin on 01/04/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import Foundation

public struct BaseURL {
    static let placeholderURL = URL(string: "https://getstream.io")!
    
    private let urlString: String
    
    public init(location: Location = .usEast) {
        urlString = "//chat\(location.rawValue.isEmpty ? "" : "-")\(location.rawValue).stream-io-api.com/"
    }
    
    func url(_ scheme: ClientScheme) -> URL? {
        return URL(string: scheme.rawValue.appending(":").appending(urlString))
    }
}

extension BaseURL {
    public enum Location: String {
        case usEast = "us-east-1"
    }
}

extension BaseURL: CustomStringConvertible {
    public var description: String {
        return urlString
    }
}

public enum ClientScheme: String {
    case https = "https"
    case webSocket = "wss"
}
