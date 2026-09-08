//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class PinnedMessagesQuery_IntegrationTests: XCTestCase {
    func test_pinnedMessagesRequest_isCreatedCorrectly() throws {
        // Create cid
        let cid: ChannelId = .unique

        // Create query arguments.
        let pageSize: Int = 10
        let messageId: MessageId = .unique

        // Create endpoint.
        let pagination = PinnedMessagesPagination.aroundMessage(messageId)
        let endpoint: Endpoint<PinnedMessagesPayload> = .getPinnedMessages(
            type: cid.type.rawValue,
            id: cid.id,
            limit: pageSize,
            offset: nil,
            idGte: pagination.messageIdAfterOrEqual,
            idGt: pagination.messageIdAfter,
            idLte: pagination.messageIdBeforeOrEqual,
            idLt: pagination.messageIdBefore,
            pinnedAtAfterOrEqual: pagination.timestampAfterOrEqual,
            pinnedAtAfter: pagination.timestampAfter,
            pinnedAtBeforeOrEqual: pagination.timestampBeforeOrEqual,
            pinnedAtBefore: pagination.timestampBefore,
            idAround: pagination.aroundMessageId,
            pinnedAtAround: pagination.aroundTimestamp,
            sort: [SortParamRequest(direction: 1, field: PinnedMessagesSortingKey.pinnedAt.rawValue)],
            memberCustomInclude: nil
        )

        let urlComponents = try encodeRequest(for: endpoint)

        // Assert path is correct
        XCTAssertEqual(urlComponents.path, endpoint.path.value)

        // Assert query contains the discrete pagination parameters
        let queryItems = try XCTUnwrap(urlComponents.queryItems)
        XCTAssertEqual(queryItems.first(where: { $0.name == "limit" })?.value, "\(pageSize)")
        XCTAssertEqual(queryItems.first(where: { $0.name == "id_around" })?.value, messageId)

        XCTAssertNotNil(queryItems.first(where: { $0.name == "sort" })?.value)
    }

    func test_pinnedMessagesRequest_withTimestampPagination_isCreatedCorrectly() throws {
        // Create cid
        let cid: ChannelId = .unique

        // Create query arguments.
        let pageSize: Int = 10
        let timestamp: Date = .unique

        // Create endpoint.
        let pagination = PinnedMessagesPagination.aroundTimestamp(timestamp)
        let endpoint: Endpoint<PinnedMessagesPayload> = .getPinnedMessages(
            type: cid.type.rawValue,
            id: cid.id,
            limit: pageSize,
            offset: nil,
            idGte: pagination.messageIdAfterOrEqual,
            idGt: pagination.messageIdAfter,
            idLte: pagination.messageIdBeforeOrEqual,
            idLt: pagination.messageIdBefore,
            pinnedAtAfterOrEqual: pagination.timestampAfterOrEqual,
            pinnedAtAfter: pagination.timestampAfter,
            pinnedAtBeforeOrEqual: pagination.timestampBeforeOrEqual,
            pinnedAtBefore: pagination.timestampBefore,
            idAround: pagination.aroundMessageId,
            pinnedAtAround: pagination.aroundTimestamp,
            sort: nil,
            memberCustomInclude: nil
        )

        let urlComponents = try encodeRequest(for: endpoint)

        // Assert path is correct
        XCTAssertEqual(urlComponents.path, endpoint.path.value)

        // Assert the date parameter is a bare RFC3339 string
        let queryItems = try XCTUnwrap(urlComponents.queryItems)
        XCTAssertEqual(queryItems.first(where: { $0.name == "limit" })?.value, "\(pageSize)")
        XCTAssertEqual(
            queryItems.first(where: { $0.name == "pinned_at_around" })?.value,
            CodableHelper.dateFormatter.string(from: timestamp)
        )
        XCTAssertNil(queryItems.first(where: { $0.name == "sort" }))
    }

    private func encodeRequest<Response>(for endpoint: Endpoint<Response>) throws -> URLComponents {
        // Create token provider
        let tokenProvider = ConnectionDetailsProviderDelegate_Spy()
        tokenProvider.provideTokenResult = .success(.unique(userId: .unique))

        // Create request encoder.
        let baseURL = BaseURL.dublin.restAPIBaseURL
        let apiKey = String.unique
        let requestEncoder = DefaultRequestEncoder(
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
        return urlComponents
    }
}
