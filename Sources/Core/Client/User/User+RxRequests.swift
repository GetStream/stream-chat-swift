//
//  User+RxRequests.swift
//  StreamChatClient
//
//  Created by Alexey Bukhtin on 10/02/2020.
//  Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChatClient
import RxSwift

// MARK: Channel Requests

extension User: ReactiveCompatible {}

public extension Reactive where Base == User {
    
    /// Update or create the user.
    func update() -> Observable<User> {
        Client.shared.rx.update(user: base)
    }
    
    /// Mute the user.
    func mute() -> Observable<MutedUsersResponse> {
        Client.shared.rx.mute(user: base)
    }
    
    /// Unmute the user.
    func unmute() -> Observable<EmptyData> {
        Client.shared.rx.unmute(user: base)
    }
    
    /// Flag the user.
    func flag() -> Observable<FlagUserResponse> {
        Client.shared.rx.flag(user: base)
    }
    
    /// Unflag the user.
    func unflag() -> Observable<FlagUserResponse> {
        Client.shared.rx.unflag(user: base)
    }
}
