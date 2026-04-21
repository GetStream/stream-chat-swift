//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class ModerationV2Response: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    var action: String
    var blocklistMatched: String?
    var blocklistsMatched: [String]?
    var imageHarms: [String]?
    var originalText: String
    var platformCircumvented: Bool?
    var semanticFilterMatched: String?
    var textHarms: [String]?

    init(action: String, blocklistMatched: String? = nil, blocklistsMatched: [String]? = nil, imageHarms: [String]? = nil, originalText: String, platformCircumvented: Bool? = nil, semanticFilterMatched: String? = nil, textHarms: [String]? = nil) {
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

    static func == (lhs: ModerationV2Response, rhs: ModerationV2Response) -> Bool {
        lhs.action == rhs.action &&
            lhs.blocklistMatched == rhs.blocklistMatched &&
            lhs.blocklistsMatched == rhs.blocklistsMatched &&
            lhs.imageHarms == rhs.imageHarms &&
            lhs.originalText == rhs.originalText &&
            lhs.platformCircumvented == rhs.platformCircumvented &&
            lhs.semanticFilterMatched == rhs.semanticFilterMatched &&
            lhs.textHarms == rhs.textHarms
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(action)
        hasher.combine(blocklistMatched)
        hasher.combine(blocklistsMatched)
        hasher.combine(imageHarms)
        hasher.combine(originalText)
        hasher.combine(platformCircumvented)
        hasher.combine(semanticFilterMatched)
        hasher.combine(textHarms)
    }
}
