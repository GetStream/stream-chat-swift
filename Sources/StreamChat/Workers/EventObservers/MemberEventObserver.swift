//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation

final class MemberEventObserver: EventObserver {
    init(
        notificationCenter: NotificationCenter,
        filter: @escaping (MemberEvent) -> Bool,
        callback: @escaping (MemberEvent) -> Void
    ) {
        super.init(notificationCenter: notificationCenter, transform: { $0 as? MemberEvent }) {
            guard filter($0) else { return }
            callback($0)
        }
    }
}

extension MemberEventObserver {
    convenience init(notificationCenter: NotificationCenter, callback: @escaping (MemberEvent) -> Void) {
        self.init(
            notificationCenter: notificationCenter,
            filter: { _ in true },
            callback: callback
        )
    }

    convenience init(notificationCenter: NotificationCenter, cid: ChannelId, callback: @escaping (MemberEvent) -> Void) {
        self.init(
            notificationCenter: notificationCenter,
            filter: { $0.cid == cid },
            callback: callback
        )
    }
}
