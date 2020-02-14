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
import UIKit

/// The Internect connection manager.
public final class InternetConnection {
    /// A shared InternetConnection.
    public static let shared = InternetConnection()
    
    private let disposeBag = DisposeBag()
    private let restartSubject = PublishSubject<Void>()
    private lazy var reachability = Reachability(hostname: Client.shared.baseURL.wsURL.host ?? "getstream.io")
    
    public var offlineMode = false {
        didSet {
            ClientLogger.log("🕸✈️", "Offline mode is \(offlineMode ? "On" : "Off").")
            restartSubject.onNext(())
        }
    }
    
    /// Check if the Internet is available.
    public var isAvailable: Bool {
        if offlineMode {
            return false
        }
        
        let connection = reachability?.connection ?? .none
        
        if case .none  = connection {
            return false
        }
        
        return true
    }
    
    /// An observable Internet connection status.
    public private(set) lazy var isAvailableObservable: Observable<Bool> = restartSubject.asObserver()
        .startWith(())
        .observeOn(MainScheduler.instance)
        .flatMapLatest({ [unowned self] _ -> Observable<Reachability.Connection> in
            if self.offlineMode {
                return .just(.none)
            }
            
            if let reachability = self.reachability {
                return reachability.rx.reachabilityChanged
                    .map({ $0.connection })
                    .startWith(reachability.connection)
            }
            
            return .empty()
        })
        .map({ $0 != .none })
        .distinctUntilChanged()
        .do(onNext: {
            if Client.shared.logOptions.isEnabled {
                ClientLogger.log("🕸", ($0 ? "Available 🙋‍♂️" : "Not Available 🤷‍♂️"))
            }
        })
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
                    
                    if Client.shared.logOptions.isEnabled {
                        ClientLogger.log("🕸", "Notifying started 🏃‍♂️")
                    }
                } catch {
                    if Client.shared.logOptions.isEnabled {
                        let message = "InternetConnection tried to start notifying when app state became active.\n\(error)"
                        ClientLogger.log("🕸", message)
                    }
                }
            })
            .disposed(by: disposeBag)
    }
    
    /// Stop observing the Internet connection.
    public func stopObserving() {
        reachability?.stopNotifier()
        
        if Client.shared.logOptions.isEnabled {
            ClientLogger.log("🕸", "Notifying stopped 🚶‍♂️")
        }
    }
}
