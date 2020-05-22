//
//  Client+RxRequest.swift
//  StreamChatCore
//
//  Created by Alexey Bukhtin on 24/04/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import StreamChatClient
import Foundation
import RxSwift

/// A request type with a progress of a sending data.
public typealias ProgressRequest<T: Decodable> = (@escaping Client.Progress, @escaping Client.Completion<T>) -> Cancellable

/// A response type with a progress of a sending data.
/// The progress property can have float values from 0.0 to 1.0.
public struct ProgressResponse<T: Decodable>: Decodable {
    /// A request uploading progress from 0.0 to 1.0.
    public let progress: Float
    /// A response value.
    public let value: T?
}

public extension Reactive where Base == Client {
    /// Returns an observable connected event.
    func connected<T: Decodable>(_ rxRequest: Observable<T>) -> Observable<T> {
        base.isConnected ? rxRequest : connected.flatMapLatest { rxRequest }
    }
}
