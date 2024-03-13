//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct Label: Codable, Hashable {
    public var name: String
    public var harmLabels: [String]? = nil
    public var phraseListIds: [Int]? = nil

    public init(name: String, harmLabels: [String]? = nil, phraseListIds: [Int]? = nil) {
        self.name = name
        self.harmLabels = harmLabels
        self.phraseListIds = phraseListIds
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case name
        case harmLabels = "harm_labels"
        case phraseListIds = "phrase_list_ids"
    }
}
