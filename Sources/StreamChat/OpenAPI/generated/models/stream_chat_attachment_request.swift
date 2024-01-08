//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatAttachmentRequest: Codable, Hashable {
    public var color: String?
    
    public var footer: String?
    
    public var imageUrl: String?
    
    public var text: String?
    
    public var custom: [String: RawJSON]?
    
    public var assetUrl: String?
    
    public var giphy: StreamChatImagesRequest?
    
    public var ogScrapeUrl: String?
    
    public var originalHeight: Int?
    
    public var title: String?
    
    public var authorIcon: String?
    
    public var footerIcon: String?
    
    public var fields: [StreamChatFieldRequest?]?
    
    public var originalWidth: Int?
    
    public var pretext: String?
    
    public var thumbUrl: String?
    
    public var actions: [StreamChatActionRequest?]?
    
    public var authorName: String?
    
    public var titleLink: String?
    
    public var type: String?
    
    public var authorLink: String?
    
    public var fallback: String?
    
    public init(color: String?, footer: String?, imageUrl: String?, text: String?, custom: [String: RawJSON]?, assetUrl: String?, giphy: StreamChatImagesRequest?, ogScrapeUrl: String?, originalHeight: Int?, title: String?, authorIcon: String?, footerIcon: String?, fields: [StreamChatFieldRequest?]?, originalWidth: Int?, pretext: String?, thumbUrl: String?, actions: [StreamChatActionRequest?]?, authorName: String?, titleLink: String?, type: String?, authorLink: String?, fallback: String?) {
        self.color = color
        
        self.footer = footer
        
        self.imageUrl = imageUrl
        
        self.text = text
        
        self.custom = custom
        
        self.assetUrl = assetUrl
        
        self.giphy = giphy
        
        self.ogScrapeUrl = ogScrapeUrl
        
        self.originalHeight = originalHeight
        
        self.title = title
        
        self.authorIcon = authorIcon
        
        self.footerIcon = footerIcon
        
        self.fields = fields
        
        self.originalWidth = originalWidth
        
        self.pretext = pretext
        
        self.thumbUrl = thumbUrl
        
        self.actions = actions
        
        self.authorName = authorName
        
        self.titleLink = titleLink
        
        self.type = type
        
        self.authorLink = authorLink
        
        self.fallback = fallback
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case color
        
        case footer
        
        case imageUrl = "image_url"
        
        case text
        
        case custom = "Custom"
        
        case assetUrl = "asset_url"
        
        case giphy
        
        case ogScrapeUrl = "og_scrape_url"
        
        case originalHeight = "original_height"
        
        case title
        
        case authorIcon = "author_icon"
        
        case footerIcon = "footer_icon"
        
        case fields
        
        case originalWidth = "original_width"
        
        case pretext
        
        case thumbUrl = "thumb_url"
        
        case actions
        
        case authorName = "author_name"
        
        case titleLink = "title_link"
        
        case type
        
        case authorLink = "author_link"
        
        case fallback
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(color, forKey: .color)
        
        try container.encode(footer, forKey: .footer)
        
        try container.encode(imageUrl, forKey: .imageUrl)
        
        try container.encode(text, forKey: .text)
        
        try container.encode(custom, forKey: .custom)
        
        try container.encode(assetUrl, forKey: .assetUrl)
        
        try container.encode(giphy, forKey: .giphy)
        
        try container.encode(ogScrapeUrl, forKey: .ogScrapeUrl)
        
        try container.encode(originalHeight, forKey: .originalHeight)
        
        try container.encode(title, forKey: .title)
        
        try container.encode(authorIcon, forKey: .authorIcon)
        
        try container.encode(footerIcon, forKey: .footerIcon)
        
        try container.encode(fields, forKey: .fields)
        
        try container.encode(originalWidth, forKey: .originalWidth)
        
        try container.encode(pretext, forKey: .pretext)
        
        try container.encode(thumbUrl, forKey: .thumbUrl)
        
        try container.encode(actions, forKey: .actions)
        
        try container.encode(authorName, forKey: .authorName)
        
        try container.encode(titleLink, forKey: .titleLink)
        
        try container.encode(type, forKey: .type)
        
        try container.encode(authorLink, forKey: .authorLink)
        
        try container.encode(fallback, forKey: .fallback)
    }
}
