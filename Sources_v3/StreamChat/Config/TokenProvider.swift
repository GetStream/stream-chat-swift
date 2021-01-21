//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation

public typealias TokenProvider = _TokenProvider<NoExtraData>

/// The type designed to provider a `Token` to the `ChatClient` when it asks for it.
public struct _TokenProvider<ExtraData: ExtraDataTypes> {
    let getToken: (_ client: _ChatClient<ExtraData>, _ completion: @escaping (Result<Token, Error>) -> Void) -> Void
}

public extension _TokenProvider {
    /// The provider that can be used when user is unknown.
    static var anonymous: Self {
        .static(.anonymous)
    }

    /// The provider that can be used during the development. It's handy since doesn't require a token.
    /// - Parameter userId: The user identifier.
    /// - Returns: The new `TokenProvider` instance.
    static func development(userId: UserId) -> Self {
        .static(.development(userId: userId))
    }

    /// The provider which can be used to provide a static token known on the client-side which doesn't expire.
    /// - Parameter token: The token to be returned by the token provider.
    /// - Returns: The new `TokenProvider` instance.
    static func `static`(_ token: Token) -> Self {
        .init {
            $1(.success(token))
        }
    }

    /// The provider which designed to be used for guest users.
    /// - Parameters:
    ///   - userId: The identifier a guest user will be created OR updated with if it exists.
    ///   - name: The name a guest user will be created OR updated with if it exists.
    ///   - imageURL: The avatar URL a guest user will be created OR updated with if it exists.
    ///   - extraData: The extra data a guest user will be created OR updated with if it exists.
    /// - Returns: The new `TokenProvider` instance.
    static func guest(
        userId: UserId,
        name: String? = nil,
        imageURL: URL? = nil,
        extraData: ExtraData.User = .defaultValue
    ) -> Self {
        .init { client, completion in
            client.apiClient.request(
                endpoint: .guestUserToken(userId: userId, name: name, imageURL: imageURL, extraData: extraData)
            ) {
                switch $0 {
                case let .success(payload):
                    let token = payload.token
                    completion(.success(token))
                case let .failure(error):
                    log.error(error)
                    completion(.failure(error))
                }
            }
        }
    }

    /// The token provider designed to be used when a token is dynamic (e.g. can change OR expire).
    /// - Parameter handler: The closure which should get the token and pass it to the `completion`.
    /// - Returns: The new `TokenProvider` instance.
    static func closure(
        _ handler: @escaping (_ client: _ChatClient<ExtraData>, _ completion: @escaping (Result<Token, Error>) -> Void) -> Void
    ) -> Self {
        .init(getToken: handler)
    }
}
