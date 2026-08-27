//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

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
        guard var rawJSONDictionary = rawJSON?.dictionaryValue else { return .dictionary([:]) }
        rawJSONDictionary.removeValue(forKey: CodingKeys.type.rawValue)
        if case let .dictionary(custom) = rawJSONDictionary.removeValue(forKey: CodingKeys.custom.rawValue) {
            rawJSONDictionary.merge(custom) { existing, _ in existing }
        }
        return .dictionary(rawJSONDictionary)
    }
}
