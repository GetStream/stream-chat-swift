//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatAttachment: Codable, Hashable {
    public var assetUrl: String?
    
    public var authorIcon: String?
    
    public var authorLink: String?
    
    public var fallback: String?
    
    public var footer: String?
    
    public var originalHeight: Int?
    
    public var thumbUrl: String?
    
    public var custom: [String: RawJSON]
    
    public var fields: [StreamChatField?]?
    
    public var footerIcon: String?
    
    public var giphy: StreamChatImages?
    
    public var ogScrapeUrl: String?
    
    public var type: String?
    
    public var color: String?
    
    public var originalWidth: Int?
    
    public var pretext: String?
    
    public var titleLink: String?
    
    public var actions: [StreamChatAction?]?
    
    public var imageUrl: String?
    
    public var text: String?
    
    public var title: String?
    
    public var authorName: String?
    
    public init(assetUrl: String?, authorIcon: String?, authorLink: String?, fallback: String?, footer: String?, originalHeight: Int?, thumbUrl: String?, custom: [String: RawJSON], fields: [StreamChatField?]?, footerIcon: String?, giphy: StreamChatImages?, ogScrapeUrl: String?, type: String?, color: String?, originalWidth: Int?, pretext: String?, titleLink: String?, actions: [StreamChatAction?]?, imageUrl: String?, text: String?, title: String?, authorName: String?) {
        self.assetUrl = assetUrl
        
        self.authorIcon = authorIcon
        
        self.authorLink = authorLink
        
        self.fallback = fallback
        
        self.footer = footer
        
        self.originalHeight = originalHeight
        
        self.thumbUrl = thumbUrl
        
        self.custom = custom
        
        self.fields = fields
        
        self.footerIcon = footerIcon
        
        self.giphy = giphy
        
        self.ogScrapeUrl = ogScrapeUrl
        
        self.type = type
        
        self.color = color
        
        self.originalWidth = originalWidth
        
        self.pretext = pretext
        
        self.titleLink = titleLink
        
        self.actions = actions
        
        self.imageUrl = imageUrl
        
        self.text = text
        
        self.title = title
        
        self.authorName = authorName
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case assetUrl = "asset_url"
        
        case authorIcon = "author_icon"
        
        case authorLink = "author_link"
        
        case fallback
        
        case footer
        
        case originalHeight = "original_height"
        
        case thumbUrl = "thumb_url"
        
        case custom = "Custom"
        
        case fields
        
        case footerIcon = "footer_icon"
        
        case giphy
        
        case ogScrapeUrl = "og_scrape_url"
        
        case type
        
        case color
        
        case originalWidth = "original_width"
        
        case pretext
        
        case titleLink = "title_link"
        
        case actions
        
        case imageUrl = "image_url"
        
        case text
        
        case title
        
        case authorName = "author_name"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(assetUrl, forKey: .assetUrl)
        
        try container.encode(authorIcon, forKey: .authorIcon)
        
        try container.encode(authorLink, forKey: .authorLink)
        
        try container.encode(fallback, forKey: .fallback)
        
        try container.encode(footer, forKey: .footer)
        
        try container.encode(originalHeight, forKey: .originalHeight)
        
        try container.encode(thumbUrl, forKey: .thumbUrl)
        
        try container.encode(custom, forKey: .custom)
        
        try container.encode(fields, forKey: .fields)
        
        try container.encode(footerIcon, forKey: .footerIcon)
        
        try container.encode(giphy, forKey: .giphy)
        
        try container.encode(ogScrapeUrl, forKey: .ogScrapeUrl)
        
        try container.encode(type, forKey: .type)
        
        try container.encode(color, forKey: .color)
        
        try container.encode(originalWidth, forKey: .originalWidth)
        
        try container.encode(pretext, forKey: .pretext)
        
        try container.encode(titleLink, forKey: .titleLink)
        
        try container.encode(actions, forKey: .actions)
        
        try container.encode(imageUrl, forKey: .imageUrl)
        
        try container.encode(text, forKey: .text)
        
        try container.encode(title, forKey: .title)
        
        try container.encode(authorName, forKey: .authorName)
    }
}
