//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

/// A test middleware that can be initiated with a closure
final class EventMiddleware_Mock: EventMiddleware {
    var closure: (Event, DatabaseSession) -> Event?
    var wsEventClosure: ((Event, WSEvent, DatabaseSession) -> Event?)?
    var handledWSEvents = [WSEvent]()

    init(
        closure: @escaping (Event, DatabaseSession) -> Event? = { event, _ in event },
        wsEventClosure: ((Event, WSEvent, DatabaseSession) -> Event?)? = nil
    ) {
        self.closure = closure
        self.wsEventClosure = wsEventClosure
    }

    func handle(event: Event, session: DatabaseSession) -> Event? {
        closure(event, session)
    }

    func handle(event: Event, wsEvent: WSEvent, session: DatabaseSession) -> Event? {
        handledWSEvents.append(wsEvent)
        return wsEventClosure?(event, wsEvent, session) ?? closure(event, session)
    }
}
