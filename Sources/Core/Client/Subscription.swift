//
//  Subscription.swift
//  StreamChatCore
//
//  Created by Alexey Bukhtin on 09/01/2020.
//  Copyright © 2020 Stream.io Inc. All rights reserved.
//

import RxSwift

/// A client completion block type.
public typealias ClientCompletion<T> = (Result<T, ClientError>) -> Void

/// A subscription for an async request.
/// You have to keep as an instance variable until you need results in a completion block.
///
/// For example:
/// ```
/// class MyViewController: UIViewController {
///     var subscription: Subscription?
///
///     open override func viewWillAppear() {
///         super.viewWillAppear(animated)
///
///         subscription = Client.shared.onEvent() { event
///             print(event)
///         }
///     }
///
///     open override func viewWillDisappear() {
///         super.viewWillDisappear()
///         subscription = nil
///     }
/// }
/// ```
public final class Subscription {
    fileprivate static let shared = Subscription()
    let disposeBag = DisposeBag()
}

// MARK: Client Completion Binding

extension ObservableType {
    
    /// Bind observable result to a completion block.
    /// - Parameter clientCompletion: a client completion block.
    /// - Returns: A subscription.
    func bind<T>(to clientCompletion: @escaping ClientCompletion<T>) -> Subscription where Element == T {
        let subscription = Subscription()
        subscribe(to: clientCompletion).disposed(by: subscription.disposeBag)
        return subscription
    }
    
    /// Bind observable for the first event only to a completion block.
    /// - Parameter clientCompletion: a client completion block.
    func bindOnce<T>(to clientCompletion: @escaping ClientCompletion<T>) where Element == T {
        take(1).subscribe(to: clientCompletion).disposed(by: Subscription.shared.disposeBag)
    }
    
    private func subscribe<T>(to clientCompletion: @escaping ClientCompletion<T>) -> Disposable where Element == T {
        return subscribe({ event in
            switch event {
            case let .next(element):
                clientCompletion(.success(element))
                
            case .completed:
                break
                
            case let .error(error):
                if let clientError = error as? ClientError {
                    clientCompletion(.failure(clientError))
                } else {
                    clientCompletion(.failure(.unexpectedError(nil, error)))
                }
            }
        })
    }
}
