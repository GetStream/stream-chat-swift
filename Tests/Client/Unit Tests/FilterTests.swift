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
        var filter = "a".equal(to: "b")
        XCTAssertEqual(filter.json, "{\"a\":\"b\"}")
        
        filter = "a".notEqual(to: "b")
        XCTAssertEqual(filter.json, "{\"a\":{\"$ne\":\"b\"}}")
        
        filter = "a".greater(than: "b")
        XCTAssertEqual(filter.json, "{\"a\":{\"$gt\":\"b\"}}")
        
        filter = "a".greaterOrEqual(than: "b")
        XCTAssertEqual(filter.json, "{\"a\":{\"$gte\":\"b\"}}")
        
        filter = "a".less(than: "b")
        XCTAssertEqual(filter.json, "{\"a\":{\"$lt\":\"b\"}}")
        
        filter = "a".lessOrEqual(than: "b")
        XCTAssertEqual(filter.json, "{\"a\":{\"$lte\":\"b\"}}")
        
        filter = "a".in(["b"])
        XCTAssertEqual(filter.json, "{\"a\":{\"$in\":[\"b\"]}}")
        
        filter = "a".notIn(["b"])
        XCTAssertEqual(filter.json, "{\"a\":{\"$nin\":[\"b\"]}}")
        
        filter = "a".query("b")
        XCTAssertEqual(filter.json, "{\"a\":{\"$q\":\"b\"}}")
        
        filter = "a".autocomplete("b")
        XCTAssertEqual(filter.json, "{\"a\":{\"$autocomplete\":\"b\"}}")
    }
    
    func testFilter() {
        let filter1 = "a".equal(to: "b")
        let filter2 = "c".equal(to: "d")
        let filter3 = "e".equal(to: "f")
        
        // And
        var filter = filter1
        filter += filter2
        XCTAssertEqual((filter1 + filter2).json, "{\"$and\":[{\"a\":\"b\"},{\"c\":\"d\"}]}")
        XCTAssertEqual(filter.json, "{\"$and\":[{\"a\":\"b\"},{\"c\":\"d\"}]}")
        
        // Or
        filter = filter1
        filter |= filter2
        XCTAssertEqual((filter1 | filter2).json, "{\"$or\":[{\"a\":\"b\"},{\"c\":\"d\"}]}")
        XCTAssertEqual(filter.json, "{\"$or\":[{\"a\":\"b\"},{\"c\":\"d\"}]}")
        
        // Combination of Or + And
        XCTAssertEqual((filter1 | filter2 + filter3).json,
                       "{\"$and\":[{\"$or\":[{\"a\":\"b\"},{\"c\":\"d\"}]},{\"e\":\"f\"}]}")
        XCTAssertEqual((filter1 | (filter2 + filter3)).json,
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
