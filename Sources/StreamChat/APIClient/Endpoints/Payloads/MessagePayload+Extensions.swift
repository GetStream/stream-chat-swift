//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

// Generated properties are slightly different from the previously hand-written ones.
extension MessagePayload {
    var channelId: ChannelId? { try? ChannelId(cid: cid) }
    var campaignId: String? { custom["created_by_campaign_id"]?.stringValue }
    // Messages have no dedicated args field, it is stored as custom data.
    var args: String? { custom[MessagePayloadsCodingKeys.args.rawValue]?.stringValue }

    var translations: [TranslationLanguage: String]? {
        guard let i18n, !i18n.isEmpty else { return nil }
        let translatedSuffix = "_text"
        var translated = [TranslationLanguage: String]()
        for (key, value) in i18n where key.hasSuffix(translatedSuffix) {
            translated[TranslationLanguage(languageCode: String(key.dropLast(translatedSuffix.count)))] = value
        }
        return translated.isEmpty ? nil : translated
    }

    var originalLanguage: String? {
        i18n?["language"]
    }
}
