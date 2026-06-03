//
// Copyright © 2026 Stream.io Inc. All rights reserved.
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

    /// Processes an incoming event with its original OpenAPI websocket event.
    ///
    /// - Parameters:
    ///   - event: The unwrapped incoming `Event`.
    ///   - wsEvent: The original OpenAPI websocket event.
    ///   - session: The database session the middleware works with.
    /// - Returns: The original `event` passed via params OR `nil` if the incoming event was consumed by the middleware.
    func handle(event: Event, wsEvent: WSEvent, session: DatabaseSession) -> Event?
}

extension EventMiddleware {
    func handle(event: Event, wsEvent: WSEvent, session: DatabaseSession) -> Event? {
        handle(event: event, session: session)
    }
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
        process(event: event, wsEvent: nil, session: session)
    }

    /// Evaluates an array of `EventMiddleware`s with the original WSEvent when available.
    ///
    /// - Parameters:
    ///   - event: The event to be pre-processed.
    ///   - wsEvent: The source OpenAPI websocket event, if the event came from websocket decoding.
    ///   - session: The database session used when evaluating the middlewares.
    /// - Returns: The processed event. It will return `nil` if the event was consumed by some middleware.
    func process(event: Event, wsEvent: WSEvent?, session: DatabaseSession) -> Event? {
        var output: Event? = event

        for middleware in self {
            guard let input = output else { break }
            if let wsEvent {
                output = middleware.handle(event: input, wsEvent: wsEvent, session: session)
            } else {
                output = middleware.handle(event: input, session: session)
            }
        }

        return output
    }
}
