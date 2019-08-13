//
//  Client+RxRequest.swift
//  StreamChatCore
//
//  Created by Alexey Bukhtin on 24/04/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import Foundation
import RxSwift

/// A response type with a progress of a sending data.
///
/// The progress property can have float values from 0.0 to 1.0.
public typealias ProgressResponse<T: Decodable> = (progress: Float, result: T?)

extension Client: ReactiveCompatible {}

public extension Reactive where Base == Client {
    
    /// Make an observable `Client` request.
    ///
    /// - Parameter endpoint: an endpoint (see `Endpoint`).
    /// - Returns: an observable result `T`.
    func request<T: Decodable>(endpoint: Endpoint) -> Observable<T> {
        return .create { observer in
            let task = self.base.request(endpoint: endpoint) { (result: Result<T, ClientError>) in
                switch result {
                case .success(let value):
                    observer.onNext(value)
                    observer.onCompleted()
                case .failure(let error):
                    observer.onError(error)
                }
            }
            
            return Disposables.create { [weak task] in task?.cancel() }
        }
    }
    
    /// Make an observable `Client` request when the client would be connected.
    ///
    /// - Parameter endpoint: an endpoint (see `Endpoint`).
    /// - Returns: an observable result `T`.
    func connectedRequest<T: Decodable>(endpoint: Endpoint) -> Observable<T> {
        return self.base.connectedRequest(request(endpoint: endpoint))
    }
    
    /// Make an observable `Client` request with a progress.
    ///
    /// - Parameter endpoint: an endpoint (see `Endpoint`).
    /// - Returns: an observable result with a progress `(progress: Float, result: T?)`.
    func progressRequest<T: Decodable>(endpoint: Endpoint) -> Observable<ProgressResponse<T>> {
        return .create { observer in
            var disposeBag: DisposeBag? = DisposeBag()
            
            let task = self.base.request(endpoint: endpoint) { (result: Result<T, ClientError>) in
                disposeBag = nil
                
                switch result {
                case .success(let value):
                    observer.onNext((1, value))
                    observer.onCompleted()
                case .failure(let error):
                    observer.onError(error)
                }
            }
            
            if let disposeBag = disposeBag {
                self.base.urlSessionTaskDelegate.uploadProgress.asObserver()
                    .filter { $0.task == task }
                    .subscribe(onNext: { observer.onNext(($0.progress, nil)) },
                               onError: { observer.onError($0) })
                    .disposed(by: disposeBag)
            }
            
            return Disposables.create { [weak task] in
                task?.cancel()
                disposeBag = nil
            }
        }
    }
}
