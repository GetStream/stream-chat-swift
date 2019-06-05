//
//  MessageAttachment.swift
//  GetStreamChat
//
//  Created by Alexey Bukhtin on 12/04/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import UIKit

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
    
    public let title: String
    public let author: String?
    public let text: String?
    public let type: AttachmentType
    public let actions: [Action]
    public let url: URL?
    public let imageURL: URL?
    public let file: AttachmentFile?
    
    public var isImageOrVideo: Bool {
        return (type.isImage && text == nil) || type == .video
    }
    
    init(type: AttachmentType, title: String, url: URL? = nil, imageURL: URL? = nil, file: AttachmentFile? = nil) {
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
        text = try container.decodeIfPresent(String.self, forKey: .text)

        title = try container.decodeIfPresent(String.self, forKey: .title)
            ?? container.decodeIfPresent(String.self, forKey: .fallback)
            ?? container.decodeIfPresent(String.self, forKey: .name)
            ?? ""
        
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
        
        file = type == .file ? try AttachmentFile(from: decoder) : nil
        
        if let actions = try? container.decodeIfPresent([Action].self, forKey: .actions) {
            self.actions = actions
        } else {
            actions = []
        }
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
    struct Action: Decodable {
        let name: String
        let value: String
        let style: ActionStyle
        let type: ActionType
        let text: String
        
        var isCancelled: Bool {
            return value == "cancel"
        }
        
        var isSend: Bool {
            return value == "send"
        }
    }
    
    enum ActionType: String, Decodable {
        case button
    }
    
    enum ActionStyle: String, Decodable {
        case `default`
        case primary
    }
}

public enum AttachmentType: String, Codable {
    case unknown
    case image
    case imgur
    case giphy
    case video
    case youtube
    case product
    case file
    case link

    fileprivate var isImage: Bool {
        return self == .image || self == .imgur || self == .giphy
    }
}

public struct AttachmentFile: Codable {
    private enum CodingKeys: String, CodingKey {
        case mimeType = "mime_type"
        case size = "file_size"
    }
    
    public let type: AttachmentFileType
    public let size: Int64
    public let mimeType: String?
    
    public let sizeFormatter = ByteCountFormatter()
    
    public var sizeString: String {
        return sizeFormatter.string(fromByteCount: size)
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

public enum AttachmentFileType: String, Codable {
    case generic
    case csv
    case doc
    case pdf
    case ppt
    case tar
    case xls
    case zip
    case mp3
    case mp4
    case mov
    case jpeg
    case png
    case gif
    
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
    
    public init(mimeType: String) {
        self = AttachmentFileType.mimeTypes[mimeType, default: .generic]
    }
    
    public init(ext: String) {
        if ext == "jpg" {
            self = .jpeg
            return
        }
        
        self = AttachmentFileType(rawValue: ext) ?? .generic
    }
    
    var mimeType: String {
        return AttachmentFileType.mimeTypes.first(where: { $1 == self })?.key ?? "application/octet-stream"
    }
    
    var icon: UIImage {
        return UIImage.chat(named: rawValue.lowercased())
    }
}
