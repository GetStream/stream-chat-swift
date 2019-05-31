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
    
    func upload(image: UIImage) {
        let item = UploaderItem(image: image)
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
    private(set) var url: URL? = nil
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
    
    init(image: UIImage) {
        self.image = image
    }
    
    func upload(in channel: Channel) {
        let fileCompletion: Client.Completion<FileUploadResponse> = { [weak self] result in
            guard let self = self else {
                return
            }
            
            if let response = try? result.get() {
                self.url = response.file
                self.uploadingCompletion.onCompleted()
            } else if let error = result.error {
                self.error = error
                self.uploadingCompletion.onError(error)
            }
        }
        
        if let imageData = image?.jpegData(compressionQuality: 0.9) {
            urlSessionTask = Client.shared.request(endpoint: .sendImage(imageData, channel), fileCompletion)
        }
    }
}
