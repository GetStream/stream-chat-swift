//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class Filter_Tests: XCTestCase {
    func test_helperOperators() {
        var filter: Filter<FilterTestScope> = .equal(.testKey, to: "equal value")
        XCTAssertEqual(filter.key, FilterKey<FilterTestScope, String>.testKey.rawValue)
        XCTAssertEqual(filter.value as? String, "equal value")
        XCTAssertEqual(filter.operator, FilterOperator.equal.rawValue)
        
        filter = .equal(.testKey, values: ["eq value 1", "eq value 2"])
        XCTAssertEqual(filter.key, FilterKey<FilterTestScope, String>.testKey.rawValue)
        XCTAssertEqual(filter.value as? [String], ["eq value 1", "eq value 2"])
        XCTAssertEqual(filter.operator, FilterOperator.equal.rawValue)

        filter = .greater(.testKey, than: "greater value")
        XCTAssertEqual(filter.key, FilterKey<FilterTestScope, String>.testKey.rawValue)
        XCTAssertEqual(filter.value as? String, "greater value")
        XCTAssertEqual(filter.operator, FilterOperator.greater.rawValue)

        filter = .greaterOrEqual(.testKey, than: "greater or equal value")
        XCTAssertEqual(filter.key, FilterKey<FilterTestScope, String>.testKey.rawValue)
        XCTAssertEqual(filter.value as? String, "greater or equal value")
        XCTAssertEqual(filter.operator, FilterOperator.greaterOrEqual.rawValue)

        filter = .less(.testKey, than: "less value")
        XCTAssertEqual(filter.key, FilterKey<FilterTestScope, String>.testKey.rawValue)
        XCTAssertEqual(filter.value as? String, "less value")
        XCTAssertEqual(filter.operator, FilterOperator.less.rawValue)

        filter = .lessOrEqual(.testKey, than: "less or equal value")
        XCTAssertEqual(filter.key, FilterKey<FilterTestScope, String>.testKey.rawValue)
        XCTAssertEqual(filter.value as? String, "less or equal value")
        XCTAssertEqual(filter.operator, FilterOperator.lessOrEqual.rawValue)

        filter = .in(.testKey, values: ["in value 1", "in value 2"])
        XCTAssertEqual(filter.key, FilterKey<FilterTestScope, String>.testKey.rawValue)
        XCTAssertEqual(filter.value as? [String], ["in value 1", "in value 2"])
        XCTAssertEqual(filter.operator, FilterOperator.in.rawValue)

        filter = .query(.testKey, text: "searched text")
        XCTAssertEqual(filter.key, FilterKey<FilterTestScope, String>.testKey.rawValue)
        XCTAssertEqual(filter.value as? String, "searched text")
        XCTAssertEqual(filter.operator, FilterOperator.query.rawValue)

        filter = .autocomplete(.testKey, text: "atocomplete text")
        XCTAssertEqual(filter.key, FilterKey<FilterTestScope, String>.testKey.rawValue)
        XCTAssertEqual(filter.value as? String, "atocomplete text")
        XCTAssertEqual(filter.operator, FilterOperator.autocomplete.rawValue)

        filter = .exists(.testKey, exists: false)
        XCTAssertEqual(filter.key, FilterKey<FilterTestScope, String>.testKey.rawValue)
        XCTAssertEqual(filter.value as? Bool, false)
        XCTAssertEqual(filter.operator, FilterOperator.exists.rawValue)

        let filter1: Filter<FilterTestScope> = .init(operator: "$" + .unique, key: .unique, value: String.unique, isCollectionFilter: false)
        let filter2: Filter<FilterTestScope> = .init(operator: "$" + .unique, key: .unique, value: String.unique, isCollectionFilter: false)

        filter = .and([filter1, filter2])
        XCTAssertEqual(filter.key, nil)
        XCTAssertEqual(filter.value as? [Filter<FilterTestScope>], [filter1, filter2])
        XCTAssertEqual(filter.operator, FilterOperator.and.rawValue)

        filter = .or([filter1, filter2])
        XCTAssertEqual(filter.key, nil)
        XCTAssertEqual(filter.value as? [Filter<FilterTestScope>], [filter1, filter2])
        XCTAssertEqual(filter.operator, FilterOperator.or.rawValue)

        filter = .nor([filter1, filter2])
        XCTAssertEqual(filter.key, nil)
        XCTAssertEqual(filter.value as? [Filter<FilterTestScope>], [filter1, filter2])
        XCTAssertEqual(filter.operator, FilterOperator.nor.rawValue)
    }

    func test_operatorEncodingAndDecoding() {
        // Test non-group filter
        var filter: Filter<FilterTestScope> = .init(operator: FilterOperator.equal.rawValue, key: "test_key", value: "test_value", isCollectionFilter: false)
        var jsonString: String { filter.serialized }
        XCTAssertEqual(jsonString, #"{"test_key":{"$eq":"test_value"}}"#)
        XCTAssertEqual(jsonString.deserializeFilter(), filter)

        // Test in filter
        filter = .init(operator: FilterOperator.in.rawValue, key: "test_key", value: [1, 2, 3], isCollectionFilter: false)
        XCTAssertEqual(filter.serialized, #"{"test_key":{"$in":[1,2,3]}}"#)
        XCTAssertEqual(jsonString.deserializeFilter(), filter)
        
        // Test eq values filter
        filter = .init(operator: FilterOperator.equal.rawValue, key: "test_key", value: [1, 2, 3], isCollectionFilter: false)
        XCTAssertEqual(filter.serialized, #"{"test_key":{"$eq":[1,2,3]}}"#)
        XCTAssertEqual(jsonString.deserializeFilter(), filter)

        // Test group filter
        let filter1: Filter<FilterTestScope> = .equal(.testKey, to: "test_value_1")
        let filter2: Filter<FilterTestScope> = .equal(.testKey, to: "test_value_2")
        filter = .or([filter1, filter2])
        XCTAssertEqual(filter.serialized, #"{"$or":[{"test_key":{"$eq":"test_value_1"}},{"test_key":{"$eq":"test_value_2"}}]}"#)
        XCTAssertEqual(jsonString.deserializeFilter(), filter)
    }

    func test_encodesAndDecodes_forAllFilterCases() {
        // Given
        let testCases = FilterCodingTestPair.allCases

        for pair in testCases {
            let filter = pair.filter
            // When
            let encoded = try! filter.serializedThrows()
            let decoded: Filter<FilterTestScope> = try! encoded.deserializeFilterThrows()
            // Then
            XCTAssertEqual(filter, decoded)
        }
    }

    func test_toRawJSONDictionary_convertsSupportedValueTypes() {
        let date = Date(timeIntervalSince1970: 1_640_995_200)
        let url = URL(string: "https://getstream.io")!

        XCTAssertEqual(
            Filter<FilterTestScope>.equal(.testKeyBool, to: true).toRawJSONDictionary(),
            ["test_key_Bool": .dictionary(["$eq": .bool(true)])]
        )
        XCTAssertEqual(
            Filter<FilterTestScope>.equal(.testKeyInt, to: 1).toRawJSONDictionary(),
            ["test_key_Int": .dictionary(["$eq": .number(1)])]
        )
        XCTAssertEqual(
            Filter<FilterTestScope>.equal(.testKeyDouble, to: 13.15).toRawJSONDictionary(),
            ["test_key_Double": .dictionary(["$eq": .number(13.15)])]
        )
        XCTAssertEqual(
            Filter<FilterTestScope>.equal(.testKeyDate, to: date).toRawJSONDictionary(),
            ["test_key_Date": .dictionary(["$eq": .string("2022-01-01T00:00:00.000Z")])]
        )
        XCTAssertEqual(
            Filter<FilterTestScope>.equal(.testKeyURL, to: url).toRawJSONDictionary(),
            ["test_key_URL": .dictionary(["$eq": .string("https://getstream.io")])]
        )
        XCTAssertEqual(
            Filter<FilterTestScope>.in(.testKeyArrayInt, values: [1, 2]).toRawJSONDictionary(),
            ["test_key_ArrayInt": .dictionary(["$in": .array([.number(1), .number(2)])])]
        )
        XCTAssertEqual(
            Filter<FilterTestScope>.equal(.testKeyChannelId, to: ChannelId(type: .messaging, id: "general")).toRawJSONDictionary(),
            ["test_key_ChannelId": .dictionary(["$eq": .string("messaging:general")])]
        )
        XCTAssertEqual(
            Filter<FilterTestScope>.equal(.testKeyChannelType, to: .custom("support")).toRawJSONDictionary(),
            ["test_key_ChannelType": .dictionary(["$eq": .string("support")])]
        )
        XCTAssertEqual(
            Filter<FilterTestScope>.equal(.testKeyMemberRole, to: .moderator).toRawJSONDictionary(),
            ["test_key_MemberRole": .dictionary(["$eq": .string("channel_moderator")])]
        )
        XCTAssertEqual(
            Filter<FilterTestScope>.equal(.testKeyUserRole, to: .admin).toRawJSONDictionary(),
            ["test_key_UserRole": .dictionary(["$eq": .string("admin")])]
        )
        XCTAssertEqual(
            Filter<FilterTestScope>.equal(.testKeyAttachmentType, to: .image).toRawJSONDictionary(),
            ["test_key_AttachmentType": .dictionary(["$eq": .string("image")])]
        )
        XCTAssertEqual(
            Filter<FilterTestScope>.equal(.testKeyMessageReactionType, to: MessageReactionType(rawValue: "like")).toRawJSONDictionary(),
            ["test_key_MessageReactionType": .dictionary(["$eq": .string("like")])]
        )
        XCTAssertEqual(
            Filter<FilterTestScope>.equal(.testKeyInviteFilterValue, to: .accepted).toRawJSONDictionary(),
            ["test_key_InviteFilterValue": .dictionary(["$eq": .string("accepted")])]
        )
        XCTAssertEqual(
            Filter<FilterTestScope>.equal(.testKeyOptionalTeamId, to: TeamId?.some("team-a")).toRawJSONDictionary(),
            ["test_key_OptionalTeamId": .dictionary(["$eq": .string("team-a")])]
        )
        XCTAssertEqual(
            Filter<FilterTestScope>.equal(.testKeyOptionalTeamId, to: TeamId?.none).toRawJSONDictionary(),
            ["test_key_OptionalTeamId": .dictionary(["$eq": .nil])]
        )
    }

    func test_toRawJSONDictionary_convertsNestedGroupFilters() {
        let filter: Filter<FilterTestScope> = .and([
            .greater(.testKeyInt, than: 18),
            .or([
                .equal(.testKey, to: "Luke"),
                .equal(.testKey, to: "Leia")
            ]),
            .nor([
                .equal(.testKeyBool, to: false)
            ])
        ])

        XCTAssertEqual(
            filter.toRawJSONDictionary(),
            [
                "$and": .array([
                    .dictionary(["test_key_Int": .dictionary(["$gt": .number(18)])]),
                    .dictionary([
                        "$or": .array([
                            .dictionary(["test_key": .dictionary(["$eq": .string("Luke")])]),
                            .dictionary(["test_key": .dictionary(["$eq": .string("Leia")])])
                        ])
                    ]),
                    .dictionary([
                        "$nor": .array([
                            .dictionary(["test_key_Bool": .dictionary(["$eq": .bool(false)])])
                        ])
                    ])
                ])
            ]
        )
    }
}
