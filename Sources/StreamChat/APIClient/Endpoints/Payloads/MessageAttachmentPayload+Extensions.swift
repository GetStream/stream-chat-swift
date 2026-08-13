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

    /// A raw attachment payload in the flattened shape used by local storage and v1
    /// endpoints, where standard and custom fields share the top level and `type` is
    /// stripped.
    var payload: RawJSON {
        guard
            let data = try? JSONEncoder.default.encode(self),
            case var .dictionary(dict) = try? JSONDecoder.default.decode(RawJSON.self, from: data)
        else {
            return .dictionary(custom)
        }

        dict.removeValue(forKey: CodingKeys.type.rawValue)
        if case let .dictionary(custom) = dict.removeValue(forKey: CodingKeys.custom.rawValue) {
            dict.merge(custom) { standard, _ in standard }
        }
        return .dictionary(dict)
    }

    /// Locally stored attachment data uses the flattened shape where standard and custom
    /// fields share the top level, while the generated model expects custom fields nested
    /// under `custom`. Partitions the keys so that standard fields stay top-level.
    static func makeRawJSON(type: AttachmentType, payload: RawJSON) -> RawJSON {
        var dict = payload.dictionaryValue ?? [:]
        dict.removeValue(forKey: CodingKeys.type.rawValue)
        let knownKeys = Set(CodingKeys.allCases.map(\.rawValue))
        var known: [String: RawJSON] = [:]
        var custom: [String: RawJSON] = [:]
        for (key, value) in dict {
            if key == CodingKeys.custom.rawValue {
                if case let .dictionary(nested) = value {
                    custom.merge(nested) { flattened, _ in flattened }
                }
            } else if knownKeys.contains(key) {
                known[key] = value
            } else {
                custom[key] = value
            }
        }
        known[CodingKeys.custom.rawValue] = .dictionary(custom)
        known[CodingKeys.type.rawValue] = .string(type.rawValue)
        return .dictionary(known)
    }

    /// The partial message update parses the `set` map with flattened logic, therefore
    /// custom fields must share the top level with the standard ones.
    static func makeFlattenedRawJSON(type: AttachmentType, payload: RawJSON) -> RawJSON {
        var dict = payload.dictionaryValue ?? [:]
        if case let .dictionary(custom) = dict.removeValue(forKey: CodingKeys.custom.rawValue) {
            dict.merge(custom) { flattened, _ in flattened }
        }
        dict[CodingKeys.type.rawValue] = .string(type.rawValue)
        return .dictionary(dict)
    }

    static func make(type: AttachmentType, payload: RawJSON) -> MessageAttachmentPayload {
        let nested = makeRawJSON(type: type, payload: payload)
        if let data = try? JSONEncoder.default.encode(nested),
           let decoded = try? JSONDecoder.default.decode(MessageAttachmentPayload.self, from: data) {
            return decoded
        }
        let flattened = payload.dictionaryValue ?? [:]
        return MessageAttachmentPayload(
            custom: flattened.removingValues(forKeys: [CodingKeys.type.rawValue]),
            type: type.rawValue
        )
    }
}
