//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation

/// An object used to pre-process incoming `Event`.
protocol EventMiddleware {
    /// Processes the incoming event and returns `nil` if it was consumed (no further processing is needed).
    ///
    /// - Parameters:
    ///   - event: The incoming `Event`.
    ///   - session: The database session the middleware works with.
    /// - Returns: The original `event` passed via params OR `nil` if the incoming event was consumed by the middleware.
    func handle(event: Event, session: DatabaseSession) -> Event?
}

extension Array where Element == EventMiddleware {
    /// Evaluates an array of `EventMiddleware`s in the order they're specified in the array. It's not guaranteed that
    /// all middlewares are called. If a middleware returns `nil`, no middlewares down in the chain are called.
    ///
    /// - Parameters:
    ///   - event: The event to be pre-processed.
    ///   - session: The database session used when evaluating the middlewares.
    /// - Returns: The processed event. It will return `nil` if the event was consumed by some middleware.
    func process(event: Event, session: DatabaseSession) -> Event? {
        var output: Event? = event

        for middleware in self {
            guard let input = output else { break }
            output = middleware.handle(event: input, session: session)
        }

        return output
    }
}
