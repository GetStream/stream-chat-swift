//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatSearchResponse: Codable, Hashable {
    public var next: String?
    
    public var previous: String?
    
    public var results: [StreamChatSearchResult?]
    
    public var resultsWarning: StreamChatSearchWarning?
    
    public var duration: String
    
    public init(next: String?, previous: String?, results: [StreamChatSearchResult?], resultsWarning: StreamChatSearchWarning?, duration: String) {
        self.next = next
        
        self.previous = previous
        
        self.results = results
        
        self.resultsWarning = resultsWarning
        
        self.duration = duration
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case next
        
        case previous
        
        case results
        
        case resultsWarning = "results_warning"
        
        case duration
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(next, forKey: .next)
        
        try container.encode(previous, forKey: .previous)
        
        try container.encode(results, forKey: .results)
        
        try container.encode(resultsWarning, forKey: .resultsWarning)
        
        try container.encode(duration, forKey: .duration)
    }
}
