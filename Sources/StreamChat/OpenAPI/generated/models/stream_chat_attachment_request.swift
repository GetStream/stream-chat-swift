//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatAttachmentRequest: Codable, Hashable {
    public var authorName: String?
    
    public var fields: [StreamChatFieldRequest?]?
    
    public var footer: String?
    
    public var text: String?
    
    public var authorIcon: String?
    
    public var authorLink: String?
    
    public var ogScrapeUrl: String?
    
    public var originalHeight: Int?
    
    public var originalWidth: Int?
    
    public var title: String?
    
    public var titleLink: String?
    
    public var assetUrl: String?
    
    public var imageUrl: String?
    
    public var footerIcon: String?
    
    public var pretext: String?
    
    public var thumbUrl: String?
    
    public var type: String?
    
    public var actions: [StreamChatActionRequest?]?
    
    public var fallback: String?
    
    public var giphy: StreamChatImagesRequest?
    
    public var custom: [String: RawJSON]?
    
    public var color: String?
    
    public init(authorName: String?, fields: [StreamChatFieldRequest?]?, footer: String?, text: String?, authorIcon: String?, authorLink: String?, ogScrapeUrl: String?, originalHeight: Int?, originalWidth: Int?, title: String?, titleLink: String?, assetUrl: String?, imageUrl: String?, footerIcon: String?, pretext: String?, thumbUrl: String?, type: String?, actions: [StreamChatActionRequest?]?, fallback: String?, giphy: StreamChatImagesRequest?, custom: [String: RawJSON]?, color: String?) {
        self.authorName = authorName
        
        self.fields = fields
        
        self.footer = footer
        
        self.text = text
        
        self.authorIcon = authorIcon
        
        self.authorLink = authorLink
        
        self.ogScrapeUrl = ogScrapeUrl
        
        self.originalHeight = originalHeight
        
        self.originalWidth = originalWidth
        
        self.title = title
        
        self.titleLink = titleLink
        
        self.assetUrl = assetUrl
        
        self.imageUrl = imageUrl
        
        self.footerIcon = footerIcon
        
        self.pretext = pretext
        
        self.thumbUrl = thumbUrl
        
        self.type = type
        
        self.actions = actions
        
        self.fallback = fallback
        
        self.giphy = giphy
        
        self.custom = custom
        
        self.color = color
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case authorName = "author_name"
        
        case fields
        
        case footer
        
        case text
        
        case authorIcon = "author_icon"
        
        case authorLink = "author_link"
        
        case ogScrapeUrl = "og_scrape_url"
        
        case originalHeight = "original_height"
        
        case originalWidth = "original_width"
        
        case title
        
        case titleLink = "title_link"
        
        case assetUrl = "asset_url"
        
        case imageUrl = "image_url"
        
        case footerIcon = "footer_icon"
        
        case pretext
        
        case thumbUrl = "thumb_url"
        
        case type
        
        case actions
        
        case fallback
        
        case giphy
        
        case custom = "Custom"
        
        case color
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(authorName, forKey: .authorName)
        
        try container.encode(fields, forKey: .fields)
        
        try container.encode(footer, forKey: .footer)
        
        try container.encode(text, forKey: .text)
        
        try container.encode(authorIcon, forKey: .authorIcon)
        
        try container.encode(authorLink, forKey: .authorLink)
        
        try container.encode(ogScrapeUrl, forKey: .ogScrapeUrl)
        
        try container.encode(originalHeight, forKey: .originalHeight)
        
        try container.encode(originalWidth, forKey: .originalWidth)
        
        try container.encode(title, forKey: .title)
        
        try container.encode(titleLink, forKey: .titleLink)
        
        try container.encode(assetUrl, forKey: .assetUrl)
        
        try container.encode(imageUrl, forKey: .imageUrl)
        
        try container.encode(footerIcon, forKey: .footerIcon)
        
        try container.encode(pretext, forKey: .pretext)
        
        try container.encode(thumbUrl, forKey: .thumbUrl)
        
        try container.encode(type, forKey: .type)
        
        try container.encode(actions, forKey: .actions)
        
        try container.encode(fallback, forKey: .fallback)
        
        try container.encode(giphy, forKey: .giphy)
        
        try container.encode(custom, forKey: .custom)
        
        try container.encode(color, forKey: .color)
    }
}
