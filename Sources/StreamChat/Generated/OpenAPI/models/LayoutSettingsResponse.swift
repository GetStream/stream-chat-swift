//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class LayoutSettingsResponse: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    var detectOrientation: Bool?
    var externalAppUrl: String
    var externalCssUrl: String
    var name: String
    var options: [String: RawJSON]?

    init(detectOrientation: Bool? = nil, externalAppUrl: String, externalCssUrl: String, name: String, options: [String: RawJSON]? = nil) {
        self.detectOrientation = detectOrientation
        self.externalAppUrl = externalAppUrl
        self.externalCssUrl = externalCssUrl
        self.name = name
        self.options = options
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case detectOrientation = "detect_orientation"
        case externalAppUrl = "external_app_url"
        case externalCssUrl = "external_css_url"
        case name
        case options
    }

    static func == (lhs: LayoutSettingsResponse, rhs: LayoutSettingsResponse) -> Bool {
        lhs.detectOrientation == rhs.detectOrientation &&
            lhs.externalAppUrl == rhs.externalAppUrl &&
            lhs.externalCssUrl == rhs.externalCssUrl &&
            lhs.name == rhs.name &&
            lhs.options == rhs.options
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(detectOrientation)
        hasher.combine(externalAppUrl)
        hasher.combine(externalCssUrl)
        hasher.combine(name)
        hasher.combine(options)
    }
}
