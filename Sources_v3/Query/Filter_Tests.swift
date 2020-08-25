//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

@testable import StreamChatClient
import XCTest

class Filter_Tests: XCTestCase {
    func testOperators() {
        var filter = Filter.equal("a", to: "b")
        XCTAssertEqual(filter.json, "{\"a\":\"b\"}")
        
        filter = .notEqual("a", to: "b")
        XCTAssertEqual(filter.json, "{\"a\":{\"$ne\":\"b\"}}")
        
        filter = .greater("a", than: "b")
        XCTAssertEqual(filter.json, "{\"a\":{\"$gt\":\"b\"}}")
        
        filter = .greaterOrEqual("a", than: "b")
        XCTAssertEqual(filter.json, "{\"a\":{\"$gte\":\"b\"}}")
        
        filter = .less("a", than: "b")
        XCTAssertEqual(filter.json, "{\"a\":{\"$lt\":\"b\"}}")
        
        filter = .lessOrEqual("a", than: "b")
        XCTAssertEqual(filter.json, "{\"a\":{\"$lte\":\"b\"}}")
        
        filter = .in("a", ["b"])
        XCTAssertEqual(filter.json, "{\"a\":{\"$in\":[\"b\"]}}")
        
        filter = .notIn("a", ["b"])
        XCTAssertEqual(filter.json, "{\"a\":{\"$nin\":[\"b\"]}}")
        
        filter = .query("a", with: "b")
        XCTAssertEqual(filter.json, "{\"a\":{\"$q\":\"b\"}}")
        
        filter = .autocomplete("a", with: "b")
        XCTAssertEqual(filter.json, "{\"a\":{\"$autocomplete\":\"b\"}}")
        
        filter = .contains("a", "b")
        XCTAssertEqual(filter.json, "{\"a\":{\"$contains\":\"b\"}}")
        
        filter = .custom("myOperator", key: "a", value: "b")
        XCTAssertEqual(filter.json, "{\"a\":{\"$myOperator\":\"b\"}}")
    }
    
    func testFilterEncoding() {
        let filter1 = Filter.equal("a", to: "b")
        let filter2 = Filter.equal("c", to: "d")
        let filter3 = Filter.equal("e", to: "f")
        
        // And
        var filter = filter1
        filter &= filter2
        XCTAssertEqual((filter1 & filter2).json, "{\"$and\":[{\"a\":\"b\"},{\"c\":\"d\"}]}")
        XCTAssertEqual(filter.json, "{\"$and\":[{\"a\":\"b\"},{\"c\":\"d\"}]}")
        
        // Or
        filter = filter1
        filter |= filter2
        XCTAssertEqual((filter1 | filter2).json, "{\"$or\":[{\"a\":\"b\"},{\"c\":\"d\"}]}")
        XCTAssertEqual(filter.json, "{\"$or\":[{\"a\":\"b\"},{\"c\":\"d\"}]}")
        
        // Combination of Or + And
        XCTAssertEqual(
            ((filter1 | filter2) & filter3).json,
            "{\"$and\":[{\"$or\":[{\"a\":\"b\"},{\"c\":\"d\"}]},{\"e\":\"f\"}]}"
        )
        XCTAssertEqual(
            (filter1 | (filter2 & filter3)).json,
            "{\"$or\":[{\"a\":\"b\"},{\"$and\":[{\"c\":\"d\"},{\"e\":\"f\"}]}]}"
        )
        
        // Nor
        XCTAssertEqual(Filter.nor([filter1, filter2]).json, "{\"$nor\":[{\"a\":\"b\"},{\"c\":\"d\"}]}")
    }
    
    func testFilterDecoding() throws {
        let filter1: Filter = .and([.and([.or([.equal(.unique, to: String.unique)])])])
        let filter2: Filter = .custom(String.unique, key: .unique, value: 1)
        let filter3: Filter = .nor([.notIn(.unique, [1, 2, 3, 4, 5]), .in(.unique, [1.1, 2.2, 3.3])])
        
        // Encode filters
        let encoded1 = try JSONEncoder.default.encode(filter1)
        let encoded2 = try JSONEncoder.default.encode(filter2)
        let encoded3 = try JSONEncoder.default.encode(filter3)
        
        // Decode filters
        let decoded1 = try JSONDecoder.default.decode(Filter.self, from: encoded1)
        let decoded2 = try JSONDecoder.default.decode(Filter.self, from: encoded2)
        let decoded3 = try JSONDecoder.default.decode(Filter.self, from: encoded3)
        
        // Assert filters decoded correctly
        XCTAssertEqual(filter1.filterHash, decoded1.filterHash)
        XCTAssertEqual(filter2.filterHash, decoded2.filterHash)
        XCTAssertEqual(filter3.filterHash, decoded3.filterHash)
    }
}

extension Filter {
    var json: String {
        let data = try! JSONEncoder.default.encode(self)
        return String(data: data, encoding: .utf8)!
    }
}
