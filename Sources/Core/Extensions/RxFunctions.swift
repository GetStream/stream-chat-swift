//
//  RxFunctions.swift
//  StreamChatCore
//
//  Created by Alexey Bukhtin on 24/04/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChatClient
import RxSwift
import RxCocoa

public extension ObservableType {
    /// Map an event value to `Void()`.
    func void() -> Observable<Void> {
        map { _ in Void() }
    }
}

public extension ObservableType where Element == ViewChanges {
    
    func asClientDriver() -> Driver<Element> {
        asDriver(onErrorRecover: { error in
            if let clientError = error as? ClientError {
                return Driver.just(Element.error(clientError))
            }
            
            return Driver.just(Element.error(.unexpectedError(description: error.localizedDescription, error: error)))
        })
    }
}

extension Reactive {
    
    /// Wraps a client request as `Observable`.
    /// - Parameter request: a client request completion block.
    /// - Returns: an observable request.
    func request<T: Decodable>(_ request: @escaping (@escaping Client.Completion<T>) -> Cancellable) -> Observable<T> {
        .create { observer in
            let subscription = request { result in
                if let value = result.value {
                    observer.onNext(value)
                    observer.onCompleted()
                } else if let error = result.error {
                    observer.onError(error)
                }
            }
            
            return Disposables.create { subscription.cancel() }
        }
    }
    
    func progressRequest<T: Decodable>(_ request: @escaping ProgressRequest<T>) -> Observable<ProgressResponse<T>> {
        .create { observer in
            let subscription = request({ progress in
                observer.onNext(.init(progress: progress, value: nil))
            }, { result in
                if let value = result.value {
                    observer.onNext(.init(progress: 1, value: value))
                    observer.onCompleted()
                } else if let error = result.error {
                    observer.onError(error)
                }
            })
            
            return Disposables.create { subscription.cancel() }
        }
    }
}
