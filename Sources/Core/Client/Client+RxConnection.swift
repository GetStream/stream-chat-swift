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
                .do(onNext: { self.logger?.log("📱 App state \($0)") })
                .startWith(app.applicationState)
            
            let onTokenChange = rx.onTokenChange.startWith(token)
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
                .flatMapLatest({ _ in self.rx.onConnect.startWith(self.lastConnection) })
                .distinctUntilChanged()
                .do(onDispose: { self.disconnect() })
                .share(replay: 1)
        }
    }
}

// MARK: - Connection

extension Reactive where Base == Client {
    
    /// An observable connection.
    public var connection: Observable<Connection> { base.rxConnection }
    
    /// An observable connected event.
    public var connected: Observable<Void> { connection.filter({ $0 == .connected }).void().share(replay: 1) }
}
