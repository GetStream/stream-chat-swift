//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatAttachment: Codable, Hashable {
    public var color: String?
    
    public var fallback: String?
    
    public var footer: String?
    
    public var ogScrapeUrl: String?
    
    public var pretext: String?
    
    public var custom: [String: RawJSON]
    
    public var assetUrl: String?
    
    public var giphy: StreamChatImages?
    
    public var originalWidth: Int?
    
    public var titleLink: String?
    
    public var type: String?
    
    public var authorLink: String?
    
    public var footerIcon: String?
    
    public var imageUrl: String?
    
    public var text: String?
    
    public var title: String?
    
    public var authorName: String?
    
    public var fields: [StreamChatField?]?
    
    public var originalHeight: Int?
    
    public var thumbUrl: String?
    
    public var actions: [StreamChatAction?]?
    
    public var authorIcon: String?
    
    public init(color: String?, fallback: String?, footer: String?, ogScrapeUrl: String?, pretext: String?, custom: [String: RawJSON], assetUrl: String?, giphy: StreamChatImages?, originalWidth: Int?, titleLink: String?, type: String?, authorLink: String?, footerIcon: String?, imageUrl: String?, text: String?, title: String?, authorName: String?, fields: [StreamChatField?]?, originalHeight: Int?, thumbUrl: String?, actions: [StreamChatAction?]?, authorIcon: String?) {
        self.color = color
        
        self.fallback = fallback
        
        self.footer = footer
        
        self.ogScrapeUrl = ogScrapeUrl
        
        self.pretext = pretext
        
        self.custom = custom
        
        self.assetUrl = assetUrl
        
        self.giphy = giphy
        
        self.originalWidth = originalWidth
        
        self.titleLink = titleLink
        
        self.type = type
        
        self.authorLink = authorLink
        
        self.footerIcon = footerIcon
        
        self.imageUrl = imageUrl
        
        self.text = text
        
        self.title = title
        
        self.authorName = authorName
        
        self.fields = fields
        
        self.originalHeight = originalHeight
        
        self.thumbUrl = thumbUrl
        
        self.actions = actions
        
        self.authorIcon = authorIcon
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case color
        
        case fallback
        
        case footer
        
        case ogScrapeUrl = "og_scrape_url"
        
        case pretext
        
        case custom = "Custom"
        
        case assetUrl = "asset_url"
        
        case giphy
        
        case originalWidth = "original_width"
        
        case titleLink = "title_link"
        
        case type
        
        case authorLink = "author_link"
        
        case footerIcon = "footer_icon"
        
        case imageUrl = "image_url"
        
        case text
        
        case title
        
        case authorName = "author_name"
        
        case fields
        
        case originalHeight = "original_height"
        
        case thumbUrl = "thumb_url"
        
        case actions
        
        case authorIcon = "author_icon"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(color, forKey: .color)
        
        try container.encode(fallback, forKey: .fallback)
        
        try container.encode(footer, forKey: .footer)
        
        try container.encode(ogScrapeUrl, forKey: .ogScrapeUrl)
        
        try container.encode(pretext, forKey: .pretext)
        
        try container.encode(custom, forKey: .custom)
        
        try container.encode(assetUrl, forKey: .assetUrl)
        
        try container.encode(giphy, forKey: .giphy)
        
        try container.encode(originalWidth, forKey: .originalWidth)
        
        try container.encode(titleLink, forKey: .titleLink)
        
        try container.encode(type, forKey: .type)
        
        try container.encode(authorLink, forKey: .authorLink)
        
        try container.encode(footerIcon, forKey: .footerIcon)
        
        try container.encode(imageUrl, forKey: .imageUrl)
        
        try container.encode(text, forKey: .text)
        
        try container.encode(title, forKey: .title)
        
        try container.encode(authorName, forKey: .authorName)
        
        try container.encode(fields, forKey: .fields)
        
        try container.encode(originalHeight, forKey: .originalHeight)
        
        try container.encode(thumbUrl, forKey: .thumbUrl)
        
        try container.encode(actions, forKey: .actions)
        
        try container.encode(authorIcon, forKey: .authorIcon)
    }
}
