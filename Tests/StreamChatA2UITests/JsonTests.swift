//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChatA2UI
import Testing

@MainActor
@Suite("JSON coercion")
struct JsonTests {
    @Test("Strings pass through unchanged")
    func stringPassthrough() {
        #expect(Json.stringify("hello") == "hello")
        #expect(Json.string("hello") == "hello")
    }

    @Test("Numbers use their shortest standard representation")
    func numberConversion() {
        #expect(Json.stringify(10) == "10")
        #expect(Json.stringify(10.0) == "10")
        #expect(Json.stringify(4.75) == "4.75")
        #expect(Json.stringify(-3) == "-3")
    }

    @Test("Booleans stringify as true and false")
    func booleanConversion() {
        #expect(Json.stringify(true) == "true")
        #expect(Json.stringify(false) == "false")
    }

    @Test("Null becomes an empty string")
    func nullConversion() {
        #expect(Json.stringify(nil) == "")
        #expect(Json.stringify(NSNull()) == "")
        #expect(Json.isNull(NSNull()))
        #expect(Json.normalized(NSNull()) == nil)
    }

    @Test("Objects and arrays stringify as JSON")
    func containerConversion() {
        #expect(Json.stringify([1, 2]) == "[1,2]")
        let object = Json.stringify(["a": 1] as JsonMap)
        #expect(object == "{\"a\":1}")
    }

    @Test("Numeric strings coerce to numbers")
    func numberCoercion() {
        #expect(Json.double("4.5") == 4.5)
        #expect(Json.int("7") == 7)
        #expect(Json.double("abc") == nil)
        #expect(Json.double(true) == 1)
    }

    @Test("Boolean coercion accepts numbers and strings")
    func booleanCoercion() {
        #expect(Json.bool(1) == true)
        #expect(Json.bool(0) == false)
        #expect(Json.bool("true") == true)
        #expect(Json.bool("FALSE") == false)
        #expect(Json.bool("maybe") == nil)
    }

    @Test("String arrays coerce their elements")
    func stringArrayCoercion() {
        #expect(Json.stringArray(["a", 2, true] as JsonArray) == ["a", "2", "true"])
        #expect(Json.stringArray("a") == nil)
    }

    @Test("Structural equality ignores dictionary order")
    func equality() {
        #expect(Json.isEqual(["a": 1, "b": [1, 2]] as JsonMap, ["b": [1, 2], "a": 1] as JsonMap))
        #expect(!Json.isEqual(["a": 1] as JsonMap, ["a": 2] as JsonMap))
        #expect(Json.isEqual(nil, NSNull()))
    }

    @Test("Encoding round-trips through strings")
    func encoding() {
        let payload: JsonMap = ["a": 1, "b": ["c": true]]
        let string = Json.encodeToString(payload)
        #expect(string != nil)
        #expect(Json.isEqual(Json.decodeMap(string ?? ""), payload))
    }
}
