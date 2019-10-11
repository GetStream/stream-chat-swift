//
//  InternetConnection.swift
//  StreamChatCore
//
//  Created by Alexey Bukhtin on 02/07/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import Foundation
import Reachability
import RxSwift
import RxAppState

/// The Internect connection manager.
public final class InternetConnection {
    /// A shared InternetConnection.
    public static let shared = InternetConnection()
    
    private let disposeBag = DisposeBag()
    private lazy var reachability = Reachability(hostname: Client.shared.baseURL.wsURL.host ?? "getstream.io")
    
    /// Check if the Internet is available.
    public var isAvailable: Bool {
        let connection = reachability?.connection ?? .none
        
        if case .none  = connection {
            return false
        }
        
        return true
    }
    
    /// An observable Internet connection status.
    public private(set) lazy var isAvailableObservable: Observable<Bool> = Observable.just(Void())
        .observeOn(MainScheduler.instance)
        .flatMapLatest { [weak self] _ -> Observable<Reachability.Connection> in
            if let reachability = self?.reachability {
                return reachability.rx.reachabilityChanged
                    .map({ $0.connection })
                    .startWith(reachability.connection)
            }
            
            return .empty()
        }
        .map {
            if case .none = $0 {
                return false
            }
            
            return true
        }
        .distinctUntilChanged()
        .do(onNext: { ClientLogger.log("🕸", $0 ? "Available 🙋‍♂️" : "Not Available 🤷‍♂️") })
        .share(replay: 1, scope: .forever)
    
    /// Init InternetConnection.
    public init() {
        if !isTests() {
            DispatchQueue.main.async { self.startObserving() }
        }
    }
    
    private func startObserving() {
        UIApplication.shared.rx.appState
            .startWith(UIApplication.shared.appState)
            .filter { $0 == .active }
            .subscribe(onNext: { [unowned self] _ in
                do {
                    try self.reachability?.startNotifier()
                    ClientLogger.log("🕸", "Notifying started 🏃‍♂️")
                } catch {
                    let message = "InternetConnection tried to start notifying when app state became active."
                    ClientLogger.log("🕸", error, message: message)
                }
            })
            .disposed(by: disposeBag)
    }
    
    /// Stop observing the Internet connection.
    public func stopObserving() {
        reachability?.stopNotifier()
        ClientLogger.log("🕸", "Notifying stopped 🚶‍♂️")
    }
}
