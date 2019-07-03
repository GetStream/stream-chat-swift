//
//  Reachability.swift
//  StreamChat
//
//  Created by Alexey Bukhtin on 02/07/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import Foundation
import Reachability
import RxSwift
import RxReachability

final class InternetConnection {
    static let shared = InternetConnection()
    
    fileprivate lazy var reachability = Reachability(hostname: Client.shared.baseURL.url(.webSocket).host ?? "getstream.io")
    
    var isAvailable: Bool {
        let connection = reachability?.connection ?? .none
        
        if case .none  = connection {
            return false
        }
        
        return true
    }
    
    lazy var isAvailableObservable: Observable<Bool> = (reachability?.rx.reachabilityChanged
        .subscribeOn(MainScheduler.instance)
        .do(
            onSubscribe: { [weak self] in
                try? self?.reachability?.startNotifier()
                ClientLogger.logger("🕸", "", "Notifying started 🏃‍♂️")    
            },
            onDispose: { [weak self] in
                self?.reachability?.stopNotifier()
                ClientLogger.logger("🕸", "", "Notifying stopped 🚶‍♂️")
        })
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
}
