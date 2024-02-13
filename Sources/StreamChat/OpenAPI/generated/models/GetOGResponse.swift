//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct GetOGResponse: Codable, Hashable {
    public var duration: String
    public var custom: [String: RawJSON]
    public var assetUrl: String? = nil
    public var authorIcon: String? = nil
    public var authorLink: String? = nil
    public var authorName: String? = nil
    public var color: String? = nil
    public var fallback: String? = nil
    public var footer: String? = nil
    public var footerIcon: String? = nil
    public var imageUrl: String? = nil
    public var ogScrapeUrl: String? = nil
    public var originalHeight: Int? = nil
    public var originalWidth: Int? = nil
    public var pretext: String? = nil
    public var text: String? = nil
    public var thumbUrl: String? = nil
    public var title: String? = nil
    public var titleLink: String? = nil
    public var type: String? = nil
    public var actions: [Action?]? = nil
    public var fields: [Field?]? = nil
    public var giphy: Images? = nil

    public init(duration: String, custom: [String: RawJSON], assetUrl: String? = nil, authorIcon: String? = nil, authorLink: String? = nil, authorName: String? = nil, color: String? = nil, fallback: String? = nil, footer: String? = nil, footerIcon: String? = nil, imageUrl: String? = nil, ogScrapeUrl: String? = nil, originalHeight: Int? = nil, originalWidth: Int? = nil, pretext: String? = nil, text: String? = nil, thumbUrl: String? = nil, title: String? = nil, titleLink: String? = nil, type: String? = nil, actions: [Action?]? = nil, fields: [Field?]? = nil, giphy: Images? = nil) {
        self.duration = duration
        self.custom = custom
        self.assetUrl = assetUrl
        self.authorIcon = authorIcon
        self.authorLink = authorLink
        self.authorName = authorName
        self.color = color
        self.fallback = fallback
        self.footer = footer
        self.footerIcon = footerIcon
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
        self.actions = actions
        self.fields = fields
        self.giphy = giphy
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case duration
        case custom
        case assetUrl = "asset_url"
        case authorIcon = "author_icon"
        case authorLink = "author_link"
        case authorName = "author_name"
        case color
        case fallback
        case footer
        case footerIcon = "footer_icon"
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
        case actions
        case fields
        case giphy
    }
}
