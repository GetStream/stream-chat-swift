//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatEvaluationRequest: Codable, Hashable {
    public var phraseListIds: [Int]?
    
    public var phrases: [String]?
    
    public var score: Double?
    
    public var type: String?
    
    public var matches: [StreamChatMatchRequest?]?
    
    public init(phraseListIds: [Int]?, phrases: [String]?, score: Double?, type: String?, matches: [StreamChatMatchRequest?]?) {
        self.phraseListIds = phraseListIds
        
        self.phrases = phrases
        
        self.score = score
        
        self.type = type
        
        self.matches = matches
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case phraseListIds = "phrase_list_ids"
        
        case phrases
        
        case score
        
        case type
        
        case matches
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(phraseListIds, forKey: .phraseListIds)
        
        try container.encode(phrases, forKey: .phrases)
        
        try container.encode(score, forKey: .score)
        
        try container.encode(type, forKey: .type)
        
        try container.encode(matches, forKey: .matches)
    }
}
