//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatAttachment: Codable, Hashable {
    public var text: String?
    
    public var thumbUrl: String?
    
    public var actions: [StreamChatAction?]?
    
    public var fallback: String?
    
    public var imageUrl: String?
    
    public var originalHeight: Int?
    
    public var ogScrapeUrl: String?
    
    public var title: String?
    
    public var assetUrl: String?
    
    public var color: String?
    
    public var fields: [StreamChatField?]?
    
    public var giphy: StreamChatImages?
    
    public var originalWidth: Int?
    
    public var titleLink: String?
    
    public var authorIcon: String?
    
    public var authorLink: String?
    
    public var authorName: String?
    
    public var footer: String?
    
    public var custom: [String: RawJSON]?
    
    public var footerIcon: String?
    
    public var pretext: String?
    
    public var type: String?
    
    public init(text: String?, thumbUrl: String?, actions: [StreamChatAction?]?, fallback: String?, imageUrl: String?, originalHeight: Int?, ogScrapeUrl: String?, title: String?, assetUrl: String?, color: String?, fields: [StreamChatField?]?, giphy: StreamChatImages?, originalWidth: Int?, titleLink: String?, authorIcon: String?, authorLink: String?, authorName: String?, footer: String?, custom: [String: RawJSON], footerIcon: String?, pretext: String?, type: String?) {
        self.text = text
        
        self.thumbUrl = thumbUrl
        
        self.actions = actions
        
        self.fallback = fallback
        
        self.imageUrl = imageUrl
        
        self.originalHeight = originalHeight
        
        self.ogScrapeUrl = ogScrapeUrl
        
        self.title = title
        
        self.assetUrl = assetUrl
        
        self.color = color
        
        self.fields = fields
        
        self.giphy = giphy
        
        self.originalWidth = originalWidth
        
        self.titleLink = titleLink
        
        self.authorIcon = authorIcon
        
        self.authorLink = authorLink
        
        self.authorName = authorName
        
        self.footer = footer
        
        self.custom = custom
        
        self.footerIcon = footerIcon
        
        self.pretext = pretext
        
        self.type = type
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case text
        
        case thumbUrl = "thumb_url"
        
        case actions
        
        case fallback
        
        case imageUrl = "image_url"
        
        case originalHeight = "original_height"
        
        case ogScrapeUrl = "og_scrape_url"
        
        case title
        
        case assetUrl = "asset_url"
        
        case color
        
        case fields
        
        case giphy
        
        case originalWidth = "original_width"
        
        case titleLink = "title_link"
        
        case authorIcon = "author_icon"
        
        case authorLink = "author_link"
        
        case authorName = "author_name"
        
        case footer
        
        case custom = "Custom"
        
        case footerIcon = "footer_icon"
        
        case pretext
        
        case type
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(text, forKey: .text)
        
        try container.encode(thumbUrl, forKey: .thumbUrl)
        
        try container.encode(actions, forKey: .actions)
        
        try container.encode(fallback, forKey: .fallback)
        
        try container.encode(imageUrl, forKey: .imageUrl)
        
        try container.encode(originalHeight, forKey: .originalHeight)
        
        try container.encode(ogScrapeUrl, forKey: .ogScrapeUrl)
        
        try container.encode(title, forKey: .title)
        
        try container.encode(assetUrl, forKey: .assetUrl)
        
        try container.encode(color, forKey: .color)
        
        try container.encode(fields, forKey: .fields)
        
        try container.encode(giphy, forKey: .giphy)
        
        try container.encode(originalWidth, forKey: .originalWidth)
        
        try container.encode(titleLink, forKey: .titleLink)
        
        try container.encode(authorIcon, forKey: .authorIcon)
        
        try container.encode(authorLink, forKey: .authorLink)
        
        try container.encode(authorName, forKey: .authorName)
        
        try container.encode(footer, forKey: .footer)
        
        try container.encode(custom, forKey: .custom)
        
        try container.encode(footerIcon, forKey: .footerIcon)
        
        try container.encode(pretext, forKey: .pretext)
        
        try container.encode(type, forKey: .type)
    }
}
