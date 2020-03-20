//
//  MessageAttachment.swift
//  StreamChatCore
//
//  Created by Alexey Bukhtin on 12/04/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import UIKit

/// A message attachment.
public struct Attachment: Codable {
    private enum CodingKeys: String, CodingKey {
        case title
        case author = "author_name"
        case text
        case type
        case image
        case url
        case name
        case titleLink = "title_link"
        case thumbURL = "thumb_url"
        case fallback
        case imageURL = "image_url"
        case assetURL = "asset_url"
        case ogURL = "og_scrape_url"
        case actions
    }
    
    /// A custom extra data type for attachments.
    /// - Note: Use this variable to setup your own extra data type for decoding attachments custom fields from JSON data.
    public static var extraDataType: Codable.Type?
    
    /// A title.
    public let title: String
    /// An author.
    public let author: String?
    /// A description text.
    public let text: String?
    /// A type (see `AttachmentType`).
    public let type: AttachmentType
    /// Actions from a command (see `Action`, `Command`).
    public let actions: [Action]
    /// An URL.
    public let url: URL?
    /// An image preview URL.
    public let imageURL: URL?
    /// A file description (see `AttachmentFile`).
    public let file: AttachmentFile?
    /// An extra data for the attachment.
    public let extraData: Codable?
    
    /// Check if the attachment is an image.
    public var isImage: Bool { type.isImage && text == nil }
    
    /// Init an attachment.
    ///
    /// - Parameters:
    ///   - type: an attachment type.
    ///   - title: a title.
    ///   - url: an url.
    ///   - imageURL: an preview image url.
    ///   - file: a file description.
    ///   - extraData: an extra data.
    public init(type: AttachmentType,
                title: String,
                url: URL? = nil,
                imageURL: URL? = nil,
                file: AttachmentFile? = nil,
                extraData: Codable? = nil) {
        self.type = type
        self.url = url
        self.imageURL = imageURL
        self.title = title
        self.file = file
        self.extraData = extraData
        text = nil
        author = nil
        actions = []
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let author = try container.decodeIfPresent(String.self, forKey: .author)
        self.author = author
        var text = try container.decodeIfPresent(String.self, forKey: .text)?.trimmingCharacters(in: .whitespacesAndNewlines)
        
        title = (try container.decodeIfPresent(String.self, forKey: .title)
            ?? container.decodeIfPresent(String.self, forKey: .fallback)
            ?? container.decodeIfPresent(String.self, forKey: .name)
            ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Parse Image URL.
        imageURL = Attachment.fixedURL(try container.decodeIfPresent(String.self, forKey: .image)
            ?? container.decodeIfPresent(String.self, forKey: .imageURL)
            ?? container.decodeIfPresent(String.self, forKey: .thumbURL))
        
        // Parse URL.
        url = Attachment.fixedURL(try container.decodeIfPresent(String.self, forKey: .assetURL)
            ?? container.decodeIfPresent(String.self, forKey: .url)
            ?? container.decodeIfPresent(String.self, forKey: .titleLink)
            ?? container.decodeIfPresent(String.self, forKey: .ogURL))
        
        let type: AttachmentType

        if let typeString = try? container.decode(String.self, forKey: .type) {
            let existsType = AttachmentType(rawValue: typeString)

            if existsType == .video {
                if author == "GIPHY" {
                    type = .giphy
                    text = nil
                } else if let url = url, url.absoluteString.contains("youtube") {
                    type = .youtube
                } else {
                    type = existsType
                }
            } else {
                type = existsType
            }
        } else if let _ = try? container.decodeIfPresent(String.self, forKey: .ogURL) {
            // swiftlint:disable:previous unused_optional_binding
            type = .link
        } else {
            type = .unknown
        }
        
        self.type = type
        self.text = text
        file = (type == .file || type == .video) ? try AttachmentFile(from: decoder) : nil
        actions = try container.decodeIfPresent([Action].self, forKey: .actions) ?? []
        extraData = try? Self.extraDataType?.init(from: decoder) // swiftlint:disable:this explicit_init
    }
    
    /// Image upload:
    ///    {
    ///        type: 'image',
    ///        image_url: image.url,
    ///        fallback: image.file.name,
    ///    }
    ///
    /// File upload:
    ///    {
    ///         type: 'file',
    ///         asset_url: upload.url,
    ///         title: upload.file.name,
    ///         mime_type: upload.file.type,
    ///         file_size: upload.file.size,
    ///    }
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .type)
        try container.encode(title, forKey: (type == .image ? .fallback : .title))
        try container.encodeIfPresent(url, forKey: .assetURL)
        try container.encodeIfPresent(imageURL, forKey: .imageURL)
        try file?.encode(to: encoder)
        extraData?.encodeSafely(to: encoder, logMessage: "📦 when encoding an extra data for attachment")
    }
    
    private static func fixedURL(_ urlString: String?) -> URL? {
        guard let string = urlString else {
            return nil
        }
        
        var urlString = string
        
        if urlString.hasPrefix("//") {
            urlString = "https:\(urlString)"
        }
        
        if !urlString.lowercased().hasPrefix("http") {
            urlString = "https://\(urlString)"
        }
        
        return URL(string: urlString)
    }
}

extension Attachment: Hashable {
    
    public static func == (lhs: Attachment, rhs: Attachment) -> Bool {
        lhs.title == rhs.title
            && lhs.author == rhs.author
            && lhs.text == rhs.text
            && lhs.type == rhs.type
            && lhs.url == rhs.url
            && lhs.imageURL == rhs.imageURL
            && lhs.file == rhs.file
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(title)
        hasher.combine(author)
        hasher.combine(text)
        hasher.combine(type)
        hasher.combine(url)
        hasher.combine(imageURL)
        hasher.combine(file)
    }
}

// MARK: - Attachment Action

public extension Attachment {
    /// An attachment action, e.g. send, shuffle.
    struct Action: Decodable {
        /// A name.
        public let name: String
        /// A value of an action.
        public let value: String
        /// A style, e.g. primary button.
        public let style: ActionStyle
        /// A type, e.g. button.
        public let type: ActionType
        /// A text.
        public let text: String
        
        /// Check if the action is cancel button.
        public var isCancelled: Bool { value == "cancel" }
        /// Check if the action is send button.
        public var isSend: Bool { value == "send" }
        
        /// Init an attachment action.
        /// - Parameters:
        ///   - name: a name.
        ///   - value: a value.
        ///   - style: a style.
        ///   - type: a type.
        ///   - text: a text.
        public init(name: String, value: String, style: ActionStyle, type: ActionType, text: String) {
            self.name = name
            self.value = value
            self.style = style
            self.type = type
            self.text = text
        }
    }
    
    /// An attachment action type, e.g. button.
    enum ActionType: String, Decodable {
        case button
    }
    
    /// An attachment action style, e.g. primary button.
    enum ActionStyle: String, Decodable {
        case `default`
        case primary
    }
}
