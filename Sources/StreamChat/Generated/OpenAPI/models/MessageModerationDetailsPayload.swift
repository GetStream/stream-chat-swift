//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class MessageModerationDetailsPayload: Sendable, Decodable {
    let action: String
    let blocklistsMatched: [String]?
    let imageHarms: [String]?
    let originalText: String
    let platformCircumvented: Bool?
    let semanticFilterMatched: String?
    let textHarms: [String]?

    init(
        action: String,
        blocklistsMatched: [String]? = nil,
        imageHarms: [String]? = nil,
        originalText: String,
        platformCircumvented: Bool? = nil,
        semanticFilterMatched: String? = nil,
        textHarms: [String]? = nil
    ) {
        self.action = action
        self.blocklistsMatched = blocklistsMatched
        self.imageHarms = imageHarms
        self.originalText = originalText
        self.platformCircumvented = platformCircumvented
        self.semanticFilterMatched = semanticFilterMatched
        self.textHarms = textHarms
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.action = try container.decode(String.self, forKey: .action)
        self.blocklistsMatched = try container.decodeIfPresent(
            [String].self,
            forKey: .blocklistsMatched
        )
        self.imageHarms = try container.decodeIfPresent([String].self, forKey: .imageHarms)
        self.originalText = try container.decode(String.self, forKey: .originalText)
        self.platformCircumvented = try container.decodeIfPresent(
            Bool.self,
            forKey: .platformCircumvented
        )
        self.semanticFilterMatched = try container.decodeIfPresent(
            String.self,
            forKey: .semanticFilterMatched
        )
        self.textHarms = try container.decodeIfPresent([String].self, forKey: .textHarms)
    }
}
