//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation

/// Query options.
struct QueryOptions: OptionSet, Encodable {
    private enum CodingKeys: String, CodingKey {
        case state
        case watch
        case presence
    }
    
    let rawValue: Int
    
    /// A query will return a channel state, e.g. messages.
    static let state = QueryOptions(rawValue: 1 << 0)
    
    /// Listen for a channel changes in real time, e.g. a new message event.
    static let watch = QueryOptions(rawValue: 1 << 1)
    
    /// Get updates when the user goes offline/online.
    static let presence = QueryOptions(rawValue: 1 << 2)
    
    /// Includes all query options: state, watch and presence.
    static let all: QueryOptions = [.state, .watch, .presence]
    
    init(rawValue: Int) {
        self.rawValue = rawValue
    }
    
    func encode(to encoder: Encoder) throws {
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
