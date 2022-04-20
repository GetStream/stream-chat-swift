//
// Copyright © 2022 Stream.io Inc. All rights reserved.
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
        
        filter = .notEqual(.testKey, to: "not equal value")
        XCTAssertEqual(filter.key, FilterKey<FilterTestScope, String>.testKey.rawValue)
        XCTAssertEqual(filter.value as? String, "not equal value")
        XCTAssertEqual(filter.operator, FilterOperator.notEqual.rawValue)
        
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
        
        filter = .notIn(.testKey, values: ["nin value 1", "nin value 2"])
        XCTAssertEqual(filter.key, FilterKey<FilterTestScope, String>.testKey.rawValue)
        XCTAssertEqual(filter.value as? [String], ["nin value 1", "nin value 2"])
        XCTAssertEqual(filter.operator, FilterOperator.notIn.rawValue)
        
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
        
        let filter1: Filter<FilterTestScope> = .init(operator: "$" + .unique, key: .unique, value: String.unique)
        let filter2: Filter<FilterTestScope> = .init(operator: "$" + .unique, key: .unique, value: String.unique)
        
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
        var filter: Filter<FilterTestScope> = .init(operator: FilterOperator.equal.rawValue, key: "test_key", value: "test_value")
        var jsonString: String { filter.serialized }
        XCTAssertEqual(jsonString, #"{"test_key":{"$eq":"test_value"}}"#)
        XCTAssertEqual(jsonString.deserializeFilter(), filter)
        
        // Test in filter
        filter = .init(operator: FilterOperator.in.rawValue, key: "test_key", value: [1, 2, 3])
        XCTAssertEqual(filter.serialized, #"{"test_key":{"$in":[1,2,3]}}"#)
        XCTAssertEqual(jsonString.deserializeFilter(), filter)
        
        // Test group filter
        let filter1: Filter<FilterTestScope> = .equal(.testKey, to: "test_value_1")
        let filter2: Filter<FilterTestScope> = .notEqual(.testKey, to: "test_value_2")
        filter = .or([filter1, filter2])
        XCTAssertEqual(filter.serialized, #"{"$or":[{"test_key":{"$eq":"test_value_1"}},{"test_key":{"$ne":"test_value_2"}}]}"#)
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
}
