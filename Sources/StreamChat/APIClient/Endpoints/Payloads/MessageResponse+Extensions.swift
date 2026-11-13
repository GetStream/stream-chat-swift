//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

// Generated properties are slightly different from the previously hand-written ones.
extension MessageResponse {
    // Messages have no dedicated args field, it is stored as custom data.
    static let argsKey = "args"

    var campaignId: String? { custom["created_by_campaign_id"]?.stringValue }
    var args: String? { custom[Self.argsKey]?.stringValue }

    var translations: [String: String]? {
        I18n.translations(from: i18n)
    }

    var originalLanguage: String? {
        I18n.originalLanguage(from: i18n)
    }
}
