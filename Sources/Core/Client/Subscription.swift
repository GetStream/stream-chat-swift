//
//  Subscription.swift
//  StreamChatCore
//
//  Created by Alexey Bukhtin on 09/01/2020.
//  Copyright © 2020 Stream.io Inc. All rights reserved.
//

import RxSwift

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
    /// - Parameter onNext: a client completion block.
    /// - Returns: A subscription.
    func bind<T>(to onNext: @escaping ClientCompletion<T>) -> Subscription where Element == T {
        let subscription = Subscription()
        subscribe(to: onNext).disposed(by: subscription.disposeBag)
        return subscription
    }
    
    /// Bind observable for the first event only to a completion block.
    /// - Parameter completion: a client completion block.
    func bindOnce<T>(to completion: @escaping ClientCompletion<T>) where Element == T {
        take(1).subscribe(to: completion).disposed(by: Subscription.shared.disposeBag)
    }
    
    private func subscribe<T>(to onNext: @escaping ClientCompletion<T>) -> Disposable where Element == T {
        return subscribe({ event in
            switch event {
            case let .next(element):
                onNext(.success(element))
                
            case .completed:
                break
                
            case let .error(error):
                if let clientError = error as? ClientError {
                    onNext(.failure(clientError))
                } else {
                    onNext(.failure(.unexpectedError(nil, error)))
                }
            }
        })
    }
}
