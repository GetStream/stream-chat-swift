//
//  Client+RxWatcherCount.swift
//  StreamChatCore
//
//  Created by Alexey Bukhtin on 09/02/2020.
//  Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChatClient
import RxSwift

public extension Reactive where Base == Client {
    /// Observe a watcher count of users for a given channel.
    func watcherCount(channel: Channel) -> Observable<Int> {
        .create { (observer) -> Disposable in
            let subscription = channel.subscribeToWatcherCount { (result) in
                do {
                    let response = try result.get()
                    observer.onNext(response)
                } catch {
                    observer.onError(error)
                }
            }
            
            return  Disposables.create { subscription.cancel() }
        }
    }
}
