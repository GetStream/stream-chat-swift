//
//  Client+RxConnection.swift
//  StreamChatCore
//
//  Created by Alexey Bukhtin on 09/01/2020.
//  Copyright © 2020 Stream.io Inc. All rights reserved.
//

import UIKit
import RxSwift

// MARK: Connection

extension Reactive where Base == Client {
    
    /// An observable connection.
    public var connection: Observable<WebSocket.Connection> {
        return base.rxConnection
    }
    
    func createConnection() -> Observable<WebSocket.Connection> {
        if let token = base.token, let error = base.checkUserAndToken(token) {
            return .error(error)
        }
        
        let app = UIApplication.shared
        
        let appState = isTestsEnvironment()
            ? .just(.active)
            : app.rx.appState
                .filter { $0 != .inactive }
                .distinctUntilChanged()
                .startWith(app.appState)
                .do(onNext: { state in
                    if Client.shared.logOptions.isEnabled {
                        ClientLogger.log("📱", "App state \(state)")
                    }
                })
        
        let internetIsAvailable: Observable<Bool> = isTestsEnvironment()
            ? .just(true)
            : InternetConnection.shared.isAvailableObservable
        
        let webSocketResponse = internetIsAvailable
            .filter({ $0 })
            .flatMapLatest { [unowned base]  _ in base.tokenSubject.asObserver() }
            .distinctUntilChanged()
            .map { $0?.isValidToken() ?? false }
            .observeOn(MainScheduler.instance)
            .flatMapLatest({ [unowned base] isTokenValid -> Observable<WebSocketEvent> in
                if isTokenValid {
                    base.webSocket.connect()
                    return base.webSocket.webSocket.rx.response
                }
                
                return .just(.disconnected(nil))
            })
            .do(onDispose: { [unowned base] in base.webSocket.disconnect() })
        
        return Observable.combineLatest(appState, internetIsAvailable, webSocketResponse)
            .compactMap { [unowned base] in base.webSocket.parseConnection(appState: $0, isInternetAvailable: $1, event: $2) }
            .distinctUntilChanged()
            .share(replay: 1)
    }
    
    func connectedRequest<T: Decodable>(_ endpoint: Endpoint) -> Observable<T> {
        let request: Observable<T> = self.request(endpoint: endpoint)
        return connectedRequest(request)
    }
    
    func connectedRequest<T>(_ request: Observable<T>) -> Observable<T> {
        return base.webSocket.isConnected
            ? request
            : connection.connected().take(1).flatMapLatest { request }
    }
}
