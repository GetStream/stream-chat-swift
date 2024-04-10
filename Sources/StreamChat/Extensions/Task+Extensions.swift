//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

@available(iOS 13.0, *)
extension Task {
    @discardableResult static func mainActor(operation: @escaping () async throws -> Success) -> Task<Success, Failure> where Failure == any Error {
        Task { @MainActor in
            try await operation()
        }
    }
}
