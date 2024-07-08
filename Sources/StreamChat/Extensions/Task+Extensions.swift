//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

extension Task {
    @discardableResult static func mainActor(priority: TaskPriority? = nil, operation: @escaping @MainActor() async throws -> Success) -> Task<Success, Failure> where Failure == any Error {
        Task(priority: priority) { @MainActor in
            try await operation()
        }
    }
}
