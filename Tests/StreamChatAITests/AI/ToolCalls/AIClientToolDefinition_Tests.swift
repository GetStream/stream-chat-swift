//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChatAI
import XCTest

final class AIClientToolDefinition_Tests: XCTestCase {
    func test_init_whenCreatedFromMCPTool_readsNameDescriptionAndSchema() throws {
        let tool = MCPStyleTool(
            name: "get_weather",
            title: "Weather",
            description: "Gets the weather for a city.",
            inputSchema: ["type": "object", "properties": ["city": ["type": "string"]]],
            annotations: .init(readOnlyHint: true)
        )

        let definition = try AIClientToolDefinition(encoding: tool)

        XCTAssertEqual(definition, AIClientToolDefinition(
            name: "get_weather",
            description: "Gets the weather for a city.",
            inputSchema: ["type": "object", "properties": ["city": ["type": "string"]]]
        ))
    }

    func test_init_whenToolHasNoName_throws() {
        struct Nameless: Encodable { let description = "No name" }

        XCTAssertThrowsError(try AIClientToolDefinition(encoding: Nameless()))
    }

    func test_encode_writesTheMCPToolFields() throws {
        let definition = AIClientToolDefinition(name: "get_weather", description: "Weather", inputSchema: ["type": "object"])

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
    var inputSchema: RawJSON
    var annotations: Annotations
}
