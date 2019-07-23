//
//  Client+RxRequest.swift
//  StreamChat
//
//  Created by Alexey Bukhtin on 24/04/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import Foundation
import RxSwift

extension Client: ReactiveCompatible {}

public extension Reactive where Base == Client {
    /// Make an observable `Client` request.
    ///
    /// - Parameter endpoint: an endpoint (see `ChatEndpoint`).
    /// - Returns: an observable `Result<T, ClientError>`.
    func request<T: Decodable>(endpoint: ChatEndpoint) -> Observable<T> {
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
}
