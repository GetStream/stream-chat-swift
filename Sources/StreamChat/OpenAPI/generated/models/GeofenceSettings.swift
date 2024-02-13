//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct GeofenceSettings: Codable, Hashable {
    public var names: [String]

    public init(names: [String]) {
        self.names = names
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case names
    }
}
