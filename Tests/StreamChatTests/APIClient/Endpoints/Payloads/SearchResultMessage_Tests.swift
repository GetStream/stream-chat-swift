//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

/// `SearchResultMessage` is `MessageResponse` plus `channel`, bridged by
/// `SearchResultMessage.asMessageResponse()`. These two tests are the reason that hand-written copy is
/// safe: the first fails when the schemas stop differing by exactly `channel`, the second fails when the
/// copy forgets a field.
final class SearchResultMessage_Tests: XCTestCase {
    var database: DatabaseContainer!

    override func setUp() {
        super.setUp()
        database = DatabaseContainer_Spy()
    }

    override func tearDown() {
        AssertAsync.canBeReleased(&database)
        database = nil
        super.tearDown()
    }

    /// The embedded channel exists so search can persist results from channels the client has never
    /// seen. Without it the save fails and `saveMessageSearch` drops the result silently.
    func test_saveMessageSearch_persistsResultWhoseChannelIsNotCached() throws {
        let cid = ChannelId.unique
        let messageId = MessageId.unique
        let query = MessageSearchQuery(channelFilter: .equal(.cid, to: cid), messageFilter: .equal(.text, to: "text"))

        XCTAssertNil(database.viewContext.channel(cid: cid), "The channel must not be cached for this test to mean anything")

        try database.writeSynchronously { session in
            session.saveMessageSearch(
                payload: MessageSearchResultsPayload(
                    results: [.init(message: .dummy(messageId: messageId, cid: cid, channel: .dummy(cid: cid)))],
                    next: nil
                ),
                for: query
            )
        }

        try database.readSynchronously { session in
            let message = try XCTUnwrap(session.message(id: messageId))
            XCTAssertEqual(message.cid, cid.rawValue)
            XCTAssertNotNil(session.channel(cid: cid))
        }
    }

    func test_schemasDifferOnlyByChannel() {
        let searchKeys = Set(SearchResultMessage.CodingKeys.allCases.map(\.rawValue))
        let messageKeys = Set(MessageResponse.CodingKeys.allCases.map(\.rawValue))

        XCTAssertEqual(
            searchKeys.subtracting(messageKeys),
            ["channel"],
            "SearchResultMessage gained or lost a field relative to MessageResponse — update asMessageResponse()"
        )
        XCTAssertEqual(
            messageKeys.subtracting(searchKeys),
            [],
            "MessageResponse has a field SearchResultMessage does not — asMessageResponse() cannot fill it"
        )
    }

    func test_asMessageResponse_copiesEveryField() throws {
        // A populated fixture, not a sparse dummy: a dummy leaves most fields nil and the comparison
        // would pass while proving nothing.
        let data = XCTestCase.mockData(fromJSONFile: "MessagePayload")
        let searchResult = try JSONDecoder.stream.decode(SearchResultMessage.self, from: data)
        XCTAssertNotNil(searchResult.channel, "The fixture must carry a channel for this test to mean anything")

        let converted = searchResult.asMessageResponse()

        var searchJSON = try encodedDictionary(searchResult)
        let convertedJSON = try encodedDictionary(converted)

        XCTAssertEqual(
            Set(searchJSON.keys).subtracting(convertedJSON.keys),
            ["channel"],
            "asMessageResponse() dropped a field"
        )

        // Deep structural comparison of everything except the field that only search returns.
        searchJSON.removeValue(forKey: "channel")
        XCTAssertEqual(
            searchJSON as NSDictionary,
            convertedJSON as NSDictionary,
            "asMessageResponse() changed or dropped a value"
        )
    }

    private func encodedDictionary(_ value: some Encodable) throws -> [String: Any] {
        let data = try JSONEncoder.stream.encode(value)
        return try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
    }
}
