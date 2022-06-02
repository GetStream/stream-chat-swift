//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class PinnedMessagesQuery_IntegrationTests: XCTestCase {
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
        let tokenProvider = ConnectionDetailsProviderDelegate_Spy()
        tokenProvider.tokenResult = .success(.unique(userId: .unique))

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
