//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct Label: Codable, Hashable {
    public var name: String
    public var phraseListIds: [Int]? = nil

    public init(name: String, phraseListIds: [Int]? = nil) {
        self.name = name
        self.phraseListIds = phraseListIds
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case name
        case phraseListIds = "phrase_list_ids"
    }
}
