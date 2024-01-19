//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatGetOGResponse: Codable, Hashable {
    public var color: String?
    
    public var duration: String
    
    public var fields: [StreamChatField?]?
    
    public var ogScrapeUrl: String?
    
    public var custom: [String: RawJSON]
    
    public var assetUrl: String?
    
    public var type: String?
    
    public var authorIcon: String?
    
    public var footer: String?
    
    public var originalHeight: Int?
    
    public var originalWidth: Int?
    
    public var pretext: String?
    
    public var text: String?
    
    public var imageUrl: String?
    
    public var thumbUrl: String?
    
    public var actions: [StreamChatAction?]?
    
    public var authorLink: String?
    
    public var authorName: String?
    
    public var fallback: String?
    
    public var footerIcon: String?
    
    public var giphy: StreamChatImages?
    
    public var title: String?
    
    public var titleLink: String?
    
    public init(color: String?, duration: String, fields: [StreamChatField?]?, ogScrapeUrl: String?, custom: [String: RawJSON], assetUrl: String?, type: String?, authorIcon: String?, footer: String?, originalHeight: Int?, originalWidth: Int?, pretext: String?, text: String?, imageUrl: String?, thumbUrl: String?, actions: [StreamChatAction?]?, authorLink: String?, authorName: String?, fallback: String?, footerIcon: String?, giphy: StreamChatImages?, title: String?, titleLink: String?) {
        self.color = color
        
        self.duration = duration
        
        self.fields = fields
        
        self.ogScrapeUrl = ogScrapeUrl
        
        self.custom = custom
        
        self.assetUrl = assetUrl
        
        self.type = type
        
        self.authorIcon = authorIcon
        
        self.footer = footer
        
        self.originalHeight = originalHeight
        
        self.originalWidth = originalWidth
        
        self.pretext = pretext
        
        self.text = text
        
        self.imageUrl = imageUrl
        
        self.thumbUrl = thumbUrl
        
        self.actions = actions
        
        self.authorLink = authorLink
        
        self.authorName = authorName
        
        self.fallback = fallback
        
        self.footerIcon = footerIcon
        
        self.giphy = giphy
        
        self.title = title
        
        self.titleLink = titleLink
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case color
        
        case duration
        
        case fields
        
        case ogScrapeUrl = "og_scrape_url"
        
        case custom = "Custom"
        
        case assetUrl = "asset_url"
        
        case type
        
        case authorIcon = "author_icon"
        
        case footer
        
        case originalHeight = "original_height"
        
        case originalWidth = "original_width"
        
        case pretext
        
        case text
        
        case imageUrl = "image_url"
        
        case thumbUrl = "thumb_url"
        
        case actions
        
        case authorLink = "author_link"
        
        case authorName = "author_name"
        
        case fallback
        
        case footerIcon = "footer_icon"
        
        case giphy
        
        case title
        
        case titleLink = "title_link"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(color, forKey: .color)
        
        try container.encode(duration, forKey: .duration)
        
        try container.encode(fields, forKey: .fields)
        
        try container.encode(ogScrapeUrl, forKey: .ogScrapeUrl)
        
        try container.encode(custom, forKey: .custom)
        
        try container.encode(assetUrl, forKey: .assetUrl)
        
        try container.encode(type, forKey: .type)
        
        try container.encode(authorIcon, forKey: .authorIcon)
        
        try container.encode(footer, forKey: .footer)
        
        try container.encode(originalHeight, forKey: .originalHeight)
        
        try container.encode(originalWidth, forKey: .originalWidth)
        
        try container.encode(pretext, forKey: .pretext)
        
        try container.encode(text, forKey: .text)
        
        try container.encode(imageUrl, forKey: .imageUrl)
        
        try container.encode(thumbUrl, forKey: .thumbUrl)
        
        try container.encode(actions, forKey: .actions)
        
        try container.encode(authorLink, forKey: .authorLink)
        
        try container.encode(authorName, forKey: .authorName)
        
        try container.encode(fallback, forKey: .fallback)
        
        try container.encode(footerIcon, forKey: .footerIcon)
        
        try container.encode(giphy, forKey: .giphy)
        
        try container.encode(title, forKey: .title)
        
        try container.encode(titleLink, forKey: .titleLink)
    }
}
