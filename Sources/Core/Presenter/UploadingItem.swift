//
//  UploadingItem.swift
//  StreamChatCore
//
//  Created by Alexey Bukhtin on 24/04/2020.
//  Copyright © 2020 Stream.io Inc. All rights reserved.
//

import UIKit
import StreamChatClient
import RxSwift

/// An uploader item.
public final class UploadingItem: Equatable {
    /// An uploading type.
    public enum UploadingType {
        case image
        case video
        case file
    }
    
    /// A channel for an uploading.
    public let channel: Channel?
    /// An original file URL.
    public let url: URL?
    /// An original image.
    public let image: UIImage?
    /// A gif data of the image.
    public let gifData: Data?
    /// A file name.
    public let fileName: String
    /// A file type.
    public let fileType: AttachmentFileType
    /// A file size.
    public let fileSize: Int64
    /// An uploading type.
    public let type: UploadingType
    /// An extra data for the attachment.
    public let extraData: Codable?
    /// An uploaded attachment.
    public internal(set) var attachment: Attachment?
    /// The last uploading progress.
    public internal(set) var lastProgress: Float = 0
    /// An observable uploading progress.
    var uploading: Observable<ProgressResponse<URL>>?
    /// An observable uploading progress.
    let cancelUploading = PublishSubject<Void>()
    
    /// A mime type.
    public private(set) var mimeType: String?
    /// Encoded data.
    public private(set) var data: Data?
    /// Encoded data error.
    public private(set) var error: ClientError?

    /// Init an uploading item.
    ///
    /// - Parameters:
    ///   - channel: a channel for the uploading.
    ///   - url: an original file URL.
    ///   - type: an uploading type.
    ///   - image: an original image.
    ///   - gifData: a original gif image data.
    ///   - fileName: a file name.
    ///   - fileType: a file type.
    ///   - fileSize: a file size.
    public init(channel: Channel,
                url: URL?,
                type: UploadingType = .file,
                image: UIImage? = nil,
                gifData: Data? = nil,
                fileName: String? = nil,
                fileType: AttachmentFileType? = nil,
                fileSize: Int64 = 0,
                extraData: Codable? = nil) throws {
        self.channel = channel
        self.url = url
        self.type = type
        self.image = image
        self.gifData = gifData
        self.fileSize = fileSize > 0 ? fileSize : (url?.fileSize ?? 0)
        self.extraData = extraData
        
        if let fileName = fileName {
            self.fileName = fileName
        } else if let url = url {
            self.fileName = url.lastPathComponent
        } else {
            self.fileName = "unknown.jpeg"
        }
        
        if let fileType = fileType {
            self.fileType = fileType
        } else if let url = url {
            self.fileType = AttachmentFileType(ext: url.pathExtension.lowercased())
        } else {
            self.fileType = .jpeg
        }
        
        try encodeData()
    }
    
    /// Init an uploader item with a given uploaded image attachment.
    ///
    /// - Parameters:
    ///     - attachment: an uploaded attachment.
    ///     - previewImage: a preview of the uploaded image.
    ///     - previewImageGifData: a preview of the uploaded gif image data.
    @available(*, deprecated, message: "Please use `init(channel:url:)` initializer")
    public init(attachment: Attachment, previewImage image: UIImage, previewImageGifData gifData: Data? = nil) {
        channel = nil
        url = attachment.url
        type = .image
        self.image = image
        self.gifData = gifData
        fileName = ""
        fileType = gifData == nil ? .generic : .gif
        fileSize = 0
        self.attachment = attachment
        extraData = nil
    }

    /// Init an uploader item with a given uploaded file.
    ///
    /// - Parameters:
    ///   - attachment: an uploaded file attachment.
    ///   - fileName: an uploaded file name.
    @available(*, deprecated, message: "Please use `init(channel:url:)` initializer")
    public init(attachment: Attachment, fileName: String) {
        channel = nil
        url = attachment.url
        type = .file
        image = nil
        gifData = nil
        self.fileName = fileName
        fileType = attachment.file?.type ?? .generic
        fileSize = attachment.file?.size ?? 0
        self.attachment = attachment
        extraData = nil
    }
    
    private func encodeData() throws {
        guard type != .file, type != .video else {
            guard let url = url else {
                error = .emptyBody(description: "Invalid URL: \(self.url?.absoluteString ?? "<unknown>")")
                throw error!
            }
            
            do {
                self.mimeType = fileType.mimeType
                data = try Data(contentsOf: url)
            } catch {
                self.error = .unexpectedError(description: "Cannot get data for url \(url): "
                                                            + error.localizedDescription,
                                              error: error)
                throw self.error!
            }
            
            return
        }
        
        var mimeType: String = fileType.mimeType
        let data: Data?

        if let gifData = gifData {
            data = gifData
            mimeType = AttachmentFileType.gif.mimeType
        } else if let url = url, let localImageData = try? Data(contentsOf: url) {
            data = localImageData
        } else if let encodedImageData = image?.jpegData(compressionQuality: 0.9) {
            data = encodedImageData
            mimeType = AttachmentFileType.jpeg.mimeType
        } else {
            let errorDescription = "For image: gifData = \(gifData == nil ? "no" : "yes"), "
                + "URL = \(url?.absoluteString ?? "<none>"), "
                + "image data: \(image?.description ?? "<none>")"
            
            error = .emptyBody(description: errorDescription)
            data = nil
            throw error!
        }
        
        self.mimeType = mimeType
        self.data = data
    }
    
    public static func == (lhs: UploadingItem, rhs: UploadingItem) -> Bool {
        lhs.channel == rhs.channel
            && lhs.url == rhs.url
            && lhs.image == rhs.image
            && lhs.fileName == rhs.fileName
            && lhs.fileType == rhs.fileType
            && lhs.fileSize == rhs.fileSize
            && lhs.type == rhs.type
    }
}
