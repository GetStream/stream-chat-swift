//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct Thresholds: Codable, Hashable {
    public var explicit: LabelThresholds? = nil
    public var spam: LabelThresholds? = nil
    public var toxic: LabelThresholds? = nil

    public init(explicit: LabelThresholds? = nil, spam: LabelThresholds? = nil, toxic: LabelThresholds? = nil) {
        self.explicit = explicit
        self.spam = spam
        self.toxic = toxic
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case explicit
        case spam
        case toxic
    }
}
