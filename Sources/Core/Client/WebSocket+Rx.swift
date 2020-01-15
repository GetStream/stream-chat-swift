//
//  WebSocket+Rx.swift
//  StreamChatCore
//
//  Created by Alexey Bukhtin on 10/01/2020.
//  Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation
import Starscream
import RxSwift

extension WebSocket: ReactiveCompatible {}

extension Reactive where Base == WebSocket {
    
    /// An observable response.
    public var response: Observable<WebSocket.Response> {
        return base.rxResponse
    }
    
    func setupResponse() -> Observable<WebSocket.Response> {
        return Observable.just(())
            .observeOn(MainScheduler.instance)
            .flatMapLatest { self.base.webSocket.rx.response }
            .compactMap { self.base.parseMessage($0) }
            .do(onNext: {
                if case .notificationMutesUpdated(let user, _) = $0.event {
                    Client.shared.user = user
                }
            })
            .share()
    }
}

// MARK: - Connection

extension ObservableType where Element == WebSocket.Connection {
    
    /// A connection status handler block type.
    public typealias ConnectionStatusHandler = (_ connected: Bool) -> Void
    
    /// Observe a web socket connection and filter not connected statuses.
    /// - Parameter connectionStatusHandler: a handler to make a side effect with all web scoket connection statuses.
    /// - Returns: an empty observable.
    public func connected(_ connectionStatusHandler: ConnectionStatusHandler? = nil) -> Observable<Void> {
        return self.do(onNext: { connectionStatusHandler?($0.isConnected) })
            .filter { $0.isConnected }
            .void()
    }
}
