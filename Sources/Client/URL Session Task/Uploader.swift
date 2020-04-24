//
//  Uploader.swift
//  StreamChatClient
//
//  Created by Alexey Bukhtin on 23/04/2020.
//  Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation

/// A custom uploader protocol.
public protocol Uploader {
    
    /// Uploads an image with a given data from the camera.
    /// - Parameters:
    ///   - data: an image data.
    ///   - fileName: a default file name.
    ///   - mimeType: a mime type.
    ///   - channel: a channel.
    ///   - progress: a progress block of the uploading.
    ///   - completion: a completion block.
    @discardableResult
    func uploadImage(data: Data,
                     fileName: String,
                     mimeType: String,
                     channel: Channel,
                     progress: @escaping Client.Progress,
                     completion: @escaping Client.Completion<URL>) -> Cancellable
    
    /// Uploads a file with a given local file.
    /// - Parameters:
    ///   - data: a file data.
    ///   - fileName: a default file name.
    ///   - mimeType: a mime type.
    ///   - channel: a channel.
    ///   - progress: a progress block of the uploading.
    ///   - completion: a completion block.
    @discardableResult
    func uploadFile(data: Data,
                    fileName: String,
                    mimeType: String,
                    channel: Channel,
                    progress: @escaping Client.Progress,
                    completion: @escaping Client.Completion<URL>) -> Cancellable
}
