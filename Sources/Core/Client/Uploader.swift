//
//  Uploader.swift
//  StreamChat
//
//  Created by Alexey Bukhtin on 31/05/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import UIKit
import RxSwift

/// An uploader manager.
public final class Uploader {
    
    /// A channel for the uploading.
    public let channel: Channel
    /// A list of UploaderItem for the upload.
    public private(set) var items: [UploaderItem] = []
    
    /// Init an uploader for a given channel.
    ///
    /// - Parameter channel: a channel for the uploading.
    public init(channel: Channel) {
        self.channel = channel
    }
    
    /// Uplode the item.
    ///
    /// - Parameter item: an uploading item.
    public func upload(item: UploaderItem) {
        items.insert(item, at: 0)
        DispatchQueue.global(qos: .utility).async { item.upload(in: self.channel) }
    }
    
    /// Remove an uploading item and cancel the current uploading state.
    ///
    /// - Parameter item: an uploading item for remove.
    public func remove(_ item: UploaderItem) {
        if let index = items.firstIndex(of: item) {
            items.remove(at: index).urlSessionTask?.cancel()
        }
    }
    
    /// Remove all uploading items and cancel all uploading states.s
    public func reset() {
        items.forEach { $0.urlSessionTask?.cancel() }
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
    private(set) var urlSessionTask: URLSessionTask?
    /// The last uploading progress.
    public private(set) var lastProgress: Float = 0
    private var tryToUploadAgain: Bool = true
    /// An observable uploading completion.
    public let uploadingCompletion = PublishSubject<Void>()
    
    /// An uploading progress.
    public private(set) lazy var uploadingProgress: Observable<Float> = Client.shared.urlSessionTaskDelegate.uploadProgress
        .filter { [weak self] in $0.task == self?.urlSessionTask }
        .map { [weak self] in
            if let error = $0.error {
                throw error
            }
            
            self?.lastProgress = $0.progress
            return $0.progress
        }
        .observeOn(MainScheduler.instance)
        .takeWhile { $0 < 1 }
    
    /// Init an uploading item.
    ///
    /// - Parameters:
    ///   - url: an original file URL.
    ///   - type: an uploading type.
    ///   - image: an original image.
    ///   - fileName: a file name.
    ///   - fileType: a file type.
    ///   - fileSize: a file size.
    public init(url: URL,
         type: UploadingType = .file,
         image: UIImage? = nil,
         fileName: String? = nil,
         fileType: AttachmentFileType? = nil,
         fileSize: Int64 = 0) {
        self.url = url
        self.type = type
        self.image = image
        self.fileName = fileName ?? url.lastPathComponent
        self.fileType = fileType ?? AttachmentFileType(ext: url.pathExtension)
        self.fileSize = fileSize > 0 ? fileSize : url.fileSize
    }
    
    func upload(in channel: Channel) {
        let fileCompletion: Client.Completion<FileUploadResponse> = { [weak self] result in
            guard let self = self else {
                return
            }
            
            if let response = try? result.get() {
                if self.type == .image {
                    self.attachment = Attachment(type: .image, title: self.fileName, imageURL: response.file)
                } else {
                    let fileAttachment = AttachmentFile(type: self.fileType, size: self.fileSize, mimeType: self.fileType.mimeType)
                    
                    self.attachment = Attachment(type: self.type == .video ? .video : .file,
                                                 title: self.fileName,
                                                 url: response.file,
                                                 file: fileAttachment)
                }
                
                self.uploadingCompletion.onCompleted()
                
            } else if let error = result.error {
                if self.tryToUploadAgain {
                    self.tryToUploadAgain = false
                    self.upload(in: channel)
                } else {
                    self.error = error
                    self.uploadingCompletion.onError(error)
                }
            }
        }
        
        if type == .file || type == .video {
            if let url = url, let data = try? Data(contentsOf: url) {
                urlSessionTask = Client.shared.request(endpoint: .sendFile(fileName, fileType.mimeType, data, channel), fileCompletion)
            } else {
                uploadingCompletion.onError(ClientError.emptyBody)
            }
            
            return
        }
        
        let imageData: Data
        var mimeType: String = fileType.mimeType
        
        if let url = url, let localImageData = try? Data(contentsOf: url) {
            imageData = localImageData
        } else  if let encodedImageData = image?.jpegData(compressionQuality: 0.9) {
            imageData = encodedImageData
            mimeType = AttachmentFileType.jpeg.mimeType
        } else {
            uploadingCompletion.onError(ClientError.emptyBody)
            return
        }
        
        urlSessionTask = Client.shared.request(endpoint: .sendImage(fileName, mimeType, imageData, channel), fileCompletion)
    }
    
    public static func == (lhs: UploaderItem, rhs: UploaderItem) -> Bool {
        return lhs.url == rhs.url
            && lhs.image == rhs.image
            && lhs.fileName == rhs.fileName
            && lhs.fileType == rhs.fileType
            && lhs.type == rhs.type
    }
}

struct FileUploadResponse: Decodable {
    let file: URL
}
