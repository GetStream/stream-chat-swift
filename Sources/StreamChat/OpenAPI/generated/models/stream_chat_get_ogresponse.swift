//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatGetOGResponse: Codable, Hashable {
    public var text: String?
    
    public var thumbUrl: String?
    
    public var type: String?
    
    public var ogScrapeUrl: String?
    
    public var originalWidth: Int?
    
    public var fallback: String?
    
    public var fields: [StreamChatField?]?
    
    public var footer: String?
    
    public var giphy: StreamChatImages?
    
    public var originalHeight: Int?
    
    public var pretext: String?
    
    public var custom: [String: RawJSON]
    
    public var duration: String
    
    public var authorLink: String?
    
    public var color: String?
    
    public var imageUrl: String?
    
    public var assetUrl: String?
    
    public var authorIcon: String?
    
    public var footerIcon: String?
    
    public var title: String?
    
    public var titleLink: String?
    
    public var actions: [StreamChatAction?]?
    
    public var authorName: String?
    
    public init(text: String?, thumbUrl: String?, type: String?, ogScrapeUrl: String?, originalWidth: Int?, fallback: String?, fields: [StreamChatField?]?, footer: String?, giphy: StreamChatImages?, originalHeight: Int?, pretext: String?, custom: [String: RawJSON], duration: String, authorLink: String?, color: String?, imageUrl: String?, assetUrl: String?, authorIcon: String?, footerIcon: String?, title: String?, titleLink: String?, actions: [StreamChatAction?]?, authorName: String?) {
        self.text = text
        
        self.thumbUrl = thumbUrl
        
        self.type = type
        
        self.ogScrapeUrl = ogScrapeUrl
        
        self.originalWidth = originalWidth
        
        self.fallback = fallback
        
        self.fields = fields
        
        self.footer = footer
        
        self.giphy = giphy
        
        self.originalHeight = originalHeight
        
        self.pretext = pretext
        
        self.custom = custom
        
        self.duration = duration
        
        self.authorLink = authorLink
        
        self.color = color
        
        self.imageUrl = imageUrl
        
        self.assetUrl = assetUrl
        
        self.authorIcon = authorIcon
        
        self.footerIcon = footerIcon
        
        self.title = title
        
        self.titleLink = titleLink
        
        self.actions = actions
        
        self.authorName = authorName
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case text
        
        case thumbUrl = "thumb_url"
        
        case type
        
        case ogScrapeUrl = "og_scrape_url"
        
        case originalWidth = "original_width"
        
        case fallback
        
        case fields
        
        case footer
        
        case giphy
        
        case originalHeight = "original_height"
        
        case pretext
        
        case custom
        
        case duration
        
        case authorLink = "author_link"
        
        case color
        
        case imageUrl = "image_url"
        
        case assetUrl = "asset_url"
        
        case authorIcon = "author_icon"
        
        case footerIcon = "footer_icon"
        
        case title
        
        case titleLink = "title_link"
        
        case actions
        
        case authorName = "author_name"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(text, forKey: .text)
        
        try container.encode(thumbUrl, forKey: .thumbUrl)
        
        try container.encode(type, forKey: .type)
        
        try container.encode(ogScrapeUrl, forKey: .ogScrapeUrl)
        
        try container.encode(originalWidth, forKey: .originalWidth)
        
        try container.encode(fallback, forKey: .fallback)
        
        try container.encode(fields, forKey: .fields)
        
        try container.encode(footer, forKey: .footer)
        
        try container.encode(giphy, forKey: .giphy)
        
        try container.encode(originalHeight, forKey: .originalHeight)
        
        try container.encode(pretext, forKey: .pretext)
        
        try container.encode(custom, forKey: .custom)
        
        try container.encode(duration, forKey: .duration)
        
        try container.encode(authorLink, forKey: .authorLink)
        
        try container.encode(color, forKey: .color)
        
        try container.encode(imageUrl, forKey: .imageUrl)
        
        try container.encode(assetUrl, forKey: .assetUrl)
        
        try container.encode(authorIcon, forKey: .authorIcon)
        
        try container.encode(footerIcon, forKey: .footerIcon)
        
        try container.encode(title, forKey: .title)
        
        try container.encode(titleLink, forKey: .titleLink)
        
        try container.encode(actions, forKey: .actions)
        
        try container.encode(authorName, forKey: .authorName)
    }
}
