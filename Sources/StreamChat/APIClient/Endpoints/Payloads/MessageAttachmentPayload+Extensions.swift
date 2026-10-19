//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

// Generated properties are slightly different from the previously hand-written ones.
extension MessageAttachmentPayload {
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

    /// Creates a request payload from an attachment payload in the flattened shape used by local storage.
    ///
    /// Standard fields stay at the top level, and every other field is moved to `custom`.
    static func fromStoredPayload(_ data: Data, type: AttachmentType) throws -> MessageAttachmentPayload {
        let payload = try JSONDecoder.default.decode(RawJSON.self, from: data)
        let reservedKeys = MessageAttachmentPayload.allKeys
        var nestedPayload: [String: RawJSON] = [:]
        var custom: [String: RawJSON] = [:]
        for (key, value) in payload.dictionaryValue ?? [:] {
            if key == StringCodingKey.custom.stringValue {
                if case let .dictionary(nested) = value {
                    custom.merge(nested) { _, new in new }
                }
            } else if reservedKeys.contains(key) {
                nestedPayload[key] = value
            } else {
                custom[key] = value
            }
        }
        nestedPayload[StringCodingKey.custom.stringValue] = .dictionary(custom)
        nestedPayload[StringCodingKey.type.stringValue] = .string(type.rawValue)
        let data = try JSONEncoder.default.encode(nestedPayload)
        return try JSONDecoder.default.decode(MessageAttachmentPayload.self, from: data)
    }
}
