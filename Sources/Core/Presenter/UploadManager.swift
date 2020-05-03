//
//  Uploader.swift
//  StreamChatCore
//
//  Created by Alexey Bukhtin on 31/05/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import UIKit
import StreamChatClient
import RxSwift

/// An uploader manager.
public final class UploadManager {
    
    /// A list of images for the upload.
    public private(set) var images: [UploadingItem] = []
    /// A list of files for the upload.
    public private(set) var files: [UploadingItem] = []
    public let uploader: Uploader
    
    /// Init an upload manager
    /// - Parameter uploader: a client for uploading.
    public init(uploader: Uploader = Client.shared) {
        self.uploader = uploader
    }
    
    /// Add an uploading item to the manager.
    /// - Parameter item: an uploading item.
    public func add(item: UploadingItem) {
        switch item.type {
        case .image:
            images.insert(item, at: 0)
        case .file, .video:
            files.insert(item, at: 0)
        }
    }
    
    /// Remove an uploading item and cancel the current uploading state.
    ///
    /// - Parameter item: an uploading item for remove.
    public func remove(_ item: UploadingItem) {
        item.cancelUploading.onNext(())
        
        if let index = images.firstIndex(of: item) {
            images.remove(at: index)
            
            if let attachment = item.attachment, let imageURL = attachment.imageURL, let channel = item.channel {
                uploader.deleteImage(url: imageURL, channel: channel) { _ in }
            }
            
        } else if let index = files.firstIndex(of: item) {
            files.remove(at: index)
            
            if let attachment = item.attachment, let url = attachment.url, let channel = item.channel {
                uploader.deleteFile(url: url, channel: channel) { _ in }
            }
        }
    }
    
    /// Remove all uploading items and cancel all uploading states.s
    public func reset() {
        images = []
        files = []
    }
    
    public func startUploading(item: UploadingItem) -> Observable<ProgressResponse<URL>> {
        if let error = item.error {
            return .error(error)
        }
        
        // Return shared uploading.
        if let uploading = item.uploading {
            return uploading
        }
        
        guard let mimeType = item.mimeType, let data = item.data else {
            return .empty()
        }
        
        let request: Observable<ProgressResponse<URL>> = .create({ [weak self, weak item] observer -> Disposable in
            guard let uploader = self?.uploader, let item = item, let channel = item.channel else {
                return Disposables.create()
            }
            
            let subscription: Cancellable
            let progress: Client.Progress = { observer.onNext(.init(progress: $0, value: nil)) }
            
            let completion: Client.Completion<URL> = { result in
                if let value = result.value {
                    observer.onNext(.init(progress: 1, value: value))
                    observer.onCompleted()
                } else if let error = result.error {
                    observer.onError(error)
                }
            }
            
            switch item.type {
            case .image:
                subscription = uploader.sendImage(data: data,
                                                  fileName: item.fileName,
                                                  mimeType: mimeType,
                                                  channel: channel,
                                                  progress: progress,
                                                  completion: completion)
            case .file, .video:
                subscription = uploader.sendFile(data: data,
                                                 fileName: item.fileName,
                                                 mimeType: mimeType,
                                                 channel: channel,
                                                 progress: progress,
                                                 completion: completion)
            }
            
            return Disposables.create {
                subscription.cancel()
            }
        })
        
        item.uploading = request
            .takeUntil(item.cancelUploading)
            .do(onNext: { [weak item] progressResponse in
                item?.lastProgress = progressResponse.progress
                
                guard let item = item, let fileURL = progressResponse.value else {
                    return
                }
                
                switch item.type {
                case .image:
                    item.attachment = Attachment(type: .image,
                                                 title: item.fileName,
                                                 imageURL: fileURL,
                                                 extraData: item.extraData)
                case .file, .video:
                    let fileAttachment = AttachmentFile(type: item.fileType,
                                                        size: item.fileSize,
                                                        mimeType: item.fileType.mimeType)
                    
                    item.attachment = Attachment(type: item.type == .video ? .video : .file,
                                                 title: item.fileName,
                                                 url: fileURL,
                                                 file: fileAttachment,
                                                 extraData: item.extraData)
                }
            })
            .share()
        
        return item.uploading ?? .empty()
    }
}
