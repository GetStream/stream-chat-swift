//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatGetOGResponse: Codable, Hashable {
    public var authorIcon: String?
    
    public var fields: [StreamChatField?]?
    
    public var giphy: StreamChatImages?
    
    public var originalWidth: Int?
    
    public var thumbUrl: String?
    
    public var color: String?
    
    public var fallback: String?
    
    public var imageUrl: String?
    
    public var text: String?
    
    public var originalHeight: Int?
    
    public var pretext: String?
    
    public var title: String?
    
    public var actions: [StreamChatAction?]?
    
    public var assetUrl: String?
    
    public var authorLink: String?
    
    public var authorName: String?
    
    public var ogScrapeUrl: String?
    
    public var type: String?
    
    public var custom: [String: RawJSON]
    
    public var duration: String
    
    public var footer: String?
    
    public var footerIcon: String?
    
    public var titleLink: String?
    
    public init(authorIcon: String?, fields: [StreamChatField?]?, giphy: StreamChatImages?, originalWidth: Int?, thumbUrl: String?, color: String?, fallback: String?, imageUrl: String?, text: String?, originalHeight: Int?, pretext: String?, title: String?, actions: [StreamChatAction?]?, assetUrl: String?, authorLink: String?, authorName: String?, ogScrapeUrl: String?, type: String?, custom: [String: RawJSON], duration: String, footer: String?, footerIcon: String?, titleLink: String?) {
        self.authorIcon = authorIcon
        
        self.fields = fields
        
        self.giphy = giphy
        
        self.originalWidth = originalWidth
        
        self.thumbUrl = thumbUrl
        
        self.color = color
        
        self.fallback = fallback
        
        self.imageUrl = imageUrl
        
        self.text = text
        
        self.originalHeight = originalHeight
        
        self.pretext = pretext
        
        self.title = title
        
        self.actions = actions
        
        self.assetUrl = assetUrl
        
        self.authorLink = authorLink
        
        self.authorName = authorName
        
        self.ogScrapeUrl = ogScrapeUrl
        
        self.type = type
        
        self.custom = custom
        
        self.duration = duration
        
        self.footer = footer
        
        self.footerIcon = footerIcon
        
        self.titleLink = titleLink
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case authorIcon = "author_icon"
        
        case fields
        
        case giphy
        
        case originalWidth = "original_width"
        
        case thumbUrl = "thumb_url"
        
        case color
        
        case fallback
        
        case imageUrl = "image_url"
        
        case text
        
        case originalHeight = "original_height"
        
        case pretext
        
        case title
        
        case actions
        
        case assetUrl = "asset_url"
        
        case authorLink = "author_link"
        
        case authorName = "author_name"
        
        case ogScrapeUrl = "og_scrape_url"
        
        case type
        
        case custom = "Custom"
        
        case duration
        
        case footer
        
        case footerIcon = "footer_icon"
        
        case titleLink = "title_link"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(authorIcon, forKey: .authorIcon)
        
        try container.encode(fields, forKey: .fields)
        
        try container.encode(giphy, forKey: .giphy)
        
        try container.encode(originalWidth, forKey: .originalWidth)
        
        try container.encode(thumbUrl, forKey: .thumbUrl)
        
        try container.encode(color, forKey: .color)
        
        try container.encode(fallback, forKey: .fallback)
        
        try container.encode(imageUrl, forKey: .imageUrl)
        
        try container.encode(text, forKey: .text)
        
        try container.encode(originalHeight, forKey: .originalHeight)
        
        try container.encode(pretext, forKey: .pretext)
        
        try container.encode(title, forKey: .title)
        
        try container.encode(actions, forKey: .actions)
        
        try container.encode(assetUrl, forKey: .assetUrl)
        
        try container.encode(authorLink, forKey: .authorLink)
        
        try container.encode(authorName, forKey: .authorName)
        
        try container.encode(ogScrapeUrl, forKey: .ogScrapeUrl)
        
        try container.encode(type, forKey: .type)
        
        try container.encode(custom, forKey: .custom)
        
        try container.encode(duration, forKey: .duration)
        
        try container.encode(footer, forKey: .footer)
        
        try container.encode(footerIcon, forKey: .footerIcon)
        
        try container.encode(titleLink, forKey: .titleLink)
    }
}
