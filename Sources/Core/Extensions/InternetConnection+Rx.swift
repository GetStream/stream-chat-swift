//
//  InternetConnection+Rx.swift
//  StreamChatCore
//
//  Created by Alexey Bukhtin on 13/02/2020.
//  Copyright © 2020 Stream.io Inc. All rights reserved.
//

import StreamChatClient
import RxSwift
import RxCocoa
import UIKit

extension InternetConnection: ReactiveCompatible {
    fileprivate static var rxStateKey: UInt8 = 0
}

extension Reactive where Base == InternetConnection {
    
    /// An observable Internet connection state.
    public var state: Observable<InternetConnection.State> {
        NotificationCenter.default.rx.notification(.reachabilityChanged)
            .subscribeOn(MainScheduler.instance)
            .flatMap({ notification -> Observable<InternetConnection.State> in
                guard let reachability = notification.object as? Reachability else {
                    return .empty()
                }
                
                if case .none = reachability.connection {
                    return .just(.unavailable)
                }
                
                return .just(.available)
            })
            .share(replay: 1)
    }
    
    /// An observable Internet connection availability.
    public var isAvailable: Observable<Bool> {
        state.map({ $0 == .available }).share(replay: 1)
    }
}
