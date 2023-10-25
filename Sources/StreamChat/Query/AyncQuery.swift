//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation

public typealias AsyncQuery<Query> = AsyncResult<ChannelQuery, Error>

public struct AsyncResult<Success, Failure: Error> {
    let execute: (_ completion: @escaping (Result<Success, Failure>) -> Void) -> Void

    public init(execute: @escaping (_ completion: @escaping (Result<Success, Failure>) -> Void) -> Void) {
        self.execute = execute
    }
}

extension AsyncQuery {
    /// Dummy id to be provided when initialising a controller with an async query.
    /// Since our controllers require passing a query when initialising them, we need to pass a dummy id.
    var id: String {
        "async-dummy"
    }

    /// Dummy cid to be provided when initialising a channel controller with an async query.
    /// Since our controllers require passing a query when initialising them, we need to pass a dummy id.
    var dummyCid: ChannelId {
        .init(type: .custom("async"), id: "dummy")
    }
}
