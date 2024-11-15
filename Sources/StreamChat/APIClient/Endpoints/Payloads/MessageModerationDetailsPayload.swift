//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

struct MessageModerationDetailsPayload: Decodable {
    let originalText: String
    let action: String
    let textHarms: [String]?
    let imageHarms: [String]?
    let blocklistMatched: [String]?
    let semanticFilterMatched: [String]?
    let platformCircumvented: Bool?

    init(
        originalText: String,
        action: String,
        textHarms: [String]?,
        imageHarms: [String]?,
        blocklistMatched: [String]?,
        semanticFilterMatched: [String]?,
        platformCircumvented: Bool?
    ) {
        self.originalText = originalText
        self.action = action
        self.textHarms = textHarms
        self.imageHarms = imageHarms
        self.blocklistMatched = blocklistMatched
        self.semanticFilterMatched = semanticFilterMatched
        self.platformCircumvented = platformCircumvented
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case originalText = "original_text"
        case action
        case textHarms = "text_harms"
        case imageHarms = "image_harms"
        case blocklistMatched = "blocklist_matched"
        case semanticFilterMatched = "semantic_filter_matched"
        case platformCircumvented = "platform_circumvented"
    }
}
