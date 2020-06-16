//
// HealthCheckFilterMiddleware.swift
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation

/// Ignores HealthCheck events
struct HealthCheckFilter: EventMiddleware {
    func handle(event: Event, completion next: @escaping (Event?) -> Void) {
        if event is HealthCheck {
            next(nil)
        } else {
            next(event)
        }
    }
}
