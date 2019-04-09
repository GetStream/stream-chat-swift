//
//  Message.swift
//  GetStreamChat
//
//  Created by Alexey Bukhtin on 02/04/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import Foundation

public struct Message: Codable {
    private enum CodingKeys: String, CodingKey {
        case id
        case type
        case user
        case created = "created_at"
        case updated = "updated_at"
        case text
        case attachments
        case replyCount = "reply_count"
        case reactionCounts = "reaction_counts"
    }
    
    let id: String
    public let type: MessageType
    public let user: User
    public let created: Date
    public let updated: Date
    public let text: String
    public let attachments: [MessageAttachment]
    public let replyCount: Int
    public let reactionCounts: [String: Int]?
}


public enum MessageType: String, Codable {
    case regular
}

public struct MessageAttachment: Codable {
    private enum CodingKeys: String, CodingKey {
        case title
        case type
        case image
        case url
        case name
        case titleLink = "title_link"
        case thumbURL = "thumb_url"
        case fallback
        case imageURL = "image_url"
    }
    
    public let title: String
    public let type: MessageAttachmentType
    public let url: URL?
    public let imageURL: URL?
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        if let existsType = try MessageAttachmentType(rawValue: container.decode(String.self, forKey: .type)) {
            type = existsType
        } else {
            type = .unknown
        }
        
        imageURL = try container.decodeIfPresent(URL.self, forKey: .image)
            ?? container.decodeIfPresent(URL.self, forKey: .imageURL)
            ?? container.decodeIfPresent(URL.self, forKey: .thumbURL)
        
        url = try container.decodeIfPresent(URL.self, forKey: .url)
            ?? container.decodeIfPresent(URL.self, forKey: .imageURL)
            ?? container.decodeIfPresent(URL.self, forKey: .titleLink)
        
        title = try container.decodeIfPresent(String.self, forKey: .title)
            ?? container.decodeIfPresent(String.self, forKey: .fallback)
            ?? container.decodeIfPresent(String.self, forKey: .name)
            ?? ""
    }
    
    public func encode(to encoder: Encoder) throws {}
}

public enum MessageAttachmentType: String, Codable {
    case unknown
    case image
    case video
    case imgur
    case product
    
    var isImage: Bool {
        return self == .image || self == .imgur
    }
}
