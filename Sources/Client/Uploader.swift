//
//  Uploader.swift
//  GetStreamChat
//
//  Created by Alexey Bukhtin on 31/05/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import UIKit
import RxSwift

final class Uploader {
    
    let channel: Channel
    var items: [UploaderItem] = []
    
    init(channel: Channel) {
        self.channel = channel
    }
    
    func upload(item: UploaderItem) {
        items.insert(item, at: 0)
        DispatchQueue.global(qos: .utility).async { item.upload(in: self.channel) }
    }
    
    func remove(_ item: UploaderItem) {
        if let index = items.firstIndex(of: item) {
            items.remove(at: index).urlSessionTask?.cancel()
        }
    }
    
    func reset() {
        items = []
    }
}

final class UploaderItem: Equatable {
    enum UploadingType {
        case image
        case video
        case file
    }
    
    let url: URL?
    let image: UIImage?
    let fileName: String
    let fileType: AttachmentFileType
    let fileSize: Int64
    let type: UploadingType
    private(set) var attachment: Attachment? = nil
    private(set) var error: Error? = nil
    private(set) var urlSessionTask: URLSessionTask?
    private(set) var lastProgress: Float = 0
    let uploadingCompletion = PublishSubject<Void>()
    
    private(set) lazy var uploadingProgress: Observable<Float> = Client.shared.urlSessionTaskDelegate.uploadProgress
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
    
    init(pickedImage: PickedImage) {
        type = pickedImage.isVideo ? .video : .image
        url = pickedImage.fileURL
        image = pickedImage.image
        fileName = pickedImage.fileName
        fileSize = url?.fileSize ?? 0
        
        if let ext = url?.pathExtension.lowercased() {
            fileType = AttachmentFileType(ext: ext)
            return
        }
        
        if let dot = fileName.lastIndex(of: ".") {
            let ext = String(fileName.suffix(from: dot)).trimmingCharacters(in: .init(charactersIn: ".")).lowercased()
            fileType = AttachmentFileType(ext: ext)
        } else {
            fileType = .generic
        }
    }
    
    init(url: URL) {
        type = .file
        image = nil
        self.url = url
        fileName = url.lastPathComponent
        fileType = AttachmentFileType(ext: url.pathExtension)
        fileSize = url.fileSize
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
                self.error = error
                self.uploadingCompletion.onError(error)
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
    
    static func == (lhs: UploaderItem, rhs: UploaderItem) -> Bool {
        return lhs.url == rhs.url
            && lhs.image == rhs.image
            && lhs.fileName == rhs.fileName
            && lhs.fileType == rhs.fileType
            && lhs.type == rhs.type
    }
}
