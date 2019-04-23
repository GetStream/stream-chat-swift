//
//  MessageAttachment.swift
//  GetStreamChat
//
//  Created by Alexey Bukhtin on 12/04/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import Foundation

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
    }
    
    public let title: String
    public let author: String?
    public let text: String?
    public let type: AttachmentType
    public let url: URL?
    public let imageURL: URL?
    public let file: AttachmentFile?
    
    public var isImage: Bool {
        return type.isImage && text == nil
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        author = try container.decodeIfPresent(String.self, forKey: .author)
        text = try container.decodeIfPresent(String.self, forKey: .text)

        title = try container.decodeIfPresent(String.self, forKey: .title)
            ?? container.decodeIfPresent(String.self, forKey: .fallback)
            ?? container.decodeIfPresent(String.self, forKey: .name)
            ?? ""
        
        if let existsType = try? AttachmentType(rawValue: container.decode(String.self, forKey: .type)) {
            type = existsType
        } else if let _ = try? container.decodeIfPresent(String.self, forKey: .ogURL) {
            type = .link
        } else {
            type = .unknown
        }
        
        file = type == .file ? try AttachmentFile(from: decoder) : nil
        
        // Parse Image URL.
        imageURL = Attachment.fixedURL(try container.decodeIfPresent(String.self, forKey: .image)
            ?? container.decodeIfPresent(String.self, forKey: .imageURL)
            ?? container.decodeIfPresent(String.self, forKey: .thumbURL))
        
        // Parse URL.
        url = Attachment.fixedURL(try container.decodeIfPresent(String.self, forKey: .url)
            ?? container.decodeIfPresent(String.self, forKey: .titleLink)
            ?? container.decodeIfPresent(String.self, forKey: .assetURL)
            ?? container.decodeIfPresent(String.self, forKey: .ogURL))
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
    public func encode(to encoder: Encoder) throws {}
    
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

public enum AttachmentType: String, Codable {
    case unknown
    case image
    case imgur
    case giphy
    case video
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
    
    public let sizeFormatter: ByteCountFormatter = {
        let fomatter = ByteCountFormatter()
        return fomatter
    }()
    
    public var sizeString: String {
        return sizeFormatter.string(fromByteCount: size)
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        mimeType = try? container.decodeIfPresent(String.self, forKey: .mimeType)
        
        if let mimeType = mimeType {
            type = AttachmentFileType(mimeType: mimeType)
        } else {
            type = .unknown
        }
        
        size = try container.decodeIfPresent(Int64.self, forKey: .size) ?? 0
    }
}

public enum AttachmentFileType: String, Codable {
    case unknown
    case csv
    case doc
    case pdf
    case ppt
    case tar
    case xls
    case zip
    
    public init(mimeType: String) {
        switch mimeType {
        case "text/csv": self = .csv
        case "application/msword": self = .doc
        case "application/pdf": self = .pdf
        case "application/vnd.ms-powerpoint": self = .ppt
        case "application/x-tar": self = .tar
        case "application/vnd.ms-excel": self = .xls
        case "application/zip": self = .zip
        default: self = .unknown
        }
    }
}
