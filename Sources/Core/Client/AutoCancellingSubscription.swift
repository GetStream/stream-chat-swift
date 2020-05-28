//
//  AutoCancellingSubscription.swift
//  StreamChatCore
//
//  Created by Alexey Bukhtin on 09/01/2020.
//  Copyright © 2020 Stream.io Inc. All rights reserved.
//

import StreamChatClient
import RxSwift

/// A subscription for events.
/// You have to keep subscription variable until you need events.
///
/// For example:
/// ```
/// class MyViewController: UIViewController {
///     var subscription: AutoCancellingSubscription?
///
///     open override func viewWillAppear() {
///         super.viewWillAppear(animated)
///
///         // Subscribe for client events.
///         subscription = Client.shared.onEvent() { result in
///             print(result)
///         }
///     }
///
///     open override func viewWillDisappear() {
///         super.viewWillDisappear()
///
///         // Unsubscribe from client events.
///         subscription?.cancel()
///     }
/// }
/// ```
final class AutoCancellingSubscription: AutoCancellable {
    fileprivate static let shared = AutoCancellingSubscription()
    private(set) var disposeBag = DisposeBag()
    
    /// Cancel the subscription.
    public func cancel() {
        disposeBag = DisposeBag()
    }
}

// MARK: Client Completion Binding

extension ObservableType {
    
    /// Bind observable result to a completion block.
    /// - Parameter onNext: a client completion block.
    /// - Returns: A subscription.
    func bind<T>(to onNext: @escaping Client.Completion<T>) -> AutoCancellable where Element == T {
        let subscription = AutoCancellingSubscription()
        subscribe(to: onNext).disposed(by: subscription.disposeBag)
        return subscription
    }
    
    /// Bind observable for the first event only to a completion block.
    /// - Parameter completion: a client completion block.
    func bindOnce<T>(to completion: @escaping Client.Completion<T>) where Element == T {
        take(1).subscribe(to: completion).disposed(by: AutoCancellingSubscription.shared.disposeBag)
    }
    
    private func subscribe<T>(to onNext: @escaping Client.Completion<T>) -> Disposable where Element == T {
        subscribe(onNext: { (element) in
            onNext(.success(element))
        }, onError: { (error) in
            if let clientError = error as? ClientError {
                onNext(.failure(clientError))
            } else {
                onNext(.failure(.unexpectedError(description: error.localizedDescription, error: error)))
            }
        })
    }
}
