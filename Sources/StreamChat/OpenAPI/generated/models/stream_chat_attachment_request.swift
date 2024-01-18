//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatAttachmentRequest: Codable, Hashable {
    public var assetUrl: String?
    
    public var authorIcon: String?
    
    public var footerIcon: String?
    
    public var imageUrl: String?
    
    public var custom: [String: RawJSON]?
    
    public var actions: [StreamChatActionRequest?]?
    
    public var fields: [StreamChatFieldRequest?]?
    
    public var ogScrapeUrl: String?
    
    public var originalHeight: Int?
    
    public var originalWidth: Int?
    
    public var pretext: String?
    
    public var thumbUrl: String?
    
    public var authorLink: String?
    
    public var authorName: String?
    
    public var type: String?
    
    public var text: String?
    
    public var title: String?
    
    public var color: String?
    
    public var giphy: StreamChatImagesRequest?
    
    public var titleLink: String?
    
    public var fallback: String?
    
    public var footer: String?
    
    public init(assetUrl: String?, authorIcon: String?, footerIcon: String?, imageUrl: String?, custom: [String: RawJSON]?, actions: [StreamChatActionRequest?]?, fields: [StreamChatFieldRequest?]?, ogScrapeUrl: String?, originalHeight: Int?, originalWidth: Int?, pretext: String?, thumbUrl: String?, authorLink: String?, authorName: String?, type: String?, text: String?, title: String?, color: String?, giphy: StreamChatImagesRequest?, titleLink: String?, fallback: String?, footer: String?) {
        self.assetUrl = assetUrl
        
        self.authorIcon = authorIcon
        
        self.footerIcon = footerIcon
        
        self.imageUrl = imageUrl
        
        self.custom = custom
        
        self.actions = actions
        
        self.fields = fields
        
        self.ogScrapeUrl = ogScrapeUrl
        
        self.originalHeight = originalHeight
        
        self.originalWidth = originalWidth
        
        self.pretext = pretext
        
        self.thumbUrl = thumbUrl
        
        self.authorLink = authorLink
        
        self.authorName = authorName
        
        self.type = type
        
        self.text = text
        
        self.title = title
        
        self.color = color
        
        self.giphy = giphy
        
        self.titleLink = titleLink
        
        self.fallback = fallback
        
        self.footer = footer
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case assetUrl = "asset_url"
        
        case authorIcon = "author_icon"
        
        case footerIcon = "footer_icon"
        
        case imageUrl = "image_url"
        
        case custom = "Custom"
        
        case actions
        
        case fields
        
        case ogScrapeUrl = "og_scrape_url"
        
        case originalHeight = "original_height"
        
        case originalWidth = "original_width"
        
        case pretext
        
        case thumbUrl = "thumb_url"
        
        case authorLink = "author_link"
        
        case authorName = "author_name"
        
        case type
        
        case text
        
        case title
        
        case color
        
        case giphy
        
        case titleLink = "title_link"
        
        case fallback
        
        case footer
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(assetUrl, forKey: .assetUrl)
        
        try container.encode(authorIcon, forKey: .authorIcon)
        
        try container.encode(footerIcon, forKey: .footerIcon)
        
        try container.encode(imageUrl, forKey: .imageUrl)
        
        try container.encode(custom, forKey: .custom)
        
        try container.encode(actions, forKey: .actions)
        
        try container.encode(fields, forKey: .fields)
        
        try container.encode(ogScrapeUrl, forKey: .ogScrapeUrl)
        
        try container.encode(originalHeight, forKey: .originalHeight)
        
        try container.encode(originalWidth, forKey: .originalWidth)
        
        try container.encode(pretext, forKey: .pretext)
        
        try container.encode(thumbUrl, forKey: .thumbUrl)
        
        try container.encode(authorLink, forKey: .authorLink)
        
        try container.encode(authorName, forKey: .authorName)
        
        try container.encode(type, forKey: .type)
        
        try container.encode(text, forKey: .text)
        
        try container.encode(title, forKey: .title)
        
        try container.encode(color, forKey: .color)
        
        try container.encode(giphy, forKey: .giphy)
        
        try container.encode(titleLink, forKey: .titleLink)
        
        try container.encode(fallback, forKey: .fallback)
        
        try container.encode(footer, forKey: .footer)
    }
}
