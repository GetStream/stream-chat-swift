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
    private lazy var reachability = Reachability(hostname: Client.shared.baseURL.url(.webSocket).host ?? "getstream.io")
    
    /// Check if the Internet is available.
    public var isAvailable: Bool {
        let connection = reachability?.connection ?? .none
        
        if case .none  = connection {
            return false
        }
        
        return true
    }
    
    /// An observable Internet connection status.
    public private(set) lazy var isAvailableObservable: Observable<Bool> = (reachability?.rx.reachabilityChanged
        .subscribeOn(MainScheduler.instance)
        .map {
            if case .none = $0.connection {
                return false
            }
            
            return true
        }
        .startWith(isAvailable)
        .distinctUntilChanged()
        .do(onNext: { ClientLogger.log("🕸", $0 ? "Available 🙋‍♂️" : "Not Available 🤷‍♂️") })
        .share(replay: 1, scope: .forever)) ?? .empty()
    
    /// Init InternetConnection.
    public init() {
        DispatchQueue.main.async {
            UIApplication.shared.rx.appState
                .subscribe(onNext: { [weak self] state in
                    if state == .active {
                        try? self?.reachability?.startNotifier()
                        ClientLogger.log("🕸", "Notifying started 🏃‍♂️")
                    }
                })
                .disposed(by: self.disposeBag)
        }
    }
    
    /// Stop observing the Internet connection.
    public func stopObserving() {
        reachability?.stopNotifier()
        ClientLogger.log("🕸", "Notifying stopped 🚶‍♂️")
    }
}
