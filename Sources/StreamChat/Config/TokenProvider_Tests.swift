//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import XCTest

final class TokenProvider_Tests: StressTestCase {
    func test_anonymousProvider_propagatesToken() throws {
        // Get token from `anonymous` provider.
        let token = try await { TokenProvider.anonymous.getToken(.mock, $0) }.get()

        // Assert token is correct.
        XCTAssertEqual(token.rawValue, "")
        XCTAssertTrue(token.userId.isAnonymousUser)
    }

    func test_developmentProvider_propagatesToken() throws {
        // Create a user identifier.
        let userId: UserId = .unique

        // Get a token from `development` token provider.
        let token = try await {
            TokenProvider.development(userId: userId).getToken(.mock, $0)
        }.get()

        // Assert token is correct.
        XCTAssertEqual(token.rawValue, "development")
        XCTAssertEqual(token.userId, userId)
    }

    func test_staticProvider_propagatesToken() throws {
        // Create a token.
        let token = Token.unique(userId: .unique)

        // Get a token from `static` token provider.
        let receivedToken = try await {
            TokenProvider.static(token).getToken(.mock, $0)
        }.get()

        // Assert token is propagated.
        XCTAssertEqual(receivedToken, token)
    }

    func test_closureProvider_propagatesToken() throws {
        // Create a token.
        let token = Token.unique()

        // Get a token from `closure` token provider.
        let receivedToken = try await {
            TokenProvider
                .closure { $1(.success(token)) }
                .getToken(.mock, $0)
        }.get()

        // Assert token is propagated.
        XCTAssertEqual(receivedToken, token)
    }

    func test_closureProvider_propagatesError() throws {
        // Create an error.
        let error = TestError()

        // Get a token from `closure` token provider.
        let receivedError = try await {
            TokenProvider
                .closure { $1(.failure(error)) }
                .getToken(.mock, $0)
        }.error

        // Assert error is propagated.
        XCTAssertEqual(receivedError as! TestError, error)
    }

    func test_guestProvider_callsAPIClient_and_propagatesToken() throws {
        // Create guest user data.
        let userId: UserId = .unique
        let userName: String = .unique
        let imageURL: URL = .unique()
        let extraData: NoExtraData = .defaultValue

        // Create a client.
        let client = ChatClient.mock

        // Create a `guest` token provider.
        let tokenProvider = TokenProvider.guest(
            userId: userId,
            name: userName,
            imageURL: imageURL,
            extraData: extraData
        )

        // Get token from provider and capture the result.
        var getTokenResult: Result<Token, Error>?
        tokenProvider.getToken(client) {
            getTokenResult = $0
        }

        // Wait for the API call to guest endpoint.
        let expectedEndpoint: Endpoint<GuestUserTokenPayload<NoExtraData>> = .guestUserToken(
            userId: userId,
            name: userName,
            imageURL: imageURL,
            extraData: extraData
        )
        AssertAsync.willBeEqual(AnyEndpoint(expectedEndpoint), client.mockAPIClient.request_endpoint)

        // Simulate successful response with a token.
        let token = Token.unique(userId: userId)
        let tokenResult: Result<GuestUserTokenPayload<NoExtraData>, Error> = .success(
            .init(user: .dummy(userId: userId, role: .guest), token: token)
        )
        client.mockAPIClient.test_simulateResponse(tokenResult)

        // Wait the result is received.
        AssertAsync.willBeTrue(getTokenResult != nil)

        // Assert token from the request is propagated.
        let receivedToken = try XCTUnwrap(try getTokenResult?.get())
        XCTAssertEqual(receivedToken, token)
    }

    func test_guestProvider_callsAPIClient_and_propagatesError() throws {
        // Create guest user data.
        let userId: UserId = .unique
        let userName: String = .unique
        let imageURL: URL = .unique()
        let extraData: NoExtraData = .defaultValue

        // Create a client.
        let client = ChatClient.mock

        // Create a `guest` token provider.
        let tokenProvider = TokenProvider.guest(
            userId: userId,
            name: userName,
            imageURL: imageURL,
            extraData: extraData
        )

        // Get token from provider and capture the result.
        var getTokenResult: Result<Token, Error>?
        tokenProvider.getToken(client) {
            getTokenResult = $0
        }

        // Wait for the API call to guest endpoint.
        let expectedEndpoint: Endpoint<GuestUserTokenPayload<NoExtraData>> = .guestUserToken(
            userId: userId,
            name: userName,
            imageURL: imageURL,
            extraData: extraData
        )
        AssertAsync.willBeEqual(AnyEndpoint(expectedEndpoint), client.mockAPIClient.request_endpoint)

        // Simulate error.
        let error = TestError()
        let tokenResult: Result<GuestUserTokenPayload<NoExtraData>, Error> = .failure(error)
        client.mockAPIClient.test_simulateResponse(tokenResult)

        // Wait the result is received.
        AssertAsync.willBeTrue(getTokenResult != nil)

        // Assert error from the request is propagated.
        let receivedError = try XCTUnwrap(getTokenResult?.error)
        XCTAssertEqual(receivedError as! TestError, error)
    }
}
