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
    
    func remove(at index: Int) {
        if index < items.count {
            items.remove(at: index).urlSessionTask?.cancel()
        }
    }
    
    func reset() {
        items = []
    }
}

final class UploaderItem {
    let image: UIImage?
    let fileName: String
    let localURL: URL?
    let fileType: AttachmentFileType
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
        image = pickedImage.image
        fileName = pickedImage.fileName
        localURL = pickedImage.fileURL
        
        if let ext = localURL?.pathExtension {
            fileType = AttachmentFileType(ext: ext)
            return
        }
        
        if let dot = fileName.lastIndex(of: ".") {
            let ext = String(fileName.suffix(from: dot)).trimmingCharacters(in: .init(charactersIn: "."))
            fileType = AttachmentFileType(ext: ext)
        } else {
            fileType = .unknown
        }
    }
    
    func upload(in channel: Channel) {
        let imageCompletion: Client.Completion<FileUploadResponse> = { [weak self] result in
            guard let self = self else {
                return
            }
            
            if let response = try? result.get() {
                self.attachment = Attachment(type: .image, title: self.fileName, imageURL: response.file)
                self.uploadingCompletion.onCompleted()
            } else if let error = result.error {
                self.error = error
                self.uploadingCompletion.onError(error)
            }
        }
        
        let imageData: Data
        var mimeType: String = fileType.mimeType
        
        if let localURL = localURL, let localImageData = try? Data(contentsOf: localURL) {
            imageData = localImageData
        } else  if let encodedImageData = image?.jpegData(compressionQuality: 0.9) {
            imageData = encodedImageData
            mimeType = AttachmentFileType.jpeg.mimeType
        } else {
            return
        }
        
        urlSessionTask = Client.shared.request(endpoint: .sendImage(fileName, mimeType, imageData, channel), imageCompletion)
    }
}
