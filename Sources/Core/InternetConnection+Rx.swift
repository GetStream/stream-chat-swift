//
//  InternetConnection+Rx.swift
//  StreamChatCore
//
//  Created by Alexey Bukhtin on 13/02/2020.
//  Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation
import Reachability
import RxSwift

extension InternetConnection: ReactiveCompatible {
    fileprivate static var rxIsAvailableKey: UInt8 = 0
}

extension Reactive where Base == InternetConnection {
    
    /// An observable Internet connection availability.
    public var isAvailable: Observable<Bool> {
        associated(to: base, key: &InternetConnection.rxIsAvailableKey) { [unowned base] in
            Observable.just(())
                .observeOn(MainScheduler.instance)
                .flatMap({
                    Observable.combineLatest(base.offlineModeSubject,
                                             UIApplication.shared.rx.applicationState
                                                .filter { $0 == .active }
                                                .do(onNext: {
                                                    do {
                                                        try base.reachability?.startNotifier()
                                                        base.log("Notifying started 🏃‍♂️")
                                                    } catch {
                                                        base.log("InternetConnection tried to start notifying "
                                                            + "when app state is \($0).\n\(error)")
                                                    }
                                                })
                    )
                })
                .observeOn(MainScheduler.instance)
                .flatMapLatest({ [unowned base] isOfflineMode, _ -> Observable<Reachability.Connection> in
                    if isOfflineMode {
                        base.log("✈️ Offline mode is \(isOfflineMode ? "On" : "Off").")
                        return .just(.none)
                    }
                    
                    if let reachability = base.reachability {
                        return reachability.rx.reachabilityChanged
                            .map({ $0.connection })
                            .startWith(reachability.connection)
                    }
                    
                    return .empty()
                })
                .map { $0 != .none }
                .do(onNext: { [unowned base] isAvailable in base.log(isAvailable ? "Available 🙋‍♂️" : "Not Available 🤷‍♂️") },
                    onDispose: { [unowned base] in base.stopObserving() })
                .share()
        }
    }
}
