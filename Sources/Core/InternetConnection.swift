//
//  InternetConnection.swift
//  StreamChatCore
//
//  Created by Alexey Bukhtin on 02/07/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import UIKit
import StreamChatClient
import Reachability
import RxSwift

/// The Internect connection manager.
public final class InternetConnection {
    /// A shared Internet Connection.
    public static let shared = InternetConnection()
    
    private let disposeBag = DisposeBag()
    private let restartSubject = PublishSubject<Void>()
    private lazy var reachability = Reachability(hostname: Client.shared.baseURL.wsURL.host ?? "getstream.io")
    
    /// Forces to offline mode.
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
        .map({
            if case .none = $0 {
                return false
            }
            
            return true
        })
        .distinctUntilChanged()
        .do(onNext: { [unowned self] isAvailable in self.log(isAvailable ? "Available 🙋‍♂️" : "Not Available 🤷‍♂️") })
        .share(replay: 1, scope: .forever)
    
    /// Init InternetConnection.
    public init() {
        if !isTestsEnvironment() {
            DispatchQueue.main.async { self.startObserving() }
        }
    }
    
    private func startObserving() {
        UIApplication.shared.rx.applicationState
            .filter { $0 == .active }
            .subscribe(onNext: { [unowned self] _ in
                do {
                    try self.reachability?.startNotifier()
                    self.log("Notifying started 🏃‍♂️")
                } catch {
                    self.log("InternetConnection tried to start notifying when app state became active.\n\(error)")
                }
            })
            .disposed(by: disposeBag)
    }
    
    /// Stop observing the Internet connection.
    public func stopObserving() {
        reachability?.stopNotifier()
        log("Notifying stopped 🚶‍♂️")
    }
    
    // MARK: Logs
    
    private func log(_ message: String) {
        if !Client.shared.logOptions.isEmpty {
            ClientLogger.log("🕸", message)
        }
    }
}
