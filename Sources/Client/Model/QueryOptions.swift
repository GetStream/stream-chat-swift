//
//  QueryOptions.swift
//  StreamChatCore
//
//  Created by Alexey Bukhtin on 29/07/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import Foundation

/// Query options.
public struct QueryOptions: OptionSet, Encodable {
    private enum CodingKeys: String, CodingKey {
        case state
        case watch
        case presence
    }
    
    public let rawValue: Int
    
    /// A query will return a channel state, e.g. messages.
    public static let state = QueryOptions(rawValue: 1 << 0)
    /// Listen for a channel changes in real time, e.g. a new message evevnt.
    public static let watch = QueryOptions(rawValue: 1 << 1)
    /// Get updates when the user goes offline/online.
    public static let presence = QueryOptions(rawValue: 1 << 2)
    /// Includes all query options: state, watch and presence.
    public static let all: QueryOptions = [.state, .watch, .presence]
    
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        if contains(.state) {
            try container.encode(true, forKey: .state)
        }
        
        if contains(.watch) {
            try container.encode(true, forKey: .watch)
        }
        
        if contains(.presence) {
            try container.encode(true, forKey: .presence)
        }
    }
}
