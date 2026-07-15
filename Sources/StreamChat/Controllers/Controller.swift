//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// A protocol to which all controllers conform to.
///
/// This protocol is not meant to be adopted by your custom types.
///
public protocol Controller {}

extension Controller {
    /// A helper function to ensure the callback is performed on the callback queue.
    func callback(_ action: @escaping @MainActor () -> Void) {
        let wrapped: @MainActor () -> Void = {
            // Reads performed while a controller callback runs (e.g. an action completion) should
            // reflect the write that triggered the callback, so we mark this as a read-your-writes
            // context. Delegate callbacks opt back out (see `delegateCallback`) because they already
            // run after the observer's cache has been refreshed.
            ControllerReadContext.beginReadYourWrites()
            defer { ControllerReadContext.endReadYourWrites() }
            action()
        }
        if Thread.current.isMainThread {
            MainActor.assumeIsolated {
                wrapped()
            }
        } else {
            DispatchQueue.main.async {
                wrapped()
            }
        }
    }
}

/// Tracks, per-thread, whether reads should prefer read-your-writes consistency over a fast,
/// non-blocking (eventually-consistent) read.
///
/// Database observers consult this to decide whether to serve `items`/`item` from their in-memory
/// cache (non-blocking, used on hot paths such as list scrolling) or to flush pending changes first
/// (blocking, used right after a write so callers observe their own mutation).
enum ControllerReadContext {
    private static let depthKey = "io.getstream.controller.readYourWritesDepth"

    /// Whether the current thread is executing inside a read-your-writes context.
    static var prefersReadYourWrites: Bool {
        (Thread.current.threadDictionary[depthKey] as? Int ?? 0) > 0
    }

    static func beginReadYourWrites() {
        let depth = Thread.current.threadDictionary[depthKey] as? Int ?? 0
        Thread.current.threadDictionary[depthKey] = depth + 1
    }

    static func endReadYourWrites() {
        let depth = Thread.current.threadDictionary[depthKey] as? Int ?? 0
        Thread.current.threadDictionary[depthKey] = max(0, depth - 1)
    }

    /// Runs `body` inside a read-your-writes context, restoring the previous state afterwards.
    static func withReadYourWrites<T>(_ body: () throws -> T) rethrows -> T {
        beginReadYourWrites()
        defer { endReadYourWrites() }
        return try body()
    }

    /// Runs `body` with the read-your-writes context temporarily disabled, restoring it afterwards.
    /// Used for delegate callbacks, whose reads should stay on the fast non-blocking path.
    static func withoutReadYourWrites<T>(_ body: () -> T) -> T {
        let depth = Thread.current.threadDictionary[depthKey] as? Int ?? 0
        Thread.current.threadDictionary[depthKey] = 0
        defer { Thread.current.threadDictionary[depthKey] = depth }
        return body()
    }
}
