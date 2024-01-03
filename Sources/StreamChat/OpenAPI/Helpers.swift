//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

func execute<Response>(
    action: @escaping () async throws -> Response,
    completion: @escaping (Result<Response, Error>) -> Void
) {
    Task {
        do {
            let response = try await action()
            completion(.success(response))
        } catch {
            completion(.failure(error))
        }
    }
}
