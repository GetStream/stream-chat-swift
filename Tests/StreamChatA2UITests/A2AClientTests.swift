//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation
@testable import StreamChatA2UI
import Testing

/// Serves canned A2A responses, picked by the request's `X-Scenario` header, path and `Authorization` header.
private final class StubA2AProtocol: URLProtocol {
    struct Response {
        var status = 200
        var contentType = "application/json"
        var body: String
    }

    static let card = #"""
    {"name": "Agent", "description": "Test", "version": "1.0", "url": "https://agent.test/rpc",
     "capabilities": {"streaming": true, "extensions": [{"uri": "https://a2ui.org/a2a-extension/a2ui/v1.0",
       "params": {"supportedCatalogIds": ["https://a2ui.org/specification/v1_0/catalogs/basic/catalog.json"]}}]}}
    """#

    static let streamEvents = [
        #"data:{"jsonrpc": "2.0", "id": 1, "result": {"kind": "status-update", "taskId": "t1", "contextId": "c1", "status": {"state": "working"}, "final": false}}"#,
        "",
        #"data: {"jsonrpc": "2.0", "id": 1, "result": {"kind": "message", "messageId": "m1", "role": "agent", "contextId": "c1", "parts": [{"kind": "text", "text": "Here you go"}, {"kind": "data", "data": [{"version": "1.0", "deleteSurface": {"surfaceId": "a"}}], "metadata": {"mimeType": "application/a2ui+json"}}, {"kind": "file", "file": {"uri": "https://a.b/f.png", "mimeType": "image/png"}}]}}"#,
        ": a comment",
        #"data: {"jsonrpc": "2.0", "id": 1, "result": {"kind": "task", "id": "t1", "contextId": "c1", "status": {"state": "completed"}}}"#
    ].joined(separator: "\n")

    static let responses: [String: Response] = [
        "ok GET /.well-known/agent-card.json": Response(body: card),
        "ok POST /rpc": Response(body: #"{"jsonrpc": "2.0", "id": 2, "result": {"kind": "message", "messageId": "m2", "role": "agent", "parts": []}}"#),
        "ok POST /": Response(contentType: "text/event-stream", body: streamEvents),
        "error POST /": Response(status: 500, body: "{}"),
        "content-type POST /": Response(contentType: "application/json", body: "{}"),
        "mismatch POST /": Response(contentType: "text/event-stream", body: #"data: {"jsonrpc": "2.0", "id": 9, "result": {}}"#),
        "rpc-error POST /": Response(contentType: "text/event-stream", body: #"data: {"jsonrpc": "2.0", "id": 1, "error": {"code": -32600, "message": "Bad request"}}"#),
        "bad-card GET /.well-known/agent-card.json": Response(body: #"{"name": "No url"}"#),
        "artifacts POST /": Response(contentType: "text/event-stream", body: artifactEvents),
        "expired POST / Bearer old": Response(status: 401, body: #"{"error": "token expired"}"#),
        "expired POST / Bearer fresh": Response(contentType: "text/event-stream", body: streamEvents)
    ]

    // An artifact streamed as it's made, then the final task repeating it with one more.
    static let artifactEvents = [
        #"data: {"jsonrpc": "2.0", "id": 1, "result": {"kind": "artifact-update", "taskId": "t2", "contextId": "c2", "append": false, "lastChunk": true, "artifact": {"artifactId": "a1", "name": "ui", "parts": [{"kind": "data", "data": [{"version": "1.0", "deleteSurface": {"surfaceId": "a"}}], "metadata": {"mimeType": "application/a2ui+json"}}]}}}"#,
        #"data: {"jsonrpc": "2.0", "id": 1, "result": {"kind": "task", "id": "t2", "contextId": "c2", "status": {"state": "completed"}, "artifacts": [{"artifactId": "a1", "parts": [{"kind": "data", "data": [{"version": "1.0", "deleteSurface": {"surfaceId": "a"}}], "metadata": {"mimeType": "application/a2ui+json"}}]}, {"artifactId": "a2", "parts": [{"kind": "text", "text": "Done"}, {"kind": "data", "data": [{"version": "1.0", "deleteSurface": {"surfaceId": "b"}}], "metadata": {"mimeType": "application/a2ui+json"}}]}]}}"#
    ].joined(separator: "\n")

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func stopLoading() {}

    override func startLoading() {
        let scenario = request.value(forHTTPHeaderField: "X-Scenario") ?? "ok"
        let authorization = request.value(forHTTPHeaderField: "Authorization").map { " \($0)" } ?? ""
        let key = "\(scenario) \(request.httpMethod ?? "GET") \(request.url?.path.isEmpty == false ? request.url!.path : "/")\(authorization)"
        let response = Self.responses[key] ?? Response(status: 404, body: "{}")
        let http = HTTPURLResponse(
            url: request.url!,
            statusCode: response.status,
            httpVersion: "HTTP/1.1",
            headerFields: ["Content-Type": response.contentType]
        )!
        client?.urlProtocol(self, didReceive: http, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: Data(response.body.utf8))
        client?.urlProtocolDidFinishLoading(self)
    }
}

// Signs requests with an old token and offers `refreshed` when the agent turns one down.
private actor RefreshingAuthentication: A2AAuthenticationHandler {
    let refreshed: String
    private(set) var turnedDownBodies: [String] = []
    private(set) var savedHeaders: [[String: String]] = []

    init(refreshed: String) {
        self.refreshed = refreshed
    }

    var headers: [String: String] {
        ["Authorization": "Bearer old"]
    }

    func shouldRetryWithHeaders(request: URLRequest, response: HTTPURLResponse, body: Data?) -> [String: String]? {
        guard response.statusCode == 401 else { return nil }
        turnedDownBodies.append(String(decoding: body ?? Data(), as: UTF8.self))
        return ["Authorization": "Bearer \(refreshed)"]
    }

    func onSuccessfulRetry(_ headers: [String: String]) {
        savedHeaders.append(headers)
    }
}

@MainActor
@Suite("A2A client")
struct A2AClientTests {
    private func client(_ scenario: String = "ok", authentication: A2AAuthenticationHandler? = nil) -> A2AClient {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [StubA2AProtocol.self]
        return A2AClient(
            baseUrl: "https://agent.test/",
            customHeaders: ["X-Scenario": scenario],
            authenticationHandler: authentication,
            agentCardBackgroundFetch: false,
            session: URLSession(configuration: configuration)
        )
    }

    private func payload() -> A2AMessageSendParams {
        A2AMessageSendParams(
            message: A2AMessage(messageId: "u1", role: "user", parts: [A2ATextPart(text: "Hi")]),
            extensions: [A2UIProtocol.a2aExtensionUri]
        )
    }

    @Test("The agent card is fetched and parsed")
    func agentCard() async throws {
        let card = try await client().getAgentCard()

        #expect(card.url == "https://agent.test/rpc")
        #expect(card.capabilities?.streaming == true)
        #expect(card.capabilities?.extensions.first?.uri == A2UIProtocol.a2aExtensionUri)
        await #expect(throws: A2AClientError.self) { try await client("bad-card").getAgentCard() }
    }

    @Test("A streamed reply yields its events, with or without a space after data:")
    func streaming() async throws {
        var events: [A2ASendStreamMessageResponse] = []
        for try await event in client().sendMessageStream(payload()) {
            events.append(event)
        }

        #expect(events.count == 3)
        let results = events.compactMap { ($0 as? A2ASendStreamMessageSuccessResponse)?.result }
        #expect(results.first is A2ATaskStatusUpdateEvent)
        let message = try #require(results.compactMap { $0 as? A2AMessage }.first)
        #expect(message.parts.count == 3)
        #expect(message.parts.contains { $0 is A2AFilePart })
        #expect(results.last is A2ATask)
    }

    @Test("Stream failures are reported")
    func streamFailures() async throws {
        for scenario in ["error", "content-type", "mismatch"] {
            await #expect(throws: A2AClientError.self, "\(scenario)") {
                for try await _ in client(scenario).sendMessageStream(payload()) {}
            }
        }

        var errors: [A2AJSONRPCErrorResponseSSM] = []
        for try await event in client("rpc-error").sendMessageStream(payload()) {
            if let error = event as? A2AJSONRPCErrorResponseSSM { errors.append(error) }
        }
        #expect(errors.first?.error?.message == "Bad request")
    }

    @Test("A stream turned down for its credentials is retried once with the refreshed ones")
    func streamingRefreshesCredentials() async throws {
        let authentication = RefreshingAuthentication(refreshed: "fresh")
        var events: [A2ASendStreamMessageResponse] = []
        for try await event in client("expired", authentication: authentication).sendMessageStream(payload()) {
            events.append(event)
        }

        #expect(events.count == 3)
        #expect(await authentication.turnedDownBodies == [#"{"error": "token expired"}"#])
        #expect(await authentication.savedHeaders == [["Authorization": "Bearer fresh"]])
    }

    @Test("A stream whose refreshed credentials are turned down too fails without saving them")
    func streamingRefreshFails() async throws {
        let authentication = RefreshingAuthentication(refreshed: "stale")

        await #expect(throws: A2AClientError.self) {
            for try await _ in client("expired", authentication: authentication).sendMessageStream(payload()) {}
        }
        #expect(await authentication.turnedDownBodies.count == 1)
        #expect(await authentication.savedHeaders.isEmpty)
    }

    @Test("message/send posts to the agent card's endpoint")
    func sendMessage() async throws {
        let client = client()
        _ = try await client.getAgentCard()
        try await client.sendMessage(payload())
    }

    @Test("A connector publishes the A2UI messages and text of a streamed reply")
    func connector() async throws {
        let connector = A2UIAgentConnector(url: URL(string: "https://agent.test/")!, client: client())
        var messages: [A2UIMessage] = []
        let cancellable = connector.messages.sink { messages.append($0) }

        let text = await connector.send(GenerationRequest(userMessage: UserMessage.text("Hi")))

        #expect(text == "Here you go")
        #expect(messages.count == 1)
        #expect(connector.contextId == "c1")
        cancellable.cancel()
    }

    @Test("A2UI in task artifacts is published once, whether streamed or in the final task")
    func artifacts() async throws {
        let connector = A2UIAgentConnector(url: URL(string: "https://agent.test/")!, client: client("artifacts"))
        var messages: [A2UIMessage] = []
        let cancellable = connector.messages.sink { messages.append($0) }

        let text = await connector.send(GenerationRequest(userMessage: UserMessage.text("Hi")))

        #expect(messages.count == 2)
        #expect(text == "Done")
        #expect(connector.taskId == "t2")
        #expect(connector.contextId == "c2")
        cancellable.cancel()
    }

    @Test("Artifacts and artifact updates round-trip through JSON")
    func artifactJson() {
        let artifact = A2AArtifact(artifactId: "a1", name: "ui", parts: [A2ATextPart(text: "Hi")])
        let update = A2ATaskArtifactUpdateEvent(taskId: "t", contextId: "c", artifact: artifact, append: true, lastChunk: true)
        let parsed = A2ATaskArtifactUpdateEvent.fromJson(update.toJson())

        #expect(parsed.artifact.artifactId == "a1")
        #expect(parsed.artifact.name == "ui")
        #expect(parsed.artifact.parts.count == 1)
        #expect(parsed.append && parsed.lastChunk)
        #expect(A2ATask.fromJson(A2ATask(id: "t", artifacts: [artifact]).toJson()).artifacts.count == 1)
    }

    @Test("Client errors describe themselves")
    func errorDescriptions() {
        let errors: [A2AClientError] = [
            .invalidAgentCard, .streamingNotSupported, .invalidResponse, .invalidContentType,
            .responseIdMismatch, .serverError(code: 1, message: "m")
        ]
        #expect(Set(errors.map(\.description)).count == errors.count)
    }
}
