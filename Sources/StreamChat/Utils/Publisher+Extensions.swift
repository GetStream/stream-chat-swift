//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Combine

extension Publisher {
    /// A helper function which attaches the provided object to the publisher chain and keeps it alive as long
    /// as the publisher chain is alive.
    func keepAlive(_ object: AnyObject) -> AnyPublisher<Output, Failure> {
        map {
            _ = object
            return $0
        }.eraseToAnyPublisher()
    }
}
