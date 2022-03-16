//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import XCTest

final class PinnedMessagesQuery_Tests: XCTestCase {
    func test_queryWithPagination_isEncodedCorrectly() throws {
        // Create page size.
        let pageSize: Int = 10
        
        // Create pagination
        let messageId: MessageId = .unique
        let pagination: PinnedMessagesPagination = .aroundMessage(messageId)
        
        // Create query.
        let query = PinnedMessagesQuery(
            pageSize: pageSize,
            pagination: pagination
        )
        
        // Encode query.
        let json = try JSONEncoder.default.encode(query)
        
        // Assert encoding is correct.
        AssertJSONEqual(json, [
            "limit": pageSize,
            "id_around": messageId
        ])
    }
    
    func test_queryWithoutPagination_isEncodedCorrectly() throws {
        // Create page size.
        let pageSize: Int = 10
        
        // Create query.
        let query = PinnedMessagesQuery(
            pageSize: pageSize,
            pagination: nil
        )
        
        // Encode query.
        let json = try JSONEncoder.default.encode(query)
        
        // Assert encoding is correct.
        AssertJSONEqual(json, ["limit": pageSize])
    }
    
    func test_queryWithSort_isEncodedCorrectly() throws {
        // Create page size.
        let pageSize: Int = 10
        
        // Create sorting options
        let sorting: [Sorting<PinnedMessagesSortingKey>] = [
            .init(key: .pinnedAt, isAscending: true),
            .init(key: .init(rawValue: "custom"), isAscending: false)
        ]
        
        // Create query with sort options.
        let query = PinnedMessagesQuery(
            pageSize: pageSize,
            sorting: sorting
        )
        
        // Encode query.
        let json = try JSONEncoder.default.encode(query)
        
        // Assert encoding is correct.
        AssertJSONEqual(json, [
            "limit": pageSize,
            "sort": [
                [
                    "field": "pinned_at",
                    "direction": 1
                ],
                [
                    "field": "custom",
                    "direction": -1
                ]
            ] as NSArray
        ])
    }
    
    func test_queryWithoutSorting_isEncodedCorrectly() throws {
        // Create page size.
        let pageSize: Int = 10
        
        // Create query with empty sort options.
        let query = PinnedMessagesQuery(
            pageSize: pageSize,
            sorting: []
        )
        
        // Encode query.
        let json = try JSONEncoder.default.encode(query)
        
        // Assert encoding is correct.
        AssertJSONEqual(json, ["limit": pageSize])
    }
}

final class PinnedMessagesQueryIntegration_Tests: XCTestCase {
    func test_pinnedMessagesRequest_isCreatedCorrectly() throws {
        // Create cid
        let cid: ChannelId = .unique
        
        // Create query.
        let pageSize: Int = 10
        let messageId: MessageId = .unique
        let query = PinnedMessagesQuery(
            pageSize: pageSize,
            sorting: [.init(key: .pinnedAt, isAscending: true)],
            pagination: .aroundMessage(messageId)
        )
        
        // Create endpoint.
        let endpoint: Endpoint<PinnedMessagesPayload> = .pinnedMessages(
            cid: cid,
            query: query
        )
        
        // Create token provider
        let tokenProvider = ConnectionDetailsProvider()
        tokenProvider.token = .unique(userId: .unique)
        
        // Create request encoder.
        let baseURL = BaseURL.dublin.restAPIBaseURL
        let apiKey = String.unique
        var requestEncoder = DefaultRequestEncoder(
            baseURL: baseURL,
            apiKey: .init(apiKey)
        )
        requestEncoder.connectionDetailsProviderDelegate = tokenProvider
        
        // Encode request.
        let urlRequestResult = try waitFor {
            requestEncoder.encodeRequest(for: endpoint, completion: $0)
        }
        let urlRequest = try urlRequestResult.get()
        let url = try XCTUnwrap(urlRequest.url)
        let urlComponents = try XCTUnwrap(URLComponents(string: url.absoluteString))
        
        // Assert host is correct
        XCTAssertEqual(urlComponents.host, baseURL.host)
        // Assert path is correct
        XCTAssertEqual(urlComponents.path, "/\(endpoint.path.value)")
        // Assert query contains payload
        let payload = try XCTUnwrap(
            urlComponents
                .queryItems?
                .first(where: { $0.name == "payload" })?
                .value?
                .data(using: .utf8)
        )
        
        AssertJSONEqual(payload, [
            "id_around": messageId,
            "limit": "\(pageSize)",
            "sort": [
                [
                    "direction": 1,
                    "field": "pinned_at"
                ]
            ] as NSArray
        ])
    }
}

private class ConnectionDetailsProvider: ConnectionDetailsProviderDelegate {
    var token: Token?
    
    func provideToken(completion: @escaping (Token?) -> Void) -> WaiterToken {
        completion(token)
        return String.newUniqueId
    }
    
    var connectionId: ConnectionId?
    
    func provideConnectionId(completion: @escaping (ConnectionId?) -> Void) -> WaiterToken {
        completion(connectionId)
        return String.newUniqueId
    }

    func invalidateTokenWaiter(_ waiter: WaiterToken) {}

    func invalidateConnectionIdWaiter(_ waiter: WaiterToken) {}
}
