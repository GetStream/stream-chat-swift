//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import CoreData
import StreamChat

@available(iOS 13.0, *)
extension DatabaseContainer {
    func write(_ actions: @escaping (DatabaseSession) throws -> Void) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            write(actions) { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
    }
    
    func read<T>(_ actions: @escaping (NSManagedObjectContext) throws -> T) async throws -> T {
        let context = stateLayerContext
        return try await withCheckedThrowingContinuation { continuation in
            context.perform {
                do {
                    let results = try actions(context)
                    if context.hasChanges {
                        assertionFailure("State layer context is read only, but calling actions() created changes")
                    }
                    continuation.resume(returning: results)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}
