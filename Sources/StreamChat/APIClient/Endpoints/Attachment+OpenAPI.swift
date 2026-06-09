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
        let attachment: Attachment
        if let data = try? JSONEncoder.default.encode(payload),
           let decoded = try? JSONDecoder.default.decode(Attachment.self, from: data) {
            attachment = decoded
        } else {
            var dict = payload.dictionaryValue ?? [:]
            dict.removeValue(forKey: AttachmentCodingKeys.type.rawValue)
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
