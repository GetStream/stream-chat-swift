//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatSearchResponse: Codable, Hashable {
    public var duration: String
    
    public var next: String?
    
    public var previous: String?
    
    public var results: [StreamChatSearchResult?]
    
    public var resultsWarning: StreamChatSearchWarning?
    
    public init(duration: String, next: String?, previous: String?, results: [StreamChatSearchResult?], resultsWarning: StreamChatSearchWarning?) {
        self.duration = duration
        
        self.next = next
        
        self.previous = previous
        
        self.results = results
        
        self.resultsWarning = resultsWarning
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case duration
        
        case next
        
        case previous
        
        case results
        
        case resultsWarning = "results_warning"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(duration, forKey: .duration)
        
        try container.encode(next, forKey: .next)
        
        try container.encode(previous, forKey: .previous)
        
        try container.encode(results, forKey: .results)
        
        try container.encode(resultsWarning, forKey: .resultsWarning)
    }
}
