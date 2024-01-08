//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

// A concrete `ConnectionDetailsProviderDelegate` implementation allowing capturing the delegate calls
final class ConnectionDetailsProviderDelegate_Spy: ConnectionDetailsProviderDelegate, Spy {
    var recordedFunctions: [String] = []

    var provideTokenResult: Result<Token, Error>?
    @Atomic var tokenWaiters: [String: (Token?) -> Void] = [:]

    var provideConnectionIdResult: Result<ConnectionId, Error>?
    @Atomic var connectionWaiters: [String: (ConnectionId?) -> Void] = [:]

    func clear() {
        recordedFunctions.removeAll()
        tokenWaiters.removeAll()
    }

    func provideConnectionId(timeout: TimeInterval, completion: @escaping (Result<StreamChat.ConnectionId, Error>) -> Void) {
        let waiterToken = String.newUniqueId
        let valueCompletion: (StreamChat.ConnectionId?) -> Void = { value in
            completion(value.map { .success($0) } ?? .failure(ClientError.MissingConnectionId()))
        }
        _connectionWaiters.mutate {
            $0[waiterToken] = valueCompletion
        }

        if let connectionIdResult = provideConnectionIdResult {
            completion(connectionIdResult)
        }
    }

    func provideToken(timeout: TimeInterval, completion: @escaping (Result<StreamChat.Token, Error>) -> Void) {
        let waiterToken = String.newUniqueId
        let valueCompletion: (StreamChat.Token?) -> Void = { value in
            completion(value.map { .success($0) } ?? .failure(ClientError.MissingToken()))
        }
        _tokenWaiters.mutate {
            $0[waiterToken] = valueCompletion
        }

        if let tokenResult = provideTokenResult {
            completion(tokenResult)
        }
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
