//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChatAI
import XCTest

final class ClientToolRegistry_Tests: XCTestCase {
    private var registry: ClientToolRegistry!

    override func setUp() {
        super.setUp()
        registry = ClientToolRegistry()
    }

    override func tearDown() {
        registry = nil
        super.tearDown()
    }

    func test_handleInvocation_whenToolIsRegistered_routesInvocationToTool() {
        let tool = WeatherTool()
        registry.register(tool: tool)
        var performed = false
        tool.actions = [{ performed = true }]

        let actions = registry.handleInvocation(invocation(of: "get_weather", args: #"{"city":"Skopje"}"#))
        actions.forEach { $0() }

        XCTAssertEqual(tool.invocations.count, 1)
        XCTAssertEqual(tool.invocations.first?.args, Data(#"{"city":"Skopje"}"#.utf8))
        XCTAssertEqual(tool.invocations.first?.messageId, "message-1")
        XCTAssertEqual(tool.invocations.first?.channelId, AnyHashable("messaging:general"))
        XCTAssertTrue(performed)
    }

    func test_handleInvocation_whenToolIsNotRegistered_returnsNoActions() {
        let tool = WeatherTool()
        registry.register(tool: tool)

        let actions = registry.handleInvocation(invocation(of: "get_location"))

        XCTAssertTrue(actions.isEmpty)
        XCTAssertTrue(tool.invocations.isEmpty)
    }

    func test_register_whenNameIsTaken_replacesTool() {
        let first = WeatherTool()
        let second = WeatherTool()
        registry.register(tool: first)
        registry.register(tool: second)

        _ = registry.handleInvocation(invocation(of: "get_weather"))

        XCTAssertTrue(first.invocations.isEmpty)
        XCTAssertEqual(second.invocations.count, 1)
        XCTAssertEqual(registry.registrationPayloads().count, 1)
    }

    func test_registrationPayloads_describeEveryRegisteredTool() throws {
        registry.register(tool: WeatherTool())
        registry.register(tool: WeatherTool(name: "get_location", description: nil, showsIndicator: false))

        let payloads = registry.registrationPayloads().sorted { $0.name < $1.name }

        XCTAssertEqual(payloads.map(\.name), ["get_location", "get_weather"])
        XCTAssertEqual(payloads[1].description, "Gets the weather for a city.")
        XCTAssertEqual(payloads[1].instructions, WeatherTool.usage)
        XCTAssertEqual(payloads[1].parameters, WeatherTool.schema)
        XCTAssertEqual(payloads[1].showExternalSourcesIndicator, true)
        XCTAssertEqual(payloads[0].showExternalSourcesIndicator, false)
    }

    func test_registrationPayloads_whenToolHasNoDescription_describeItWithInstructions() {
        registry.register(tool: WeatherTool(description: nil))

        XCTAssertEqual(registry.registrationPayloads().first?.description, WeatherTool.usage)
    }

    func test_registrationPayload_encodesSchemaAsPlainJSON() throws {
        registry.register(tool: WeatherTool())
        let payload = try XCTUnwrap(registry.registrationPayloads().first)

        let json = try JSONSerialization.jsonObject(with: JSONEncoder().encode(payload)) as? NSDictionary

        XCTAssertEqual(json, [
            "name": "get_weather",
            "description": "Gets the weather for a city.",
            "instructions": WeatherTool.usage,
            "parameters": [
                "type": "object",
                "properties": ["city": ["type": "string"]],
                "required": ["city"]
            ],
            "showExternalSourcesIndicator": true
        ] as NSDictionary)
    }

    func test_toolDescriptor_exposesItsFields() {
        let descriptor = ClientToolInvocation.ToolDescriptor(
            name: "get_weather",
            description: "Weather",
            instructions: "Ask first",
            parameters: Data("{}".utf8)
        )

        XCTAssertEqual(descriptor.name, "get_weather")
        XCTAssertEqual(descriptor.description, "Weather")
        XCTAssertEqual(descriptor.instructions, "Ask first")
        XCTAssertEqual(descriptor.parameters, Data("{}".utf8))
    }

    // MARK: - Helpers

    private func invocation(of name: String, args: String? = nil) -> ClientToolInvocation {
        ClientToolInvocation(
            tool: .init(name: name, description: nil, instructions: nil, parameters: nil),
            args: args.map { Data($0.utf8) },
            messageId: "message-1",
            channelId: AnyHashable("messaging:general")
        )
    }
}

private final class WeatherTool: ClientTool {
    static let usage = "Use it when the person asks about the weather."
    static let schema: AIJSONValue = [
        "type": "object",
        "properties": ["city": ["type": "string"]],
        "required": ["city"]
    ]

    let toolDefinition: ClientToolDefinition
    let instructions = WeatherTool.usage
    let showExternalSourcesIndicator: Bool
    var actions: [ClientToolAction] = []
    private(set) var invocations: [ClientToolInvocation] = []

    init(name: String = "get_weather", description: String? = "Gets the weather for a city.", showsIndicator: Bool = true) {
        toolDefinition = ClientToolDefinition(name: name, description: description, inputSchema: Self.schema)
        showExternalSourcesIndicator = showsIndicator
    }

    func handleInvocation(_ invocation: ClientToolInvocation) -> [ClientToolAction] {
        invocations.append(invocation)
        return actions
    }
}
