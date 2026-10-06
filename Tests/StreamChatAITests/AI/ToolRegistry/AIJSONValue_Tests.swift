//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChatAI
import XCTest

final class AIJSONValue_Tests: XCTestCase {
    func test_literals_buildMatchingValues() {
        let value: AIJSONValue = ["a": [nil, true, 1, 1.5, "x"]]

        XCTAssertEqual(value, .object(["a": .array([.null, .bool(true), .int(1), .double(1.5), .string("x")])]))
    }

    func test_stringInterpolation_buildsString() {
        let city = "Skopje"
        let value: AIJSONValue = "Weather in \(city)"

        XCTAssertEqual(value, .string("Weather in Skopje"))
    }

    func test_encode_writesPlainJSON() throws {
        let value: AIJSONValue = ["name": "city", "required": true, "count": 2, "ratio": 0.5, "tags": ["a", nil]]

        let json = try JSONSerialization.jsonObject(with: JSONEncoder().encode(value)) as? NSDictionary

        XCTAssertEqual(json, [
            "name": "city",
            "required": true,
            "count": 2,
            "ratio": 0.5,
            "tags": ["a", NSNull()]
        ] as NSDictionary)
    }

    func test_decode_readsEveryKindOfValue() throws {
        let json = #"{"null":null,"bool":false,"int":3,"double":2.5,"string":"s","array":[1,"a"],"object":{"k":true}}"#

        let value = try JSONDecoder().decode(AIJSONValue.self, from: Data(json.utf8))

        XCTAssertEqual(value, [
            "null": nil,
            "bool": false,
            "int": 3,
            "double": 2.5,
            "string": "s",
            "array": [1, "a"],
            "object": ["k": true]
        ])
    }

    func test_encodeThenDecode_returnsSameValue() throws {
        let value: AIJSONValue = ["type": "object", "properties": ["city": ["type": "string", "enum": ["Skopje", "Amsterdam"]]]]

        let decoded = try JSONDecoder().decode(AIJSONValue.self, from: JSONEncoder().encode(value))

        XCTAssertEqual(decoded, value)
    }

    // MARK: - ClientToolDefinition

    func test_clientToolDefinition_whenCreatedFromMCPTool_readsNameDescriptionAndSchema() throws {
        let tool = MCPStyleTool(
            name: "get_weather",
            title: "Weather",
            description: "Gets the weather for a city.",
            inputSchema: ["type": "object", "properties": ["city": ["type": "string"]]],
            annotations: .init(readOnlyHint: true)
        )

        let definition = try ClientToolDefinition(encoding: tool)

        XCTAssertEqual(definition, ClientToolDefinition(
            name: "get_weather",
            description: "Gets the weather for a city.",
            inputSchema: ["type": "object", "properties": ["city": ["type": "string"]]]
        ))
    }

    func test_clientToolDefinition_whenToolHasNoName_throws() {
        struct Nameless: Encodable { let description = "No name" }

        XCTAssertThrowsError(try ClientToolDefinition(encoding: Nameless()))
    }

    func test_clientToolDefinition_encodesTheMCPToolFields() throws {
        let definition = ClientToolDefinition(name: "get_weather", description: "Weather", inputSchema: ["type": "object"])

        let json = try JSONSerialization.jsonObject(with: JSONEncoder().encode(definition)) as? NSDictionary

        XCTAssertEqual(json, ["name": "get_weather", "description": "Weather", "inputSchema": ["type": "object"]] as NSDictionary)
    }
}

/// The JSON shape of the Model Context Protocol SDK's `Tool`.
private struct MCPStyleTool: Encodable {
    struct Annotations: Encodable {
        var readOnlyHint: Bool?
    }

    var name: String
    var title: String?
    var description: String?
    var inputSchema: AIJSONValue
    var annotations: Annotations
}
