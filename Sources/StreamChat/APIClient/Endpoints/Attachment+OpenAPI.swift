//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

extension Attachment {
    var attachmentType: AttachmentType {
        if ogScrapeUrl != nil {
            return .linkPreview
        }
        return type.map(AttachmentType.init(rawValue:)) ?? .unknown
    }

    static func make(type: AttachmentType, payload: RawJSON) -> Attachment {
        var dict = payload.dictionaryValue ?? [:]
        dict.removeValue(forKey: CodingKeys.type.rawValue)
        // Locally stored attachment data uses the flattened shape where standard and
        // custom fields share the top level, while the generated model expects custom
        // fields nested under `custom`. Partition the keys before decoding so that
        // standard fields stay top-level on the wire.
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
        let attachment: Attachment
        if let data = try? JSONEncoder.default.encode(RawJSON.dictionary(known)),
           let decoded = try? JSONDecoder.default.decode(Attachment.self, from: data) {
            attachment = decoded
        } else {
            attachment = Attachment(custom: dict)
        }
        attachment.type = type.rawValue
        return attachment
    }

    var payload: RawJSON {
        guard
            let data = try? JSONEncoder.default.encode(self),
            case var .dictionary(dict) = (try? JSONDecoder.default.decode(RawJSON.self, from: data)) ?? .dictionary([:])
        else {
            return .dictionary([:])
        }
        dict.removeValue(forKey: AttachmentCodingKeys.type.rawValue)
        if case let .dictionary(customDict) = dict["custom"] ?? .dictionary([:]) {
            for (key, value) in customDict {
                dict[key] = value
            }
        }
        dict.removeValue(forKey: "custom")
        return .dictionary(dict)
    }
}
