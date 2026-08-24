//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class MessageModerationDetailsPayload: Sendable, Decodable {
    let action: String
    let blocklistMatched: String?
    let blocklistsMatched: [String]?
    let imageHarms: [String]?
    let originalText: String
    let platformCircumvented: Bool?
    let semanticFilterMatched: String?
    let textHarms: [String]?

    init(
        action: String,
        blocklistMatched: String? = nil,
        blocklistsMatched: [String]? = nil,
        imageHarms: [String]? = nil,
        originalText: String,
        platformCircumvented: Bool? = nil,
        semanticFilterMatched: String? = nil,
        textHarms: [String]? = nil
    ) {
        self.action = action
        self.blocklistMatched = blocklistMatched
        self.blocklistsMatched = blocklistsMatched
        self.imageHarms = imageHarms
        self.originalText = originalText
        self.platformCircumvented = platformCircumvented
        self.semanticFilterMatched = semanticFilterMatched
        self.textHarms = textHarms
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case action
        case blocklistMatched = "blocklist_matched"
        case blocklistsMatched = "blocklists_matched"
        case imageHarms = "image_harms"
        case originalText = "original_text"
        case platformCircumvented = "platform_circumvented"
        case semanticFilterMatched = "semantic_filter_matched"
        case textHarms = "text_harms"
    }
}
