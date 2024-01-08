//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatAttachment: Codable, Hashable {
    public var title: String?
    
    public var titleLink: String?
    
    public var authorIcon: String?
    
    public var fields: [StreamChatField?]?
    
    public var giphy: StreamChatImages?
    
    public var originalWidth: Int?
    
    public var pretext: String?
    
    public var assetUrl: String?
    
    public var authorLink: String?
    
    public var footerIcon: String?
    
    public var ogScrapeUrl: String?
    
    public var text: String?
    
    public var thumbUrl: String?
    
    public var custom: [String: RawJSON]
    
    public var authorName: String?
    
    public var fallback: String?
    
    public var footer: String?
    
    public var imageUrl: String?
    
    public var type: String?
    
    public var actions: [StreamChatAction?]?
    
    public var color: String?
    
    public var originalHeight: Int?
    
    public init(title: String?, titleLink: String?, authorIcon: String?, fields: [StreamChatField?]?, giphy: StreamChatImages?, originalWidth: Int?, pretext: String?, assetUrl: String?, authorLink: String?, footerIcon: String?, ogScrapeUrl: String?, text: String?, thumbUrl: String?, custom: [String: RawJSON], authorName: String?, fallback: String?, footer: String?, imageUrl: String?, type: String?, actions: [StreamChatAction?]?, color: String?, originalHeight: Int?) {
        self.title = title
        
        self.titleLink = titleLink
        
        self.authorIcon = authorIcon
        
        self.fields = fields
        
        self.giphy = giphy
        
        self.originalWidth = originalWidth
        
        self.pretext = pretext
        
        self.assetUrl = assetUrl
        
        self.authorLink = authorLink
        
        self.footerIcon = footerIcon
        
        self.ogScrapeUrl = ogScrapeUrl
        
        self.text = text
        
        self.thumbUrl = thumbUrl
        
        self.custom = custom
        
        self.authorName = authorName
        
        self.fallback = fallback
        
        self.footer = footer
        
        self.imageUrl = imageUrl
        
        self.type = type
        
        self.actions = actions
        
        self.color = color
        
        self.originalHeight = originalHeight
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case title
        
        case titleLink = "title_link"
        
        case authorIcon = "author_icon"
        
        case fields
        
        case giphy
        
        case originalWidth = "original_width"
        
        case pretext
        
        case assetUrl = "asset_url"
        
        case authorLink = "author_link"
        
        case footerIcon = "footer_icon"
        
        case ogScrapeUrl = "og_scrape_url"
        
        case text
        
        case thumbUrl = "thumb_url"
        
        case custom = "Custom"
        
        case authorName = "author_name"
        
        case fallback
        
        case footer
        
        case imageUrl = "image_url"
        
        case type
        
        case actions
        
        case color
        
        case originalHeight = "original_height"
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(title, forKey: .title)
        
        try container.encode(titleLink, forKey: .titleLink)
        
        try container.encode(authorIcon, forKey: .authorIcon)
        
        try container.encode(fields, forKey: .fields)
        
        try container.encode(giphy, forKey: .giphy)
        
        try container.encode(originalWidth, forKey: .originalWidth)
        
        try container.encode(pretext, forKey: .pretext)
        
        try container.encode(assetUrl, forKey: .assetUrl)
        
        try container.encode(authorLink, forKey: .authorLink)
        
        try container.encode(footerIcon, forKey: .footerIcon)
        
        try container.encode(ogScrapeUrl, forKey: .ogScrapeUrl)
        
        try container.encode(text, forKey: .text)
        
        try container.encode(thumbUrl, forKey: .thumbUrl)
        
        try container.encode(custom, forKey: .custom)
        
        try container.encode(authorName, forKey: .authorName)
        
        try container.encode(fallback, forKey: .fallback)
        
        try container.encode(footer, forKey: .footer)
        
        try container.encode(imageUrl, forKey: .imageUrl)
        
        try container.encode(type, forKey: .type)
        
        try container.encode(actions, forKey: .actions)
        
        try container.encode(color, forKey: .color)
        
        try container.encode(originalHeight, forKey: .originalHeight)
    }
}
