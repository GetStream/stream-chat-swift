//
//  InternetConnection.swift
//  StreamChat
//
//  Created by Alexey Bukhtin on 02/07/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import Foundation
import Reachability
import RxSwift
import RxReachability
import RxAppState

final class InternetConnection {
    static let shared = InternetConnection()
    
    private let disposeBag = DisposeBag()
    private lazy var reachability = Reachability(hostname: Client.shared.baseURL.url(.webSocket).host ?? "getstream.io")
    
    var isAvailable: Bool {
        let connection = reachability?.connection ?? .none
        
        if case .none  = connection {
            return false
        }
        
        return true
    }
    
    lazy var isAvailableObservable: Observable<Bool> = (reachability?.rx.reachabilityChanged
        .subscribeOn(MainScheduler.instance)
        .map {
            if case .none = $0.connection {
                return false
            }
            
            return true
        }
        .startWith(isAvailable)
        .distinctUntilChanged()
        .do(onNext: { ClientLogger.logger("🕸", "", $0 ? "Available 🙋‍♂️" : "Not Available 🤷‍♂️") })
        .share(replay: 1, scope: .forever)) ?? .empty()
    
    init() {
        UIApplication.shared.rx.appState
            .subscribeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] state in
                if state == .active {
                    try? self?.reachability?.startNotifier()
                    ClientLogger.logger("🕸", "", "Notifying started 🏃‍♂️")
                }
            })
            .disposed(by: disposeBag)
    }
    
    func stopObserving() {
        reachability?.stopNotifier()
        ClientLogger.logger("🕸", "", "Notifying stopped 🚶‍♂️")
    }
}
