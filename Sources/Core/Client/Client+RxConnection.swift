//
//  Client+RxConnection.swift
//  StreamChatCore
//
//  Created by Alexey Bukhtin on 09/01/2020.
//  Copyright © 2020 Stream.io Inc. All rights reserved.
//

import UIKit
import StreamChatClient
import RxSwift

// MARK: RxConnection

extension Client {
    private static var rxConnectionKey: UInt8 = 0
    
    fileprivate var rxConnection: Observable<Connection> {
        associated(to: self, key: &Client.rxConnectionKey) { [unowned self] in
            let isInternetAvailable: Observable<Bool> = InternetConnection.shared.isAvailableObservable.startWith(false)
            let app = UIApplication.shared
            
            let appState = app.rx.applicationState.filter({ $0 != .inactive })
                .distinctUntilChanged()
                .startWith(app.applicationState)
                .do(onNext: { self.logger?.log("📱 App state \($0)") })

            let onTokenChange = rx.onTokenChange
                .filter { [unowned self] _ in !self.isExpiredTokenInProgress }
            
            return Observable.combineLatest(isInternetAvailable, appState, onTokenChange)
                .observeOn(MainScheduler.instance)
                .do(onNext: { isInternetAvailable, appState, _ in
                    guard isInternetAvailable else {
                        self.logger?.log("💔🕸 Disconnected: No Internet")
                        self.disconnect()
                        return
                    }
                    
                    self.handleConnection(with: appState)
                })
                .flatMapLatest({ _ in self.rx.onConnect })
                .distinctUntilChanged()
                .do(onDispose: { self.disconnect() })
                .share(replay: 1)
                .debug()
        }
    }
}

// MARK: - Connection

extension Reactive where Base == Client {
    /// An observable connection.
    public var connection: Observable<Connection> { base.rxConnection }
}
