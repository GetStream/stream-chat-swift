//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

// Generated properties are slightly different from the previously hand-written ones.
extension MessageAttachmentPayload {
    static let allKeys: Set<String> = [
        StringCodingKey.actions.stringValue,
        StringCodingKey.assetUrl.stringValue,
        StringCodingKey.authorIcon.stringValue,
        StringCodingKey.authorLink.stringValue,
        StringCodingKey.authorName.stringValue,
        StringCodingKey.color.stringValue,
        StringCodingKey.custom.stringValue,
        StringCodingKey.fallback.stringValue,
        StringCodingKey.fields.stringValue,
        StringCodingKey.footer.stringValue,
        StringCodingKey.footerIcon.stringValue,
        StringCodingKey.giphy.stringValue,
        StringCodingKey.imageUrl.stringValue,
        StringCodingKey.ogScrapeUrl.stringValue,
        StringCodingKey.originalHeight.stringValue,
        StringCodingKey.originalWidth.stringValue,
        StringCodingKey.pretext.stringValue,
        StringCodingKey.text.stringValue,
        StringCodingKey.thumbUrl.stringValue,
        StringCodingKey.title.stringValue,
        StringCodingKey.titleLink.stringValue,
        StringCodingKey.type.stringValue
    ]

    /// An attachment type derived from the raw payload.
    var attachmentType: AttachmentType {
        if ogScrapeUrl != nil {
            return .linkPreview
        }
        return type.map(AttachmentType.init(rawValue:)) ?? .unknown
    }

    /// A raw attachment payload in the flattened shape used by local storage, where
    /// standard and custom fields share the top level and `type` is stripped.
    var payload: RawJSON {
        guard var rawJSONDictionary = rawJSON?.dictionaryValue else { return .dictionary([:]) }
        rawJSONDictionary.removeValue(forKey: StringCodingKey.type.stringValue)
        if case let .dictionary(custom) = rawJSONDictionary.removeValue(forKey: StringCodingKey.custom.stringValue) {
            rawJSONDictionary.merge(custom) { existing, _ in existing }
        }
        return .dictionary(rawJSONDictionary)
    }
}
