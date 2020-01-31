//
//  Uploader.swift
//  StreamChatCore
//
//  Created by Alexey Bukhtin on 31/05/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import UIKit
import RxSwift

/// An uploader manager.
public final class Uploader {
    
    /// A list of UploaderItem for the upload.
    public private(set) var items: [UploaderItem] = []
    
    /// Uplode the item.
    ///
    /// - Parameter item: an uploading item.
    public func upload(item: UploaderItem) {
        items.insert(item, at: 0)
    }
    
    /// Remove an uploading item and cancel the current uploading state.
    ///
    /// - Parameter item: an uploading item for remove.
    public func remove(_ item: UploaderItem) {
        if let index = items.firstIndex(of: item) {
            items.remove(at: index)
        }
    }
    
    /// Remove all uploading items and cancel all uploading states.s
    public func reset() {
        items = []
    }
}

/// An uploader item.
public final class UploaderItem: Equatable {
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
    /// An uploaded attachment.
    public private(set) var attachment: Attachment?
    /// An error with uploading.
    public private(set) var error: Error?
    /// The last uploading progress.
    public private(set) var lastProgress: Float = 0
    /// An observable uploading progress.
    public private(set) lazy var uploading: Observable<ProgressResponse<URL>> = createUploading()
    
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
                fileSize: Int64 = 0) {
        self.channel = channel
        self.url = url
        self.type = type
        self.image = image
        self.gifData = gifData
        self.fileSize = fileSize > 0 ? fileSize : (url?.fileSize ?? 0)
        
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
    }
    
    /// Init an uploader item with a given uploaded image attachment.
    ///
    /// - Parameters:
    ///     - attachment: an uploaded attachment.
    ///     - previewImage: a preview of the uploaded image.
    ///     - previewImageGifData: a preview of the uploaded gif image data.
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
    }
    
    /// Init an uploader item with a given uploaded file.
    ///
    /// - Parameters:
    ///   - attachment: an uploaded file attachment.
    ///   - fileName: an uploaded file name.
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
    }
    
    private func createUploading() -> Observable<ProgressResponse<URL>> {
        guard let channel = channel else {
            return .empty()
        }
        
        let request: Observable<ProgressResponse<URL>>
        
        if type == .file || type == .video {
            if let url = url, let data = try? Data(contentsOf: url) {
                request = channel.sendFile(fileName: fileName, mimeType: fileType.mimeType, fileData: data)
            } else {
                return .error(ClientError.emptyBody(description: "For file at URL: \(url?.absoluteString ?? "<unknown>")"))
            }
        } else {
            let imageData: Data
            var mimeType: String = fileType.mimeType
            
            if let gifData = gifData {
                imageData = gifData
                mimeType = AttachmentFileType.gif.mimeType
            } else if let url = url, let localImageData = try? Data(contentsOf: url) {
                imageData = localImageData
            } else if let encodedImageData = image?.jpegData(compressionQuality: 0.9) {
                imageData = encodedImageData
                mimeType = AttachmentFileType.jpeg.mimeType
            } else {
                let errorDescription = "For image: gifData = \(gifData == nil ? "no" : "yes"), "
                    + "URL = \(url?.absoluteString ?? "<none>"), "
                    + "image data: \(image?.description ?? "<none>")"
                
                return .error(ClientError.emptyBody(description: errorDescription))
            }
            
            request = channel.sendImage(fileName: fileName, mimeType: mimeType, imageData: imageData)
        }
        
        return request
            .retry(3)
            .do(onNext: { [weak self] progressResponse in
                self?.lastProgress = progressResponse.progress
                
                guard let self = self, let fileURL = progressResponse.result else {
                    return
                }
                
                if self.type == .image {
                    self.attachment = Attachment(type: .image, title: self.fileName, imageURL: fileURL)
                } else {
                    let fileAttachment = AttachmentFile(type: self.fileType, size: self.fileSize, mimeType: self.fileType.mimeType)
                    
                    self.attachment = Attachment(type: self.type == .video ? .video : .file,
                                                 title: self.fileName,
                                                 url: fileURL,
                                                 file: fileAttachment)
                }},
                onError: { [weak self] in self?.error = $0 }
            )
            .share()
    }
    
    public static func == (lhs: UploaderItem, rhs: UploaderItem) -> Bool {
        return lhs.url == rhs.url
            && lhs.image == rhs.image
            && lhs.fileName == rhs.fileName
            && lhs.fileType == rhs.fileType
            && lhs.type == rhs.type
    }
}
