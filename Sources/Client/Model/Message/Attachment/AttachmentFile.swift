//
//  AttachmentFile.swift
//  StreamChatClient
//
//  Created by Alexey Bukhtin on 22/01/2020.
//  Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation

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
    public var sizeString: String { AttachmentFile.sizeFormatter.string(fromByteCount: size) }
    
    /// Init an attachment file.
    /// - Parameters:
    ///   - type: a file type.
    ///   - size: a file size.
    ///   - mimeType: a mime type.
    public init(type: AttachmentFileType, size: Int64, mimeType: String?) {
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
        
        if let size = try? container.decodeIfPresent(Int64.self, forKey: .size) {
            self.size = size
        } else if let floatSize = try? container.decodeIfPresent(Float64.self, forKey: .size) {
            size = Int64(floatSize.rounded())
        } else {
            size = 0
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(size, forKey: .size)
        try container.encodeIfPresent(mimeType, forKey: .mimeType)
    }
}

extension AttachmentFile: Hashable {
    
    public static func == (lhs: AttachmentFile, rhs: AttachmentFile) -> Bool {
        lhs.type == rhs.type
            && lhs.size == rhs.size
            && lhs.mimeType == rhs.mimeType
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(type)
        hasher.combine(size)
        hasher.combine(mimeType)
    }

}
