//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

/// A test middleware that can be initiated with a closure
final class EventMiddleware_Mock: EventMiddleware {
    var closure: (Event, DatabaseSession) -> Event?
    
    init(closure: @escaping (Event, DatabaseSession) -> Event? = { event, _ in event }) {
        self.closure = closure
    }
    
    func handle(event: Event, session: DatabaseSession) -> Event? {
        closure(event, session)
    }
}
