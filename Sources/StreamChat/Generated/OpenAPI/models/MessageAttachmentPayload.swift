//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// An attachment is a message object that represents a file uploaded by a user.
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

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.actions = try container.decodeArrayIfPresentIgnoringFailures(
            [AttachmentActionPayload].self,
            forKey: .actions
        )
        self.assetUrl = try container.decodeIfPresent(String.self, forKey: .assetUrl)
        self.authorIcon = try container.decodeIfPresent(String.self, forKey: .authorIcon)
        self.authorLink = try container.decodeIfPresent(String.self, forKey: .authorLink)
        self.authorName = try container.decodeIfPresent(String.self, forKey: .authorName)
        self.color = try container.decodeIfPresent(String.self, forKey: .color)
        self.custom = try container.decodeIfPresent([String: RawJSON].self, forKey: .custom) ?? [:]
        self.fallback = try container.decodeIfPresent(String.self, forKey: .fallback)
        self.fields = try container.decodeArrayIfPresentIgnoringFailures(
            [AttachmentFieldPayload].self,
            forKey: .fields
        )
        self.footer = try container.decodeIfPresent(String.self, forKey: .footer)
        self.footerIcon = try container.decodeIfPresent(String.self, forKey: .footerIcon)
        self.giphy = try container.decodeIfPresent(GiphyImages.self, forKey: .giphy)
        self.imageUrl = try container.decodeIfPresent(String.self, forKey: .imageUrl)
        self.ogScrapeUrl = try container.decodeIfPresent(String.self, forKey: .ogScrapeUrl)
        self.originalHeight = try container.decodeIfPresent(Int.self, forKey: .originalHeight)
        self.originalWidth = try container.decodeIfPresent(Int.self, forKey: .originalWidth)
        self.pretext = try container.decodeIfPresent(String.self, forKey: .pretext)
        self.text = try container.decodeIfPresent(String.self, forKey: .text)
        self.thumbUrl = try container.decodeIfPresent(String.self, forKey: .thumbUrl)
        self.title = try container.decodeIfPresent(String.self, forKey: .title)
        self.titleLink = try container.decodeIfPresent(String.self, forKey: .titleLink)
        self.type = try container.decodeIfPresent(String.self, forKey: .type)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: StringCodingKey.self)
        try container.encodeIfPresent(actions, forKey: .actions)
        try container.encodeIfPresent(assetUrl, forKey: .assetUrl)
        try container.encodeIfPresent(authorIcon, forKey: .authorIcon)
        try container.encodeIfPresent(authorLink, forKey: .authorLink)
        try container.encodeIfPresent(authorName, forKey: .authorName)
        try container.encodeIfPresent(color, forKey: .color)
        try container.encode(custom, forKey: .custom)
        try container.encodeIfPresent(fallback, forKey: .fallback)
        try container.encodeIfPresent(fields, forKey: .fields)
        try container.encodeIfPresent(footer, forKey: .footer)
        try container.encodeIfPresent(footerIcon, forKey: .footerIcon)
        try container.encodeIfPresent(giphy, forKey: .giphy)
        try container.encodeIfPresent(imageUrl, forKey: .imageUrl)
        try container.encodeIfPresent(ogScrapeUrl, forKey: .ogScrapeUrl)
        try container.encodeIfPresent(originalHeight, forKey: .originalHeight)
        try container.encodeIfPresent(originalWidth, forKey: .originalWidth)
        try container.encodeIfPresent(pretext, forKey: .pretext)
        try container.encodeIfPresent(text, forKey: .text)
        try container.encodeIfPresent(thumbUrl, forKey: .thumbUrl)
        try container.encodeIfPresent(title, forKey: .title)
        try container.encodeIfPresent(titleLink, forKey: .titleLink)
        try container.encodeIfPresent(type, forKey: .type)
    }
}
