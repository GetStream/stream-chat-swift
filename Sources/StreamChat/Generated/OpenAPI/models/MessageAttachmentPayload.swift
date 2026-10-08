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

    static let allKeys: Set<String> = [
        StringCodingKey.actions.stringValue,
        StringCodingKey.assetUrl.stringValue,
        StringCodingKey.authorIcon.stringValue,
        StringCodingKey.authorLink.stringValue,
        StringCodingKey.authorName.stringValue,
        StringCodingKey.color.stringValue,
        StringCodingKey.custom.stringValue,
        StringCodingKey.fallback.stringValue,
        StringCodingKey.fields.stringValue,
        StringCodingKey.footer.stringValue,
        StringCodingKey.footerIcon.stringValue,
        StringCodingKey.giphy.stringValue,
        StringCodingKey.imageUrl.stringValue,
        StringCodingKey.ogScrapeUrl.stringValue,
        StringCodingKey.originalHeight.stringValue,
        StringCodingKey.originalWidth.stringValue,
        StringCodingKey.pretext.stringValue,
        StringCodingKey.text.stringValue,
        StringCodingKey.thumbUrl.stringValue,
        StringCodingKey.title.stringValue,
        StringCodingKey.titleLink.stringValue,
        StringCodingKey.type.stringValue
    ]

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        actions = try container.decodeIfPresent([AttachmentActionPayload].self, forKey: .actions)
        assetUrl = try container.decodeIfPresent(String.self, forKey: .assetUrl)
        authorIcon = try container.decodeIfPresent(String.self, forKey: .authorIcon)
        authorLink = try container.decodeIfPresent(String.self, forKey: .authorLink)
        authorName = try container.decodeIfPresent(String.self, forKey: .authorName)
        color = try container.decodeIfPresent(String.self, forKey: .color)
        custom = try container.decodeIfPresent([String: RawJSON].self, forKey: .custom) ?? [:]
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
