//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation

/// An object used to pre-process incoming `Event`.
protocol EventMiddleware {
    /// Process the incoming event and call completion when done. `completion` can be called multiple times if
    /// the functionality requires it.
    ///
    /// - Parameters:
    ///   - event: The incoming `Event`.
    ///   - completion: Called when the event processing is done. If called with `nil`, no middlewares down the
    ///   chain are called.
    func handle(event: Event, completion: @escaping (Event?) -> Void)
}

extension Array where Element == EventMiddleware {
    /// Evaluates an array of `EventMiddleware`s in the order they're specified in the array. It's not guaranteed that
    /// all middlewares are called. If a middleware returns `nil`, no middlewares down in the chain are called.
    ///
    /// - Parameters:
    ///   - event: The event to be pre-processed.
    ///   - completion: Called when the event pre-processing is finished. Be aware that `completion` can be called
    ///   multiple times for a single event.
    func process(event: Event, completion: @escaping (Event?) -> Void) {
        guard isEmpty == false else { completion(event); return }
        evaluate(idx: startIndex, event: event, completion: completion)
    }
    
    private func evaluate(idx: Int, event: Event, completion: @escaping (Event?) -> Void) {
        let middleware = self[idx]
        middleware.handle(event: event) { event in
            let nextIdx = idx + 1
            if nextIdx == self.endIndex {
                completion(event)
                
            } else if let event = event {
                self.evaluate(idx: nextIdx, event: event, completion: completion)
                
            } else {
                completion(nil)
            }
        }
    }
}
