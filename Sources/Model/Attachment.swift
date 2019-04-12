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
        case type
        case image
        case url
        case name
        case titleLink = "title_link"
        case thumbURL = "thumb_url"
        case fallback
        case imageURL = "image_url"
        case assetURL = "asset_url"
    }
    
    public let title: String
    public let type: AttachmentType
    public let url: URL?
    public let imageURL: URL?
    public let file: AttachmentFile?
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        title = try container.decodeIfPresent(String.self, forKey: .title)
            ?? container.decodeIfPresent(String.self, forKey: .fallback)
            ?? container.decodeIfPresent(String.self, forKey: .name)
            ?? ""
        
        if let existsType = try? AttachmentType(rawValue: container.decode(String.self, forKey: .type)) {
            type = existsType
        } else {
            type = .unknown
        }
        
        url = try container.decodeIfPresent(URL.self, forKey: .url)
            ?? container.decodeIfPresent(URL.self, forKey: .imageURL)
            ?? container.decodeIfPresent(URL.self, forKey: .titleLink)
            ?? container.decodeIfPresent(URL.self, forKey: .assetURL)
        
        imageURL = try container.decodeIfPresent(URL.self, forKey: .image)
            ?? container.decodeIfPresent(URL.self, forKey: .imageURL)
            ?? container.decodeIfPresent(URL.self, forKey: .thumbURL)
        
        file = type == .file ? try AttachmentFile(from: decoder) : nil
    }
    
    public func encode(to encoder: Encoder) throws {}
}

public enum AttachmentType: String, Codable {
    case unknown
    case image
    case imgur
    case giphy
    case video
    case product
    case file
    
    var isImage: Bool {
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
