//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatEvaluationResponse: Codable, Hashable {
    public var type: String
    
    public var matches: [StreamChatMatchResponse]?
    
    public var score: Double
    
    public init(type: String, matches: [StreamChatMatchResponse]?, score: Double) {
        self.type = type
        
        self.matches = matches
        
        self.score = score
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case type
        
        case matches
        
        case score
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(type, forKey: .type)
        
        try container.encode(matches, forKey: .matches)
        
        try container.encode(score, forKey: .score)
    }
}
