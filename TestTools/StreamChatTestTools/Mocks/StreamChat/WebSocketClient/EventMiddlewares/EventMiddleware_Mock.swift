//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

/// A test middleware that can be initiated with a closure
final class EventMiddleware_Mock: EventMiddleware {
    var closure: (Event, DatabaseSession) -> Event?
    var wsEventClosure: ((Event, WSEvent, DatabaseSession) -> Event?)?
    var handledWSEvents: [WSEvent] = []

    init(closure: @escaping (Event, DatabaseSession) -> Event? = { event, _ in event }) {
        self.closure = closure
    }

    func handle(event: Event, session: DatabaseSession) -> Event? {
        closure(event, session)
    }

    func handle(event: Event, wsEvent: WSEvent, session: DatabaseSession) -> Event? {
        handledWSEvents.append(wsEvent)
        if let wsEventClosure {
            return wsEventClosure(event, wsEvent, session)
        }
        return closure(event, session)
    }
}
