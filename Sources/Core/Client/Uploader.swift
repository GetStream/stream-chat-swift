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
    public let channel: Channel
    /// An original file URL.
    public let url: URL?
    /// An original image.
    public let image: UIImage?
    /// A file name.
    public let fileName: String
    /// A file type.
    public let fileType: AttachmentFileType
    /// A file size.
    public let fileSize: Int64
    /// An uploading type.
    public let type: UploadingType
    /// An uploaded attachment.
    public private(set) var attachment: Attachment? = nil
    /// An error with uploading.
    public private(set) var error: Error? = nil
    /// The last uploading progress.
    public private(set) var lastProgress: Float = 0
    /// An observable uploading progress.
    public private(set) lazy var uploading: Observable<ProgressResponse<FileUploadResponse>> = createUploading()
    
    /// Init an uploading item.
    ///
    /// - Parameters:
    ///   - url: an original file URL.
    ///   - type: an uploading type.
    ///   - image: an original image.
    ///   - fileName: a file name.
    ///   - fileType: a file type.
    ///   - fileSize: a file size.
    public init(channel: Channel,
                url: URL,
                type: UploadingType = .file,
                image: UIImage? = nil,
                fileName: String? = nil,
                fileType: AttachmentFileType? = nil,
                fileSize: Int64 = 0) {
        self.channel = channel
        self.url = url
        self.type = type
        self.image = image
        self.fileName = fileName ?? url.lastPathComponent
        self.fileType = fileType ?? AttachmentFileType(ext: url.pathExtension)
        self.fileSize = fileSize > 0 ? fileSize : url.fileSize
    }
    
    private func createUploading() -> Observable<ProgressResponse<FileUploadResponse>> {
        let request: Observable<ProgressResponse<FileUploadResponse>>
        
        if type == .file || type == .video {
            if let url = url, let data = try? Data(contentsOf: url) {
                request = channel.sendFile(fileName: fileName, mimeType: fileType.mimeType, fileData: data)
            } else {
                return .error(ClientError.emptyBody)
            }
        } else {
            let imageData: Data
            var mimeType: String = fileType.mimeType
            
            if let url = url, let localImageData = try? Data(contentsOf: url) {
                imageData = localImageData
            } else if let encodedImageData = image?.jpegData(compressionQuality: 0.9) {
                imageData = encodedImageData
                mimeType = AttachmentFileType.jpeg.mimeType
            } else {
                return .error(ClientError.emptyBody)
            }
            
            request = channel.sendImage(fileName: fileName, mimeType: mimeType, imageData: imageData)
        }
        
        return request
            .do(onNext: { [weak self] progressResponse in
                self?.lastProgress = progressResponse.progress
                
                guard let self = self, let fileUploadResponse = progressResponse.result else {
                    return
                }
                
                if self.type == .image {
                    self.attachment = Attachment(type: .image, title: self.fileName, imageURL: fileUploadResponse.file)
                } else {
                    let fileAttachment = AttachmentFile(type: self.fileType, size: self.fileSize, mimeType: self.fileType.mimeType)
                    
                    self.attachment = Attachment(type: self.type == .video ? .video : .file,
                                                 title: self.fileName,
                                                 url: fileUploadResponse.file,
                                                 file: fileAttachment)
                }
            })
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
