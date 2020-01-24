//
//  AttachmentFileType.swift
//  StreamChatClient
//
//  Created by Alexey Bukhtin on 17/01/2020.
//  Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation

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
