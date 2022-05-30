//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

// A concrete `ConnectionDetailsProviderDelegate` implementation allowing capturing the delegate calls
final class ConnectionDetailsProviderDelegate_Spy: ConnectionDetailsProviderDelegate, Spy {
    var recordedFunctions: [String] = []

    @Atomic var token: Token?
    @Atomic var tokenWaiters: [String: (Token?) -> Void] = [:]

    @Atomic var connectionId: ConnectionId?
    @Atomic var connectionWaiters: [String: (ConnectionId?) -> Void] = [:]

    func clear() {
        recordedFunctions.removeAll()
        tokenWaiters.removeAll()
    }

    func provideConnectionId(completion: @escaping (ConnectionId?) -> Void) -> WaiterToken {
        let waiterToken = String.newUniqueId
        _connectionWaiters.mutate {
            $0[waiterToken] = completion
        }

        if let connectionId = connectionId {
            completion(connectionId)
        }
        return waiterToken
    }

    func provideToken(completion: @escaping (Token?) -> Void) -> WaiterToken {
        let waiterToken = String.newUniqueId
        _tokenWaiters.mutate {
            $0[waiterToken] = completion
        }

        if let token = token {
            completion(token)
        }
        return waiterToken
    }

    func invalidateTokenWaiter(_ waiter: WaiterToken) {}

    func invalidateConnectionIdWaiter(_ waiter: WaiterToken) {}

    func completeConnectionIdWaiters(passing connectionId: String?) {
        _connectionWaiters.mutate { waiters in
            waiters.forEach { $0.value(connectionId) }
            waiters.removeAll()
        }
    }

    func completeTokenWaiters(passing token: Token?) {
        _tokenWaiters.mutate { waiters in
            waiters.forEach { $0.value(token) }
            waiters.removeAll()
        }
    }
}
