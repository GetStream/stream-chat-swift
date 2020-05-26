//
//  FilterTests.swift
//  StreamChatClientTests
//
//  Created by Alexey Bukhtin on 19/01/2020.
//  Copyright © 2020 Stream.io Inc. All rights reserved.
//

import XCTest
@testable import StreamChatClient

final class FilterTests: XCTestCase {
    
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
    
    func testFilter() {
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
        XCTAssertEqual(((filter1 | filter2) & filter3).json,
                       "{\"$and\":[{\"$or\":[{\"a\":\"b\"},{\"c\":\"d\"}]},{\"e\":\"f\"}]}")
        XCTAssertEqual((filter1 | (filter2 & filter3)).json,
                       "{\"$or\":[{\"a\":\"b\"},{\"$and\":[{\"c\":\"d\"},{\"e\":\"f\"}]}]}")
        
        // Nor
        XCTAssertEqual(Filter.nor([filter1, filter2]).json, "{\"$nor\":[{\"a\":\"b\"},{\"c\":\"d\"}]}")
    }
}

extension Filter {
    var json: String {
        let data = try! JSONEncoder.default.encode(self)
        return String(data: data, encoding: .utf8)!
    }
}
