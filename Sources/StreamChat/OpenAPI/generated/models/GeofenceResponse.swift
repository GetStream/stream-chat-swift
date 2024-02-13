//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct GeofenceResponse: Codable, Hashable {
    public var name: String
    public var description: String? = nil
    public var type: String? = nil
    public var countryCodes: [String]? = nil

    public init(name: String, description: String? = nil, type: String? = nil, countryCodes: [String]? = nil) {
        self.name = name
        self.description = description
        self.type = type
        self.countryCodes = countryCodes
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case name
        case description
        case type
        case countryCodes = "country_codes"
    }
}
