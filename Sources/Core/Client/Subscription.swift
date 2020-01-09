//
//  Subscription.swift
//  StreamChatCore
//
//  Created by Alexey Bukhtin on 09/01/2020.
//  Copyright © 2020 Stream.io Inc. All rights reserved.
//

import RxSwift

/// A client result type.
public typealias ClientResult<T> = Result<T, ClientError>
/// A client completion type.
public typealias ClientCompletion<T> = (ClientResult<T>) -> Void
/// An empty client completion type.
public typealias EmptyClientCompletion = ClientCompletion<Void>

/// A subscription for an async request.
public final class Subscription {
    let disposeBag = DisposeBag()
}

// MARK: Client Completion Binding

extension ObservableType {
    
    /// Bind observable result to a completion block.
    /// - Parameter clientCompletion: a client completion block.
    /// - Returns: A subscription.
    func bind<T>(to clientCompletion: @escaping ClientCompletion<T>) -> Subscription where Element == T {
        let subscription = Subscription()
        
        subscribe({ event in
            switch event {
            case let .next(element):
                clientCompletion(.success(element))
            case let .error(error):
                if let clientError = error as? ClientError {
                    clientCompletion(.failure(clientError))
                }
            case .completed:
                break
            }
        }).disposed(by: subscription.disposeBag)
        
        return subscription
    }
}
