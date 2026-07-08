//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class GetOGResponse: Sendable, Codable, JSONEncodable {
    let actions: [AttachmentActionPayload]?
    /// URL of detected video or audio
    let assetUrl: String?
    let authorIcon: String?
    /// og:site
    let authorLink: String?
    /// og:site_name
    let authorName: String?
    let color: String?
    let custom: [String: RawJSON]
    let duration: String
    let fallback: String?
    let fields: [AttachmentFieldPayload]?
    let footer: String?
    let footerIcon: String?
    let giphy: GiphyImages?
    /// URL of detected image
    let imageUrl: String?
    /// extracted url from the text
    let ogScrapeUrl: String?
    let originalHeight: Int?
    let originalWidth: Int?
    let pretext: String?
    /// og:description
    let text: String?
    /// URL of detected thumb image
    let thumbUrl: String?
    /// og:title
    let title: String?
    /// og:url
    let titleLink: String?
    /// Attachment type, could be empty, image, audio or video
    let type: String?

    init(actions: [AttachmentActionPayload]? = nil, assetUrl: String? = nil, authorIcon: String? = nil, authorLink: String? = nil, authorName: String? = nil, color: String? = nil, custom: [String: RawJSON], duration: String, fallback: String? = nil, fields: [AttachmentFieldPayload]? = nil, footer: String? = nil, footerIcon: String? = nil, giphy: GiphyImages? = nil, imageUrl: String? = nil, ogScrapeUrl: String? = nil, originalHeight: Int? = nil, originalWidth: Int? = nil, pretext: String? = nil, text: String? = nil, thumbUrl: String? = nil, title: String? = nil, titleLink: String? = nil, type: String? = nil) {
        self.actions = actions
        self.assetUrl = assetUrl
        self.authorIcon = authorIcon
        self.authorLink = authorLink
        self.authorName = authorName
        self.color = color
        self.custom = custom
        self.duration = duration
        self.fallback = fallback
        self.fields = fields
        self.footer = footer
        self.footerIcon = footerIcon
        self.giphy = giphy
        self.imageUrl = imageUrl
        self.ogScrapeUrl = ogScrapeUrl
        self.originalHeight = originalHeight
        self.originalWidth = originalWidth
        self.pretext = pretext
        self.text = text
        self.thumbUrl = thumbUrl
        self.title = title
        self.titleLink = titleLink
        self.type = type
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case actions
        case assetUrl = "asset_url"
        case authorIcon = "author_icon"
        case authorLink = "author_link"
        case authorName = "author_name"
        case color
        case custom
        case duration
        case fallback
        case fields
        case footer
        case footerIcon = "footer_icon"
        case giphy
        case imageUrl = "image_url"
        case ogScrapeUrl = "og_scrape_url"
        case originalHeight = "original_height"
        case originalWidth = "original_width"
        case pretext
        case text
        case thumbUrl = "thumb_url"
        case title
        case titleLink = "title_link"
        case type
    }
}

extension GetOGResponse: Hashable {
    static func == (lhs: GetOGResponse, rhs: GetOGResponse) -> Bool {
        lhs.actions == rhs.actions &&
            lhs.assetUrl == rhs.assetUrl &&
            lhs.authorIcon == rhs.authorIcon &&
            lhs.authorLink == rhs.authorLink &&
            lhs.authorName == rhs.authorName &&
            lhs.color == rhs.color &&
            lhs.custom == rhs.custom &&
            lhs.duration == rhs.duration &&
            lhs.fallback == rhs.fallback &&
            lhs.fields == rhs.fields &&
            lhs.footer == rhs.footer &&
            lhs.footerIcon == rhs.footerIcon &&
            lhs.giphy == rhs.giphy &&
            lhs.imageUrl == rhs.imageUrl &&
            lhs.ogScrapeUrl == rhs.ogScrapeUrl &&
            lhs.originalHeight == rhs.originalHeight &&
            lhs.originalWidth == rhs.originalWidth &&
            lhs.pretext == rhs.pretext &&
            lhs.text == rhs.text &&
            lhs.thumbUrl == rhs.thumbUrl &&
            lhs.title == rhs.title &&
            lhs.titleLink == rhs.titleLink &&
            lhs.type == rhs.type
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(actions)
        hasher.combine(assetUrl)
        hasher.combine(authorIcon)
        hasher.combine(authorLink)
        hasher.combine(authorName)
        hasher.combine(color)
        hasher.combine(custom)
        hasher.combine(duration)
        hasher.combine(fallback)
        hasher.combine(fields)
        hasher.combine(footer)
        hasher.combine(footerIcon)
        hasher.combine(giphy)
        hasher.combine(imageUrl)
        hasher.combine(ogScrapeUrl)
        hasher.combine(originalHeight)
        hasher.combine(originalWidth)
        hasher.combine(pretext)
        hasher.combine(text)
        hasher.combine(thumbUrl)
        hasher.combine(title)
        hasher.combine(titleLink)
        hasher.combine(type)
    }
}
