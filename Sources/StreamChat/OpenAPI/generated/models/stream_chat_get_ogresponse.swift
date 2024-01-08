//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatGetOGResponse: Codable, Hashable {
    public var footerIcon: String?
    
    public var ogScrapeUrl: String?
    
    public var originalWidth: Int?
    
    public var pretext: String?
    
    public var thumbUrl: String?
    
    public var titleLink: String?
    
    public var actions: [StreamChatAction?]?
    
    public var authorLink: String?
    
    public var authorName: String?
    
    public var fallback: String?
    
    public var footer: String?
    
    public var text: String?
    
    public var custom: [String: RawJSON]
    
    public var color: String?
    
    public var fields: [StreamChatField?]?
    
    public var title: String?
    
    public var type: String?
    
    public var authorIcon: String?
    
    public var duration: String
    
    public var giphy: StreamChatImages?
    
    public var imageUrl: String?
    
    public var originalHeight: Int?
    
    public var assetUrl: String?
    
    public init(footerIcon: String?, ogScrapeUrl: String?, originalWidth: Int?, pretext: String?, thumbUrl: String?, titleLink: String?, actions: [StreamChatAction?]?, authorLink: String?, authorName: String?, fallback: String?, footer: String?, text: String?, custom: [String: RawJSON], color: String?, fields: [StreamChatField?]?, title: String?, type: String?, authorIcon: String?, duration: String, giphy: StreamChatImages?, imageUrl: String?, originalHeight: Int?, assetUrl: String?) {
        self.footerIcon = footerIcon
        
        self.ogScrapeUrl = ogScrapeUrl
        
        self.originalWidth = originalWidth
        
        self.pretext = pretext
        
        self.thumbUrl = thumbUrl
        
        self.titleLink = titleLink
        
        self.actions = actions
        
        self.authorLink = authorLink
        
        self.authorName = authorName
        
        self.fallback = fallback
        
        self.footer = footer
        
        self.text = text
        
        self.custom = custom
        
        self.color = color
        
        self.fields = fields
        
        self.title = title
        
        self.type = type
        
        self.authorIcon = authorIcon
        
        self.duration = duration
        
        self.giphy = giphy
        
        self.imageUrl = imageUrl
        
        self.originalHeight = originalHeight
        
        self.assetUrl = assetUrl
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case footerIcon = "footer_icon"
        
        case ogScrapeUrl = "og_scrape_url"
        
        case originalWidth = "original_width"
        
        case pretext
        
        case thumbUrl = "thumb_url"
        
        case titleLink = "title_link"
        
        case actions
        
        case authorLink = "author_link"
        
        case authorName = "author_name"
        
        case fallback
        
        case footer
        
        case text
        
        case custom = "Custom"
        
        case color
        
        case fields
        
        case title
        
        case type
        
        case authorIcon = "author_icon"
        
        case duration
        
        case giphy
        
        case imageUrl = "image_url"
        
        case originalHeight = "original_height"
        
        case assetUrl = "asset_url"
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(footerIcon, forKey: .footerIcon)
        
        try container.encode(ogScrapeUrl, forKey: .ogScrapeUrl)
        
        try container.encode(originalWidth, forKey: .originalWidth)
        
        try container.encode(pretext, forKey: .pretext)
        
        try container.encode(thumbUrl, forKey: .thumbUrl)
        
        try container.encode(titleLink, forKey: .titleLink)
        
        try container.encode(actions, forKey: .actions)
        
        try container.encode(authorLink, forKey: .authorLink)
        
        try container.encode(authorName, forKey: .authorName)
        
        try container.encode(fallback, forKey: .fallback)
        
        try container.encode(footer, forKey: .footer)
        
        try container.encode(text, forKey: .text)
        
        try container.encode(custom, forKey: .custom)
        
        try container.encode(color, forKey: .color)
        
        try container.encode(fields, forKey: .fields)
        
        try container.encode(title, forKey: .title)
        
        try container.encode(type, forKey: .type)
        
        try container.encode(authorIcon, forKey: .authorIcon)
        
        try container.encode(duration, forKey: .duration)
        
        try container.encode(giphy, forKey: .giphy)
        
        try container.encode(imageUrl, forKey: .imageUrl)
        
        try container.encode(originalHeight, forKey: .originalHeight)
        
        try container.encode(assetUrl, forKey: .assetUrl)
    }
}
