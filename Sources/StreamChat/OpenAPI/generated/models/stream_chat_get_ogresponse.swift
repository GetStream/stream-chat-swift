//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatGetOGResponse: Codable, Hashable {
    public var duration: String
    
    public var custom: [String: RawJSON]
    
    public var assetUrl: String? = nil
    
    public var authorIcon: String? = nil
    
    public var authorLink: String? = nil
    
    public var authorName: String? = nil
    
    public var color: String? = nil
    
    public var fallback: String? = nil
    
    public var footer: String? = nil
    
    public var footerIcon: String? = nil
    
    public var imageUrl: String? = nil
    
    public var ogScrapeUrl: String? = nil
    
    public var originalHeight: Int? = nil
    
    public var originalWidth: Int? = nil
    
    public var pretext: String? = nil
    
    public var text: String? = nil
    
    public var thumbUrl: String? = nil
    
    public var title: String? = nil
    
    public var titleLink: String? = nil
    
    public var type: String? = nil
    
    public var actions: [StreamChatAction?]? = nil
    
    public var fields: [StreamChatField?]? = nil
    
    public var giphy: StreamChatImages? = nil
    
    public init(duration: String, custom: [String: RawJSON], assetUrl: String? = nil, authorIcon: String? = nil, authorLink: String? = nil, authorName: String? = nil, color: String? = nil, fallback: String? = nil, footer: String? = nil, footerIcon: String? = nil, imageUrl: String? = nil, ogScrapeUrl: String? = nil, originalHeight: Int? = nil, originalWidth: Int? = nil, pretext: String? = nil, text: String? = nil, thumbUrl: String? = nil, title: String? = nil, titleLink: String? = nil, type: String? = nil, actions: [StreamChatAction?]? = nil, fields: [StreamChatField?]? = nil, giphy: StreamChatImages? = nil) {
        self.duration = duration
        
        self.custom = custom
        
        self.assetUrl = assetUrl
        
        self.authorIcon = authorIcon
        
        self.authorLink = authorLink
        
        self.authorName = authorName
        
        self.color = color
        
        self.fallback = fallback
        
        self.footer = footer
        
        self.footerIcon = footerIcon
        
        self.imageUrl = imageUrl
        
        self.ogScrapeUrl = ogScrapeUrl
        
        self.originalHeight = originalHeight
        
        self.originalWidth = originalWidth
        
        self.pretext = pretext
        
        self.text = text
        
        self.thumbUrl = thumbUrl
        
        self.title = title
        
        self.titleLink = titleLink
        
        self.type = type
        
        self.actions = actions
        
        self.fields = fields
        
        self.giphy = giphy
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case duration
        
        case custom
        
        case assetUrl = "asset_url"
        
        case authorIcon = "author_icon"
        
        case authorLink = "author_link"
        
        case authorName = "author_name"
        
        case color
        
        case fallback
        
        case footer
        
        case footerIcon = "footer_icon"
        
        case imageUrl = "image_url"
        
        case ogScrapeUrl = "og_scrape_url"
        
        case originalHeight = "original_height"
        
        case originalWidth = "original_width"
        
        case pretext
        
        case text
        
        case thumbUrl = "thumb_url"
        
        case title
        
        case titleLink = "title_link"
        
        case type
        
        case actions
        
        case fields
        
        case giphy
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(duration, forKey: .duration)
        
        try container.encode(custom, forKey: .custom)
        
        try container.encode(assetUrl, forKey: .assetUrl)
        
        try container.encode(authorIcon, forKey: .authorIcon)
        
        try container.encode(authorLink, forKey: .authorLink)
        
        try container.encode(authorName, forKey: .authorName)
        
        try container.encode(color, forKey: .color)
        
        try container.encode(fallback, forKey: .fallback)
        
        try container.encode(footer, forKey: .footer)
        
        try container.encode(footerIcon, forKey: .footerIcon)
        
        try container.encode(imageUrl, forKey: .imageUrl)
        
        try container.encode(ogScrapeUrl, forKey: .ogScrapeUrl)
        
        try container.encode(originalHeight, forKey: .originalHeight)
        
        try container.encode(originalWidth, forKey: .originalWidth)
        
        try container.encode(pretext, forKey: .pretext)
        
        try container.encode(text, forKey: .text)
        
        try container.encode(thumbUrl, forKey: .thumbUrl)
        
        try container.encode(title, forKey: .title)
        
        try container.encode(titleLink, forKey: .titleLink)
        
        try container.encode(type, forKey: .type)
        
        try container.encode(actions, forKey: .actions)
        
        try container.encode(fields, forKey: .fields)
        
        try container.encode(giphy, forKey: .giphy)
    }
}
