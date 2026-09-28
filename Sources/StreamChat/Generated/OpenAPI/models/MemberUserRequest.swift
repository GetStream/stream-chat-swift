//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class MemberUserRequest: Sendable, Codable, JSONEncodable {
    let custom: [String: RawJSON]?
    let id: String
    let image: String?
    let invisible: Bool?
    let language: String?
    let name: String?
    let privacySettings: UserPrivacySettings?

    init(
        custom: [String: RawJSON]? = nil,
        id: String,
        image: String? = nil,
        invisible: Bool? = nil,
        language: String? = nil,
        name: String? = nil,
        privacySettings: UserPrivacySettings? = nil
    ) {
        self.custom = custom
        self.id = id
        self.image = image
        self.invisible = invisible
        self.language = language
        self.name = name
        self.privacySettings = privacySettings
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case custom
        case id
        case image
        case invisible
        case language
        case name
        case privacySettings = "privacy_settings"
    }
}
