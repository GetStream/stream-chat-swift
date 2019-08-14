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
    
    /// Check if the attachment is an image.
    public var isImage: Bool {
        return type.isImage && text == nil
    }
    
    /// Init an attachment.
    ///
    /// - Parameters:
    ///   - type: an attachment type.
    ///   - title: a title.
    ///   - url: an url.
    ///   - imageURL: an preview image url.
    ///   - file: a file description.
    public init(type: AttachmentType, title: String, url: URL? = nil, imageURL: URL? = nil, file: AttachmentFile? = nil) {
        self.type = type
        self.url = url
        self.imageURL = imageURL
        self.title = title
        self.file = file
        text = nil
        author = nil
        actions = []
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        author = try container.decodeIfPresent(String.self, forKey: .author)
        
        if let text = try container.decodeIfPresent(String.self, forKey: .text) {
            self.text = text.trimmingCharacters(in: .whitespacesAndNewlines)
        } else {
            text = nil
        }
        
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
        
        let typeString = try? container.decode(String.self, forKey: .type)
        let type: AttachmentType
        
        if let typeString = typeString, let existsType = AttachmentType(rawValue: typeString) {
            if existsType == .video, let url = url, url.absoluteString.contains("youtube") {
                type = .youtube
            } else {
                type = existsType
            }
        } else if let _ = try? container.decodeIfPresent(String.self, forKey: .ogURL) {
            type = .link
        } else {
            type = .unknown
        }
        
        self.type = type
        file = (type == .file || type == .video) ? try AttachmentFile(from: decoder) : nil
        actions = try container.decodeIfPresent([Action].self, forKey: .actions) ?? []
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
        public var isCancelled: Bool {
            return value == "cancel"
        }
        
        /// Check if the action is send button.
        public var isSend: Bool {
            return value == "send"
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

/// An attachment type.
public enum AttachmentType: String, Codable {
    /// An attachment type.
    case unknown, image, imgur, giphy, video, youtube, product, file, link
    
    fileprivate var isImage: Bool {
        return self == .image || self == .imgur || self == .giphy
    }
}

/// An attachment file description.
public struct AttachmentFile: Codable {
    private enum CodingKeys: String, CodingKey {
        case mimeType = "mime_type"
        case size = "file_size"
    }
    
    /// An attachment file type (see `AttachmentFileType`).
    public let type: AttachmentFileType
    /// A size of the file.
    public let size: Int64
    /// A mime type.
    public let mimeType: String?
    /// A file size formatter.
    public static let sizeFormatter = ByteCountFormatter()
    
    /// A formatted file size.
    public var sizeString: String {
        return AttachmentFile.sizeFormatter.string(fromByteCount: size)
    }
    
    init(type: AttachmentFileType, size: Int64, mimeType: String?) {
        self.type = type
        self.size = size
        self.mimeType = mimeType
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        mimeType = try? container.decodeIfPresent(String.self, forKey: .mimeType)
        
        if let mimeType = mimeType {
            type = AttachmentFileType(mimeType: mimeType)
        } else {
            type = .generic
        }
        
        size = try container.decodeIfPresent(Int64.self, forKey: .size) ?? 0
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(size, forKey: .size)
        try container.encodeIfPresent(mimeType, forKey: .mimeType)
    }
}

/// An attachment file type.
public enum AttachmentFileType: String, Codable {
    /// A file attachment type.
    case generic, csv, doc, pdf, ppt, tar, xls, zip, mp3, mp4, mov, jpeg, png, gif
    
    private static let mimeTypes: [String: AttachmentFileType] = ["application/octet-stream": .generic,
                                                                  "text/csv": .csv,
                                                                  "application/msword": .doc,
                                                                  "application/pdf": .pdf,
                                                                  "application/vnd.ms-powerpoint": .ppt,
                                                                  "application/x-tar": .tar,
                                                                  "application/vnd.ms-excel": .xls,
                                                                  "application/zip": .zip,
                                                                  "audio/mp3": .mp3,
                                                                  "video/mp4": .mp4,
                                                                  "video/quicktime": .mov,
                                                                  "image/jpeg": .jpeg,
                                                                  "image/jpg": .jpeg,
                                                                  "image/png": .png,
                                                                  "image/gif": .gif]
    
    /// Init an attachment file type by mime type.
    ///
    /// - Parameter mimeType: a mime type.
    public init(mimeType: String) {
        self = AttachmentFileType.mimeTypes[mimeType, default: .generic]
    }
    
    /// Init an attachment file type by a file extension.
    ///
    /// - Parameter ext: a file extension.
    public init(ext: String) {
        if ext == "jpg" {
            self = .jpeg
            return
        }
        
        self = AttachmentFileType(rawValue: ext) ?? .generic
    }
    
    /// Returns a mime type for the file type.
    public var mimeType: String {
        if self == .jpeg {
            return "image/jpeg"
        }
        
        return AttachmentFileType.mimeTypes.first(where: { $1 == self })?.key ?? "application/octet-stream"
    }
}
