//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatSearchResponse: Codable, Hashable {
    public var results: [StreamChatSearchResult?]
    
    public var resultsWarning: StreamChatSearchWarning?
    
    public var duration: String
    
    public var next: String?
    
    public var previous: String?
    
    public init(results: [StreamChatSearchResult?], resultsWarning: StreamChatSearchWarning?, duration: String, next: String?, previous: String?) {
        self.results = results
        
        self.resultsWarning = resultsWarning
        
        self.duration = duration
        
        self.next = next
        
        self.previous = previous
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case results
        
        case resultsWarning = "results_warning"
        
        case duration
        
        case next
        
        case previous
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(results, forKey: .results)
        
        try container.encode(resultsWarning, forKey: .resultsWarning)
        
        try container.encode(duration, forKey: .duration)
        
        try container.encode(next, forKey: .next)
        
        try container.encode(previous, forKey: .previous)
    }
}
