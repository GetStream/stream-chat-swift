//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class RawJSON_Tests: XCTestCase {
    func test_valueEncoding() throws {
        struct test {
            var value: RawJSON
            var expected: String
        }

        let tests = [
            test.init(value: .dictionary(["k": .bool(false)]), expected: "{\"k\": false}"),
            test.init(value: .dictionary(["k": .bool(true)]), expected: "{\"k\": true}"),
            test.init(value: .dictionary(["k": .number(3.14)]), expected: "{\"k\": 3.14}"),
            test.init(value: .dictionary(["k": .number(3)]), expected: "{\"k\": 3}"),
            test.init(value: .dictionary(["k": .number(-3)]), expected: "{\"k\": -3}"),
            test.init(value: .dictionary(["k": .number(0)]), expected: "{\"k\": 0}"),
            test.init(value: .dictionary(["k": .double(0.1)]), expected: "{\"k\": 0.1}"),
            test.init(value: .dictionary(["k": .string("asd")]), expected: "{\"k\": \"asd\"}")
        ]
        
        for test in tests {
            let encoded = try JSONEncoder.stream.encode(test.value)
            AssertJSONEqual(encoded, test.expected.data(using: .utf8)!)
        }
    }

    func test_valueDecoding() throws {
        struct test {
            var value: String
            var expected: RawJSON
        }

        let tests = [
            test.init(value: "{\"k\": false}", expected: .dictionary(["k": .bool(false)])),
            test.init(value: "{\"k\": true}", expected: .dictionary(["k": .bool(true)])),
            test.init(value: "{\"k\": 3}", expected: .dictionary(["k": .number(3)])),
            test.init(value: "{\"k\": 3.14}", expected: .dictionary(["k": .number(3.14)])),
            test.init(value: "{\"k\": 3.14}", expected: .dictionary(["k": .double(3.14)])),
            test.init(value: "{\"k\": 3}", expected: .dictionary(["k": .number(3)])),
            test.init(value: "{\"k\": \"asd\"}", expected: .dictionary(["k": .string("asd")]))
        ]
        
        for test in tests {
            let rawJSON = try? JSONDecoder.stream.decode(RawJSON.self, from: test.value.data(using: .utf8)!)
            XCTAssertEqual(rawJSON, test.expected)
        }
    }

    func test_encodedAndDecoded() throws {
        let attachmentType: String = "route"
        let routeId: Int = 123
        let routeType: String = "hike"
        let routeMapURL = URL(string: "https://getstream.io/routeMap.jpg")!

        let data: Data = """
            {   "type": "\(attachmentType)",
                "route": {
                    "id": \(routeId), "type": "\(routeType)"
                },
                "routeMapURL": "\(routeMapURL.absoluteString)"
            }
        """.data(using: .utf8)!

        var rawJSON: RawJSON?

        rawJSON = try? JSONDecoder().decode(RawJSON.self, from: data)

        let encoded = try JSONEncoder().encode(rawJSON)

        struct RouteAttachment: Decodable {
            let type: String
            let route: Route
            let routeMapURL: URL
        }

        struct Route: Decodable {
            let id: Int
            let type: String
        }

        let decoded = try JSONDecoder().decode(RouteAttachment.self, from: encoded)

        XCTAssertEqual(decoded.type, attachmentType)
        XCTAssertEqual(decoded.routeMapURL, routeMapURL)
        XCTAssertEqual(decoded.route.type, routeType)
        XCTAssertEqual(decoded.route.id, routeId)
    }

    func test_numberValue() {
        let validNumber = RawJSON.number(30)
        XCTAssertEqual(validNumber.numberValue, 30)

        let invalidNumber = RawJSON.bool(true)
        XCTAssertEqual(invalidNumber.numberValue, nil)
    }

    func test_stringValue() {
        let validString = RawJSON.string("hello")
        XCTAssertEqual(validString.stringValue, "hello")

        let invalidString = RawJSON.number(30)
        XCTAssertEqual(invalidString.stringValue, nil)
    }

    func test_boolValue() {
        let validBool = RawJSON.bool(true)
        XCTAssertEqual(validBool.boolValue, true)

        let invalidBool = RawJSON.string("true")
        XCTAssertEqual(invalidBool.boolValue, nil)
    }

    func test_dictionaryValue() {
        let validDictionary = RawJSON.dictionary([
            "price": .number(23)
        ])
        XCTAssertEqual(validDictionary.dictionaryValue, ["price": .number(23)])

        let invalidDictionary = RawJSON.array([.number(23)])
        XCTAssertEqual(invalidDictionary.dictionaryValue, nil)
    }

    func test_arrayValue() {
        let validArray = RawJSON.array([.string("Hello"), .string("World")])
        XCTAssertEqual(validArray.arrayValue, [.string("Hello"), .string("World")])

        let invalidArray = RawJSON.string("Not an array")
        XCTAssertEqual(invalidArray.arrayValue, nil)
    }

    func test_numberArrayValue() {
        let validNumberArray = RawJSON.array([.number(10), .number(20)])
        XCTAssertEqual(validNumberArray.numberArrayValue, [10, 20])

        let partiallyValidNumberArray = RawJSON.array([.number(10), .string("wrong")])
        XCTAssertEqual(partiallyValidNumberArray.numberArrayValue, [10])

        let invalidNumberArray = RawJSON.string("Not an array")
        XCTAssertEqual(invalidNumberArray.numberArrayValue, nil)
    }

    func test_stringArrayValue() {
        let validStringArray = RawJSON.array([.string("Hello"), .string("World")])
        XCTAssertEqual(validStringArray.stringArrayValue, ["Hello", "World"])

        let partiallyValidStringArray = RawJSON.array([.number(10), .string("wrong")])
        XCTAssertEqual(partiallyValidStringArray.stringArrayValue, ["wrong"])

        let invalidStringArray = RawJSON.string("Not an array")
        XCTAssertEqual(invalidStringArray.stringArrayValue, nil)
    }

    func test_boolArrayValue() {
        let validBoolArray = RawJSON.array([.bool(false), .bool(false)])
        XCTAssertEqual(validBoolArray.boolArrayValue, [false, false])

        let partiallyValidBoolArray = RawJSON.array([.number(10), .bool(false)])
        XCTAssertEqual(partiallyValidBoolArray.boolArrayValue, [false])

        let invalidBoolArray = RawJSON.string("Not an array")
        XCTAssertEqual(invalidBoolArray.boolArrayValue, nil)
    }

    func test_isNil() {
        let validNil = RawJSON.nil
        XCTAssertTrue(validNil.isNil)

        let notNil = RawJSON.string("Hey")
        XCTAssertFalse(notNil.isNil)
    }

    func test_init_dictionaryLiteral() {
        let rawJSONDictionary: RawJSON = [
            "price": .number(23)
        ]

        XCTAssertEqual(rawJSONDictionary, RawJSON.dictionary(["price": .number(23)]))
    }

    func test_init_arrayLiteral() {
        let rawJSONArray: RawJSON = [.number(20), .number(30)]
        XCTAssertEqual(rawJSONArray, RawJSON.array([.number(20), .number(30)]))
    }

    func test_init_stringLiteral() {
        let rawJSONString: RawJSON = "Hello"
        XCTAssertEqual(rawJSONString, .string("Hello"))
    }

    func test_init_floatLiteral() {
        let rawJSONDouble: RawJSON = 23.50
        XCTAssertEqual(rawJSONDouble, .number(23.50))
    }

    func test_init_integerLiteral() {
        let rawJSONInteger: RawJSON = 23
        XCTAssertEqual(rawJSONInteger, .number(23))
    }

    func test_init_booleanLiteral() {
        let rawJSONBoolean: RawJSON = true
        XCTAssertEqual(rawJSONBoolean, .bool(true))
    }

    func test_subscriptKey_get() {
        let rawJSONDictionary: RawJSON = .dictionary([
            "price": .number(23),
            "destination": .string("Lisbon")
        ])
        XCTAssertEqual(rawJSONDictionary["price"]?.numberValue, 23)
    }

    func test_subscriptKey_set() {
        var rawJSONDictionary: RawJSON = .dictionary([
            "price": .number(23),
            "destination": .string("Lisbon")
        ])
        rawJSONDictionary["destination"] = .string("Madrid")
        
        XCTAssertEqual(rawJSONDictionary, .dictionary([
            "price": .number(23),
            "destination": .string("Madrid")
        ]))
    }

    func test_subscriptIndex_get() {
        let rawJSONArray: RawJSON = .array([
            .string("Hello"), .string("World")
        ])

        XCTAssertEqual(rawJSONArray[1], .string("World"))
    }

    func test_subscriptIndex_set() {
        var rawJSONArray: RawJSON = .array([
            .string("Hello"), .string("World")
        ])
        rawJSONArray[1] = .string("Stream")

        XCTAssertEqual(rawJSONArray, .array([.string("Hello"), .string("Stream")]))
    }
}
