//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct MessageActionRequest: Codable, Hashable {
    public var formData: [String: String]
    public var iD: String? = nil

    public init(formData: [String: String], iD: String? = nil) {
        self.formData = formData
        self.iD = iD
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case formData = "form_data"
        case iD = "ID"
    }
}
