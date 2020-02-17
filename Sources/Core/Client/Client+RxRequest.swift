//
//  Client+RxRequest.swift
//  StreamChatCore
//
//  Created by Alexey Bukhtin on 24/04/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import StreamChatClient
import RxSwift

/// A request type with a progress of a sending data.
public typealias ProgressRequest<T: Decodable> = (@escaping Client.Progress, @escaping Client.Completion<T>) -> URLSessionTask

/// A response type with a progress of a sending data.
/// The progress property can have float values from 0.0 to 1.0.
public struct ProgressResponse<T: Decodable>: Decodable {
    /// A request uploading progress from 0.0 to 1.0.
    public let progress: Float
    /// A response value.
    public let value: T?
}

extension Client: ReactiveCompatible {}

public extension Reactive where Base == Client {
    
    func request<T: Decodable>(_ request: @escaping (@escaping Client.Completion<T>) -> URLSessionTask) -> Observable<T> {
        .create { observer in
            let urlSessionTask = request { result in
                if let value = result.value {
                    observer.onNext(value)
                    observer.onCompleted()
                } else if let error = result.error {
                    observer.onError(error)
                }
            }
            
            return Disposables.create { urlSessionTask.cancel() }
        }
    }
    
    func progressRequest<T: Decodable>(_ request: @escaping ProgressRequest<T>) -> Observable<ProgressResponse<T>> {
        .create { observer in
            let urlSessionTask = request({ progress in
                observer.onNext(.init(progress: progress, value: nil))
            }, { result in
                if let value = result.value {
                    observer.onNext(.init(progress: 1, value: value))
                    observer.onCompleted()
                } else if let error = result.error {
                    observer.onError(error)
                }
            })
            
            return Disposables.create { urlSessionTask.cancel() }
        }
    }
    
    func connected<T: Decodable>(_ rxRequest: Observable<T>) -> Observable<T> {
        base.isConnected ? rxRequest : connection.filter({ $0.isConnected }).take(1).flatMapLatest { _ in rxRequest }
    }
}
