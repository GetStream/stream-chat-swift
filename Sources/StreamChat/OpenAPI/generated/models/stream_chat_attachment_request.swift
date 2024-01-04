//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatAttachmentRequest: Codable, Hashable {
    public var fallback: String?
    
    public var fields: [StreamChatFieldRequest?]?
    
    public var footerIcon: String?
    
    public var imageUrl: String?
    
    public var ogScrapeUrl: String?
    
    public var originalHeight: Int?
    
    public var type: String?
    
    public var authorName: String?
    
    public var footer: String?
    
    public var originalWidth: Int?
    
    public var text: String?
    
    public var thumbUrl: String?
    
    public var custom: [String: RawJSON]?
    
    public var authorLink: String?
    
    public var color: String?
    
    public var pretext: String?
    
    public var title: String?
    
    public var titleLink: String?
    
    public var actions: [StreamChatActionRequest?]?
    
    public var authorIcon: String?
    
    public var giphy: StreamChatImagesRequest?
    
    public var assetUrl: String?
    
    public init(fallback: String?, fields: [StreamChatFieldRequest?]?, footerIcon: String?, imageUrl: String?, ogScrapeUrl: String?, originalHeight: Int?, type: String?, authorName: String?, footer: String?, originalWidth: Int?, text: String?, thumbUrl: String?, custom: [String: RawJSON]?, authorLink: String?, color: String?, pretext: String?, title: String?, titleLink: String?, actions: [StreamChatActionRequest?]?, authorIcon: String?, giphy: StreamChatImagesRequest?, assetUrl: String?) {
        self.fallback = fallback
        
        self.fields = fields
        
        self.footerIcon = footerIcon
        
        self.imageUrl = imageUrl
        
        self.ogScrapeUrl = ogScrapeUrl
        
        self.originalHeight = originalHeight
        
        self.type = type
        
        self.authorName = authorName
        
        self.footer = footer
        
        self.originalWidth = originalWidth
        
        self.text = text
        
        self.thumbUrl = thumbUrl
        
        self.custom = custom
        
        self.authorLink = authorLink
        
        self.color = color
        
        self.pretext = pretext
        
        self.title = title
        
        self.titleLink = titleLink
        
        self.actions = actions
        
        self.authorIcon = authorIcon
        
        self.giphy = giphy
        
        self.assetUrl = assetUrl
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case fallback
        
        case fields
        
        case footerIcon = "footer_icon"
        
        case imageUrl = "image_url"
        
        case ogScrapeUrl = "og_scrape_url"
        
        case originalHeight = "original_height"
        
        case type
        
        case authorName = "author_name"
        
        case footer
        
        case originalWidth = "original_width"
        
        case text
        
        case thumbUrl = "thumb_url"
        
        case custom = "Custom"
        
        case authorLink = "author_link"
        
        case color
        
        case pretext
        
        case title
        
        case titleLink = "title_link"
        
        case actions
        
        case authorIcon = "author_icon"
        
        case giphy
        
        case assetUrl = "asset_url"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(fallback, forKey: .fallback)
        
        try container.encode(fields, forKey: .fields)
        
        try container.encode(footerIcon, forKey: .footerIcon)
        
        try container.encode(imageUrl, forKey: .imageUrl)
        
        try container.encode(ogScrapeUrl, forKey: .ogScrapeUrl)
        
        try container.encode(originalHeight, forKey: .originalHeight)
        
        try container.encode(type, forKey: .type)
        
        try container.encode(authorName, forKey: .authorName)
        
        try container.encode(footer, forKey: .footer)
        
        try container.encode(originalWidth, forKey: .originalWidth)
        
        try container.encode(text, forKey: .text)
        
        try container.encode(thumbUrl, forKey: .thumbUrl)
        
        try container.encode(custom, forKey: .custom)
        
        try container.encode(authorLink, forKey: .authorLink)
        
        try container.encode(color, forKey: .color)
        
        try container.encode(pretext, forKey: .pretext)
        
        try container.encode(title, forKey: .title)
        
        try container.encode(titleLink, forKey: .titleLink)
        
        try container.encode(actions, forKey: .actions)
        
        try container.encode(authorIcon, forKey: .authorIcon)
        
        try container.encode(giphy, forKey: .giphy)
        
        try container.encode(assetUrl, forKey: .assetUrl)
    }
}
