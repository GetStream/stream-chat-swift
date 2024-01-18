//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatGetOGResponse: Codable, Hashable {
    public var text: String?
    
    public var type: String?
    
    public var authorLink: String?
    
    public var footer: String?
    
    public var fields: [StreamChatField?]?
    
    public var giphy: StreamChatImages?
    
    public var imageUrl: String?
    
    public var actions: [StreamChatAction?]?
    
    public var assetUrl: String?
    
    public var duration: String
    
    public var fallback: String?
    
    public var footerIcon: String?
    
    public var originalHeight: Int?
    
    public var originalWidth: Int?
    
    public var custom: [String: RawJSON]
    
    public var authorIcon: String?
    
    public var ogScrapeUrl: String?
    
    public var pretext: String?
    
    public var thumbUrl: String?
    
    public var title: String?
    
    public var titleLink: String?
    
    public var authorName: String?
    
    public var color: String?
    
    public init(text: String?, type: String?, authorLink: String?, footer: String?, fields: [StreamChatField?]?, giphy: StreamChatImages?, imageUrl: String?, actions: [StreamChatAction?]?, assetUrl: String?, duration: String, fallback: String?, footerIcon: String?, originalHeight: Int?, originalWidth: Int?, custom: [String: RawJSON], authorIcon: String?, ogScrapeUrl: String?, pretext: String?, thumbUrl: String?, title: String?, titleLink: String?, authorName: String?, color: String?) {
        self.text = text
        
        self.type = type
        
        self.authorLink = authorLink
        
        self.footer = footer
        
        self.fields = fields
        
        self.giphy = giphy
        
        self.imageUrl = imageUrl
        
        self.actions = actions
        
        self.assetUrl = assetUrl
        
        self.duration = duration
        
        self.fallback = fallback
        
        self.footerIcon = footerIcon
        
        self.originalHeight = originalHeight
        
        self.originalWidth = originalWidth
        
        self.custom = custom
        
        self.authorIcon = authorIcon
        
        self.ogScrapeUrl = ogScrapeUrl
        
        self.pretext = pretext
        
        self.thumbUrl = thumbUrl
        
        self.title = title
        
        self.titleLink = titleLink
        
        self.authorName = authorName
        
        self.color = color
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case text
        
        case type
        
        case authorLink = "author_link"
        
        case footer
        
        case fields
        
        case giphy
        
        case imageUrl = "image_url"
        
        case actions
        
        case assetUrl = "asset_url"
        
        case duration
        
        case fallback
        
        case footerIcon = "footer_icon"
        
        case originalHeight = "original_height"
        
        case originalWidth = "original_width"
        
        case custom = "Custom"
        
        case authorIcon = "author_icon"
        
        case ogScrapeUrl = "og_scrape_url"
        
        case pretext
        
        case thumbUrl = "thumb_url"
        
        case title
        
        case titleLink = "title_link"
        
        case authorName = "author_name"
        
        case color
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(text, forKey: .text)
        
        try container.encode(type, forKey: .type)
        
        try container.encode(authorLink, forKey: .authorLink)
        
        try container.encode(footer, forKey: .footer)
        
        try container.encode(fields, forKey: .fields)
        
        try container.encode(giphy, forKey: .giphy)
        
        try container.encode(imageUrl, forKey: .imageUrl)
        
        try container.encode(actions, forKey: .actions)
        
        try container.encode(assetUrl, forKey: .assetUrl)
        
        try container.encode(duration, forKey: .duration)
        
        try container.encode(fallback, forKey: .fallback)
        
        try container.encode(footerIcon, forKey: .footerIcon)
        
        try container.encode(originalHeight, forKey: .originalHeight)
        
        try container.encode(originalWidth, forKey: .originalWidth)
        
        try container.encode(custom, forKey: .custom)
        
        try container.encode(authorIcon, forKey: .authorIcon)
        
        try container.encode(ogScrapeUrl, forKey: .ogScrapeUrl)
        
        try container.encode(pretext, forKey: .pretext)
        
        try container.encode(thumbUrl, forKey: .thumbUrl)
        
        try container.encode(title, forKey: .title)
        
        try container.encode(titleLink, forKey: .titleLink)
        
        try container.encode(authorName, forKey: .authorName)
        
        try container.encode(color, forKey: .color)
    }
}
