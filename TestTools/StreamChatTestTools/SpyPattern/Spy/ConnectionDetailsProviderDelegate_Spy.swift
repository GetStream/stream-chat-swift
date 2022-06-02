//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

// A concrete `ConnectionDetailsProviderDelegate` implementation allowing capturing the delegate calls
final class ConnectionDetailsProviderDelegate_Spy: ConnectionDetailsProviderDelegate, Spy {
    var recordedFunctions: [String] = []

    @Atomic var tokenResult: Result<Token, Error>?
    @Atomic var tokenWaiters: [WaiterToken: TokenWaiter] = [:]

    @Atomic var connectionIdResult: Result<ConnectionId, Error>?
    @Atomic var connectionWaiters: [WaiterToken: ConnectionIdWaiter] = [:]

    func clear() {
        tokenResult = nil
        tokenWaiters.removeAll()
        
        connectionIdResult = nil
        connectionWaiters.removeAll()
        
        recordedFunctions.removeAll()
    }

    func provideConnectionId(completion: @escaping ConnectionIdWaiter) -> WaiterToken {
        let waiterToken = String.newUniqueId

        if let result = connectionIdResult {
            completion(result)
        } else {
            _connectionWaiters.mutate {
                $0[waiterToken] = completion
            }
        }
        
        return waiterToken
    }

    func provideToken(completion: @escaping TokenWaiter) -> WaiterToken {
        let waiterToken = String.newUniqueId
        
        if let result = tokenResult {
            completion(result)
        } else {
            _tokenWaiters.mutate {
                $0[waiterToken] = completion
            }
        }
        
        return waiterToken
    }

    func invalidateTokenWaiter(_ waiter: WaiterToken) {}

    func invalidateConnectionIdWaiter(_ waiter: WaiterToken) {}

    func completeConnectionIdWaiters(passing result: Result<ConnectionId, Error>) {
        _connectionWaiters.mutate { waiters in
            waiters.forEach { $0.value(result) }
            waiters.removeAll()
        }
    }

    func completeTokenWaiters(passing result: Result<Token, Error>) {
        _tokenWaiters.mutate { waiters in
            waiters.forEach { $0.value(result) }
            waiters.removeAll()
        }
    }
}
