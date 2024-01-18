//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatAttachment: Codable, Hashable {
    public var footer: String?
    
    public var pretext: String?
    
    public var color: String?
    
    public var authorIcon: String?
    
    public var authorName: String?
    
    public var ogScrapeUrl: String?
    
    public var assetUrl: String?
    
    public var actions: [StreamChatAction?]?
    
    public var authorLink: String?
    
    public var fallback: String?
    
    public var imageUrl: String?
    
    public var custom: [String: RawJSON]
    
    public var footerIcon: String?
    
    public var giphy: StreamChatImages?
    
    public var originalHeight: Int?
    
    public var originalWidth: Int?
    
    public var text: String?
    
    public var thumbUrl: String?
    
    public var title: String?
    
    public var fields: [StreamChatField?]?
    
    public var type: String?
    
    public var titleLink: String?
    
    public init(footer: String?, pretext: String?, color: String?, authorIcon: String?, authorName: String?, ogScrapeUrl: String?, assetUrl: String?, actions: [StreamChatAction?]?, authorLink: String?, fallback: String?, imageUrl: String?, custom: [String: RawJSON], footerIcon: String?, giphy: StreamChatImages?, originalHeight: Int?, originalWidth: Int?, text: String?, thumbUrl: String?, title: String?, fields: [StreamChatField?]?, type: String?, titleLink: String?) {
        self.footer = footer
        
        self.pretext = pretext
        
        self.color = color
        
        self.authorIcon = authorIcon
        
        self.authorName = authorName
        
        self.ogScrapeUrl = ogScrapeUrl
        
        self.assetUrl = assetUrl
        
        self.actions = actions
        
        self.authorLink = authorLink
        
        self.fallback = fallback
        
        self.imageUrl = imageUrl
        
        self.custom = custom
        
        self.footerIcon = footerIcon
        
        self.giphy = giphy
        
        self.originalHeight = originalHeight
        
        self.originalWidth = originalWidth
        
        self.text = text
        
        self.thumbUrl = thumbUrl
        
        self.title = title
        
        self.fields = fields
        
        self.type = type
        
        self.titleLink = titleLink
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case footer
        
        case pretext
        
        case color
        
        case authorIcon = "author_icon"
        
        case authorName = "author_name"
        
        case ogScrapeUrl = "og_scrape_url"
        
        case assetUrl = "asset_url"
        
        case actions
        
        case authorLink = "author_link"
        
        case fallback
        
        case imageUrl = "image_url"
        
        case custom = "Custom"
        
        case footerIcon = "footer_icon"
        
        case giphy
        
        case originalHeight = "original_height"
        
        case originalWidth = "original_width"
        
        case text
        
        case thumbUrl = "thumb_url"
        
        case title
        
        case fields
        
        case type
        
        case titleLink = "title_link"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(footer, forKey: .footer)
        
        try container.encode(pretext, forKey: .pretext)
        
        try container.encode(color, forKey: .color)
        
        try container.encode(authorIcon, forKey: .authorIcon)
        
        try container.encode(authorName, forKey: .authorName)
        
        try container.encode(ogScrapeUrl, forKey: .ogScrapeUrl)
        
        try container.encode(assetUrl, forKey: .assetUrl)
        
        try container.encode(actions, forKey: .actions)
        
        try container.encode(authorLink, forKey: .authorLink)
        
        try container.encode(fallback, forKey: .fallback)
        
        try container.encode(imageUrl, forKey: .imageUrl)
        
        try container.encode(custom, forKey: .custom)
        
        try container.encode(footerIcon, forKey: .footerIcon)
        
        try container.encode(giphy, forKey: .giphy)
        
        try container.encode(originalHeight, forKey: .originalHeight)
        
        try container.encode(originalWidth, forKey: .originalWidth)
        
        try container.encode(text, forKey: .text)
        
        try container.encode(thumbUrl, forKey: .thumbUrl)
        
        try container.encode(title, forKey: .title)
        
        try container.encode(fields, forKey: .fields)
        
        try container.encode(type, forKey: .type)
        
        try container.encode(titleLink, forKey: .titleLink)
    }
}
