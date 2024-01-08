//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatLabel: Codable, Hashable {
    public var name: String
    
    public var phraseListIds: [Int]?
    
    public init(name: String, phraseListIds: [Int]?) {
        self.name = name
        
        self.phraseListIds = phraseListIds
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case name
        
        case phraseListIds = "phrase_list_ids"
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(name, forKey: .name)
        
        try container.encode(phraseListIds, forKey: .phraseListIds)
    }
}
