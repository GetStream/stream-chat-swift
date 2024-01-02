//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

// A concrete `EventsControllerDelegate` implementation allowing capturing the delegate calls
final class EventsController_Delegate: QueueAwareDelegate, EventsControllerDelegate {
    @Atomic var events: [Event] = []

    func eventsController(_ controller: EventsController, didReceiveEvent event: Event) {
        events.append(event)
        validateQueue()
    }
}
