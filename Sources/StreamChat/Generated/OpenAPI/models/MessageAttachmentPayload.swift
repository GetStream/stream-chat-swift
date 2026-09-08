//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class MessageAttachmentPayload: Sendable, Codable, JSONEncodable {
    let actions: [AttachmentActionPayload]?
    let assetUrl: String?
    let authorIcon: String?
    let authorLink: String?
    let authorName: String?
    let color: String?
    let custom: [String: RawJSON]
    let fallback: String?
    let fields: [AttachmentFieldPayload]?
    let footer: String?
    let footerIcon: String?
    let giphy: GiphyImages?
    let imageUrl: String?
    let ogScrapeUrl: String?
    let originalHeight: Int?
    let originalWidth: Int?
    let pretext: String?
    let text: String?
    let thumbUrl: String?
    let title: String?
    let titleLink: String?
    /// MessageAttachmentPayload type (e.g. image, video, url)
    let type: String?

    init(
        actions: [AttachmentActionPayload]? = nil,
        assetUrl: String? = nil,
        authorIcon: String? = nil,
        authorLink: String? = nil,
        authorName: String? = nil,
        color: String? = nil,
        custom: [String: RawJSON],
        fallback: String? = nil,
        fields: [AttachmentFieldPayload]? = nil,
        footer: String? = nil,
        footerIcon: String? = nil,
        giphy: GiphyImages? = nil,
        imageUrl: String? = nil,
        ogScrapeUrl: String? = nil,
        originalHeight: Int? = nil,
        originalWidth: Int? = nil,
        pretext: String? = nil,
        text: String? = nil,
        thumbUrl: String? = nil,
        title: String? = nil,
        titleLink: String? = nil,
        type: String? = nil
    ) {
        self.actions = actions
        self.assetUrl = assetUrl
        self.authorIcon = authorIcon
        self.authorLink = authorLink
        self.authorName = authorName
        self.color = color
        self.custom = custom
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

    class var customExcludedKeys: Set<String> {
        Set(CodingKeys.allCases.map(\.rawValue))
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        actions = try container.decodeIfPresent([AttachmentActionPayload].self, forKey: .actions)
        assetUrl = try container.decodeIfPresent(String.self, forKey: .assetUrl)
        authorIcon = try container.decodeIfPresent(String.self, forKey: .authorIcon)
        authorLink = try container.decodeIfPresent(String.self, forKey: .authorLink)
        authorName = try container.decodeIfPresent(String.self, forKey: .authorName)
        color = try container.decodeIfPresent(String.self, forKey: .color)
        if let decoded = try container.decodeIfPresent([String: RawJSON].self, forKey: .custom) {
            custom = decoded
        } else {
            var flattened = try [String: RawJSON](from: decoder)
            flattened.removeValues(forKeys: Array(Self.customExcludedKeys))
            custom = flattened
        }
        fallback = try container.decodeIfPresent(String.self, forKey: .fallback)
        fields = try container.decodeIfPresent([AttachmentFieldPayload].self, forKey: .fields)
        footer = try container.decodeIfPresent(String.self, forKey: .footer)
        footerIcon = try container.decodeIfPresent(String.self, forKey: .footerIcon)
        giphy = try container.decodeIfPresent(GiphyImages.self, forKey: .giphy)
        imageUrl = try container.decodeIfPresent(String.self, forKey: .imageUrl)
        ogScrapeUrl = try container.decodeIfPresent(String.self, forKey: .ogScrapeUrl)
        originalHeight = try container.decodeIfPresent(Int.self, forKey: .originalHeight)
        originalWidth = try container.decodeIfPresent(Int.self, forKey: .originalWidth)
        pretext = try container.decodeIfPresent(String.self, forKey: .pretext)
        text = try container.decodeIfPresent(String.self, forKey: .text)
        thumbUrl = try container.decodeIfPresent(String.self, forKey: .thumbUrl)
        title = try container.decodeIfPresent(String.self, forKey: .title)
        titleLink = try container.decodeIfPresent(String.self, forKey: .titleLink)
        type = try container.decodeIfPresent(String.self, forKey: .type)
    }
}
