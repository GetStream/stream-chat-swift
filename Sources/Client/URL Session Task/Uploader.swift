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
    /// - Note: Please be sure to call `progress` and `completion` callbacks on the main thread.
    /// - Parameters:
    ///   - data: an image data.
    ///   - fileName: a default file name.
    ///   - mimeType: a mime type.
    ///   - channel: a channel.
    ///   - progress: a progress block of the uploading.
    ///   - completion: a completion block.
    @discardableResult
    func sendImage(data: Data,
                   fileName: String,
                   mimeType: String,
                   channel: Channel,
                   progress: @escaping (Float) -> Void,
                   completion: @escaping (Result<URL, ClientError>) -> Void) -> Cancellable
    
    /// Uploads a file with a given local file.
    /// - Note: Please be sure to call `progress` and `completion` callbacks on the main thread.
    /// - Parameters:
    ///   - data: a file data.
    ///   - fileName: a default file name.
    ///   - mimeType: a mime type.
    ///   - channel: a channel.
    ///   - progress: a progress block of the uploading.
    ///   - completion: a completion block.
    @discardableResult
    func sendFile(data: Data,
                  fileName: String,
                  mimeType: String,
                  channel: Channel,
                  progress: @escaping (Float) -> Void,
                  completion: @escaping (Result<URL, ClientError>) -> Void) -> Cancellable
    
    /// Delete an image with a given URL.
    /// - Note: Please be sure to call the `completion` callback on the main thread.
    /// - Parameters:
    ///   - url: an image URL.
    ///   - channel: a channel.
    ///   - completion: an empty completion block.
    @discardableResult
    func deleteImage(url: URL, channel: Channel, _ completion: @escaping (Result<EmptyData, ClientError>) -> Void) -> Cancellable
    
    /// Delete a file with a given URL.
    /// - Note: Please be sure to call the `completion` callback on the main thread.
    /// - Parameters:
    ///   - url: a file URL.
    ///   - channel: a channel.
    ///   - completion: an empty completion block.
    @discardableResult
    func deleteFile(url: URL, channel: Channel, _ completion: @escaping (Result<EmptyData, ClientError>) -> Void) -> Cancellable
}
