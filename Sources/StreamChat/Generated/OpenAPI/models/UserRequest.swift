//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class UserRequest: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    /// Custom user data
    var custom: [String: RawJSON]?
    /// User ID
    var id: String
    /// User's profile image URL
    var image: String?
    var invisible: Bool?
    var language: String?
    /// Optional name of user
    var name: String?
    var privacySettings: PrivacySettingsResponse?

    init(custom: [String: RawJSON]? = nil, id: String, image: String? = nil, invisible: Bool? = nil, language: String? = nil, name: String? = nil, privacySettings: PrivacySettingsResponse? = nil) {
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

    static func == (lhs: UserRequest, rhs: UserRequest) -> Bool {
        lhs.custom == rhs.custom &&
            lhs.id == rhs.id &&
            lhs.image == rhs.image &&
            lhs.invisible == rhs.invisible &&
            lhs.language == rhs.language &&
            lhs.name == rhs.name &&
            lhs.privacySettings == rhs.privacySettings
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(custom)
        hasher.combine(id)
        hasher.combine(image)
        hasher.combine(invisible)
        hasher.combine(language)
        hasher.combine(name)
        hasher.combine(privacySettings)
    }
}
