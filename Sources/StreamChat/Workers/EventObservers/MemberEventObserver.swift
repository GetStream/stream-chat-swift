//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

final class MemberEventObserver: EventObserver {
    init(
        notificationCenter: NotificationCenter,
        filter: @escaping @Sendable(MemberEvent) -> Bool,
        callback: @escaping @Sendable(MemberEvent) -> Void
    ) {
        super.init(notificationCenter: notificationCenter, transform: { $0 as? MemberEvent }) {
            guard filter($0) else { return }
            callback($0)
        }
    }
}

extension MemberEventObserver {
    convenience init(notificationCenter: NotificationCenter, callback: @escaping @Sendable(MemberEvent) -> Void) {
        self.init(
            notificationCenter: notificationCenter,
            filter: { _ in true },
            callback: callback
        )
    }

    convenience init(notificationCenter: NotificationCenter, cid: ChannelId, callback: @escaping @Sendable(MemberEvent) -> Void) {
        self.init(
            notificationCenter: notificationCenter,
            filter: { $0.cid == cid },
            callback: callback
        )
    }
}
