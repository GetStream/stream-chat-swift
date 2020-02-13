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
            let connection = rx.onConnect.filter { _ in !self.isExpiredTokenInProgress }
            let appState = UIApplication.shared.rx.applicationState.filter({ $0 != .inactive })
            let isInternetAvailable: Observable<Bool> = InternetConnection.shared.rx.isAvailable
            
            let environment = Observable.combineLatest(appState, isInternetAvailable)
                .distinctUntilChanged({ $0.0 == $1.0 && $0.1 == $1.1 })
                .observeOn(MainScheduler.instance)
                .do(onNext: { appState, isInternetAvailable in
                    self.logger?.log("Environment: appState: \(appState), Internet: \(isInternetAvailable ? "yes" : "no")")
                    self.handleConnection(appState: appState, isInternetAvailable: isInternetAvailable)
                })
            
            return Observable.combineLatest(connection, environment)
                .map { connection, _ in connection }
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
}
