//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

/// The type can be used to check the events published by `NotificationCenter`
final class EventLogger {
    @Atomic var events: [Event] = []
    var equatableEvents: [EquatableEvent] { events.map(EquatableEvent.init) }
    
    init(_ notificationCenter: NotificationCenter) {
        notificationCenter.addObserver(self, selector: #selector(handleNewEvent), name: .NewEventReceived, object: nil)
    }
    
    @objc
    func handleNewEvent(_ notification: Notification) {
        events.append(notification.event!)
    }
}
