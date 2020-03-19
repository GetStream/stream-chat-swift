//
//  AttachmentType.swift
//  StreamChatClient
//
//  Created by Alexey Bukhtin on 22/01/2020.
//  Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation

/// An attachment type.
public enum AttachmentType: RawRepresentable, Codable, Hashable, ExpressibleByStringLiteral {
    /// An attachment type.
    case unknown
    case custom(String)
    case image
    case imgur
    case giphy
    case video
    case youtube
    case product
    case file
    case link
    
    public var rawValue: String? {
        switch self {
        case .unknown:
            return nil
        case .custom(let raw):
            return raw
        case .image:
            return "image"
        case .imgur:
            return "imgur"
        case .giphy:
            return "giphy"
        case .video:
            return "video"
        case .youtube:
            return "youtube"
        case .product:
            return "product"
        case .file:
            return "file"
        case .link:
            return "link"
        }
    }
    
    var isImage: Bool { self == .image || self == .imgur || self == .giphy }
    
    public init(rawValue: String?) {
        switch rawValue {
        case "image":
            self = .image
        case "imgur":
            self = .imgur
        case "giphy":
            self = .giphy
        case "video":
            self = .video
        case "youtube":
            self = .youtube
        case "product":
            self = .product
        case "file":
            self = .file
        case "link":
            self = .link
        case .some(let raw) where !raw.isEmpty:
            self = .custom(raw)
        default:
            self = .unknown
        }
    }
    
    public init(from decoder: Decoder) throws {
        let rawValue = try decoder.singleValueContainer().decode(String.self)
        self = AttachmentType(rawValue: rawValue)
    }
    
    public init(stringLiteral value: String) {
        self.init(rawValue: value)
    }
    
    public func encode(to encoder: Encoder) throws {
        guard self != .unknown else {
            throw ClientError.encodingFailure(EncodingError.attachmentUnsupported, object: self)
        }
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}
