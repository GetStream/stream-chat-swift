//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation

final class TypingEventObserver: EventObserver {
    init(
        notificationCenter: NotificationCenter,
        filter: @escaping (TypingEvent) -> Bool,
        callback: @escaping (TypingEvent) -> Void
    ) {
        super.init(notificationCenter: notificationCenter, transform: { $0 as? TypingEvent }) {
            guard filter($0) else { return }
            callback($0)
        }
    }
}

extension TypingEventObserver {
    convenience init(notificationCenter: NotificationCenter, callback: @escaping (TypingEvent) -> Void) {
        self.init(
            notificationCenter: notificationCenter,
            filter: { _ in true },
            callback: callback
        )
    }

    convenience init(notificationCenter: NotificationCenter, cid: ChannelId, callback: @escaping (TypingEvent) -> Void) {
        self.init(
            notificationCenter: notificationCenter,
            filter: { $0.cid == cid },
            callback: callback
        )
    }
}
