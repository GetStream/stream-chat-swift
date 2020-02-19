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
    fileprivate static var rxConnectionKey: UInt8 = 0
}

// MARK: - Connection

extension Reactive where Base == Client {
    /// An observable connection.
    public var connection: Observable<Connection> {
        associated(to: base, key: &Client.rxConnectionKey) { [unowned base] in
            let connection = base.rx.onConnect.filter { _ in !base.isExpiredTokenInProgress }
            let appState = UIApplication.shared.rx.applicationState.filter({ $0 != .inactive })
            let isInternetAvailable: Observable<Bool> = InternetConnection.shared.rx.isAvailable
            
            let environment = Observable.combineLatest(appState, isInternetAvailable)
                .distinctUntilChanged({ $0.0 == $1.0 && $0.1 == $1.1 })
                .observeOn(MainScheduler.instance)
                .do(onNext: { appState, isInternetAvailable in
                    base.logger?.log("Environment: appState: \(appState), Internet: \(isInternetAvailable ? "yes" : "no")")
                    base.handleConnection(appState: appState, isInternetAvailable: isInternetAvailable)
                })
            
            return Observable.combineLatest(connection, environment)
                .map { connection, _ in connection }
                .distinctUntilChanged()
                .do(onDispose: { base.disconnect() })
                .share(replay: 1)
        }
    }
}
