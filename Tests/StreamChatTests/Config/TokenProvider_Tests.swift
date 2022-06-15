//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class TokenProvider_Tests: XCTestCase {
    func test_noCurrentUser_fetchToken_returnsError() throws {
        // GIVEN
        let provider: UserConnectionProvider = .noCurrentUser
        
        // WHEN
        let tokenResult = try waitFor(provider.fetchToken)
        
        // THEN
        XCTAssertTrue(tokenResult.error is ClientError.CurrentUserDoesNotExist)
    }
    
    func test_notInitiated_fetchToken_returnsError() throws {
        // GIVEN
        let provider: UserConnectionProvider = .notInitiated(userId: .unique)
        
        // WHEN
        let tokenResult = try waitFor(provider.fetchToken)
        
        // THEN
        XCTAssertTrue(tokenResult.error is ClientError.ConnectionWasNotInitiated)
    }
    
    func test_initiated_fetchToken_propagatesToken() throws {
        // GIVEN
        let token: Token = .unique()
        let provider: UserConnectionProvider = .initiated(userId: .unique) { $0(.success(token)) }
        
        // WHEN
        let tokenResult = try waitFor(provider.fetchToken)
        
        // THEN
        XCTAssertEqual(try tokenResult.get(), token)
    }
    
    func test_initiated_fetchToken_propagatesError() throws {
        // GIVEN
        let error = TestError()
        let provider: UserConnectionProvider = .initiated(userId: .unique) { $0(.failure(error)) }
        
        // WHEN
        let tokenResult = try waitFor(provider.fetchToken)
        
        // THEN
        XCTAssertEqual(tokenResult.error as? TestError, error)
    }
    
    func test_development_fetchToken_returnsDevToken() throws {
        // GIVEN
        let userId: UserId = .unique
        let provider: UserConnectionProvider = .development(userId: userId)
        
        // WHEN
        let token = try waitFor(provider.fetchToken).get()
        
        // THEN
        let tokenParts = token.rawValue.split(separator: ".")
        XCTAssertEqual(tokenParts[0], "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9") // header
        XCTAssertEqual(token.userId, userId) // payload
        XCTAssertEqual(tokenParts[2], "devtoken") // signature
    }

    func test_staticProvider_fetchToken_propagatesToken() throws {
        // GIVEN
        let token = Token.unique(userId: .unique)
        let provider: UserConnectionProvider = .static(token)

        // WHEN
        let receivedToken = try waitFor(provider.fetchToken).get()
        
        // THEN
        XCTAssertEqual(receivedToken, token)
    }
    
    func test_guestProvider_callsAPIClient_and_propagatesToken() throws {
        // Create guest user data.
        let userId: UserId = .unique
        let userName: String = .unique
        let imageURL: URL = .unique()
        let extraData: [String: RawJSON] = [:]

        // Create a client.
        let client = ChatClient.mock

        // Create a `guest` token provider.
        let provider = UserConnectionProvider.guest(
            client: client,
            userId: userId,
            name: userName,
            imageURL: imageURL,
            extraData: extraData
        )

        // Get token from provider and capture the result.
        var getTokenResult: Result<Token, Error>?
        provider.fetchToken {
            getTokenResult = $0
        }

        // Wait for the API call to guest endpoint.
        let expectedEndpoint: Endpoint<GuestUserTokenPayload> = .guestUserToken(
            userId: userId,
            name: userName,
            imageURL: imageURL,
            extraData: extraData
        )
        AssertAsync.willBeEqual(AnyEndpoint(expectedEndpoint), client.mockAPIClient.executeRequest_endpoint)

        // Simulate successful response with a token.
        let token = Token.unique(userId: userId)
        let completion = client.mockAPIClient.executeRequest_completion as! (Result<GuestUserTokenPayload, Error>) -> Void
        completion(.success(.init(user: .dummy(userId: userId, role: .guest), token: token)))
        
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
        let extraData: [String: RawJSON] = [:]

        // Create a client.
        let client = ChatClient.mock

        // Create a `guest` token provider.
        let provider = UserConnectionProvider.guest(
            client: client,
            userId: userId,
            name: userName,
            imageURL: imageURL,
            extraData: extraData
        )

        // Get token from provider and capture the result.
        var getTokenResult: Result<Token, Error>?
        provider.fetchToken {
            getTokenResult = $0
        }

        // Wait for the API call to guest endpoint.
        let expectedEndpoint: Endpoint<GuestUserTokenPayload> = .guestUserToken(
            userId: userId,
            name: userName,
            imageURL: imageURL,
            extraData: extraData
        )
        AssertAsync.willBeEqual(AnyEndpoint(expectedEndpoint), client.mockAPIClient.executeRequest_endpoint)

        // Simulate error.
        let error = TestError()
        let completion = client.mockAPIClient.executeRequest_completion as! (Result<GuestUserTokenPayload, Error>) -> Void
        completion(.failure(error))
        
        // Wait the result is received.
        AssertAsync.willBeTrue(getTokenResult != nil)

        // Assert error from the request is propagated.
        let receivedError = try XCTUnwrap(getTokenResult?.error)
        XCTAssertEqual(receivedError as! TestError, error)
    }
}
