//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// Defines the transport surface for A2A JSON-RPC interactions.
/// Implementations fetch agent cards and send messages over HTTP or other channels.
@MainActor
public protocol A2AClientProtocol {
    /// Loads the agent card and returns parsed metadata.
    /// Use this to discover the RPC endpoint and supported capabilities.
    func getAgentCard() async throws -> A2AAgentCard

    /// Starts a `message/stream` request and yields SSE events.
    /// The stream ends when the server closes the connection or an error occurs.
    func sendMessageStream(_ payload: A2AMessageSendParams) -> AsyncThrowingStream<A2ASendStreamMessageResponse, Error>

    /// Sends a `message/send` request and waits for completion.
    /// Throws if the RPC call fails or returns an error response.
    func sendMessage(_ payload: A2AMessageSendParams) async throws
}

/// Supplies authentication headers and retry logic for A2A requests.
/// Implement this to inject tokens and refresh them on authentication failures.
public protocol A2AAuthenticationHandler: Sendable {
    var headers: [String: String] { get async }

    /// Decides whether a failed request should be retried with new headers.
    /// Return updated headers to retry, or nil to propagate the error.
    func shouldRetryWithHeaders(
        request: URLRequest,
        response: HTTPURLResponse,
        body: Data?
    ) async -> [String: String]?

    /// Notifies the handler after a successful retry.
    /// Use this to persist refreshed credentials.
    func onSuccessfulRetry(_ headers: [String: String]) async
}

/// Describes optional features advertised by an A2A agent.
/// Check these flags before attempting streaming or push notifications.
public struct A2AAgentCapabilities: Sendable {
    public let streaming: Bool?
    public let pushNotifications: Bool?

    /// The protocol extensions advertised by the agent.
    ///
    /// A2UI agents declare their supported catalogs here, under the extension
    /// URI `https://a2ui.org/a2a-extension/a2ui/v1.0`.
    public let extensions: [A2AAgentExtension]

    /// Creates a capabilities container with optional flags.
    /// Use nil when the agent card omits a capability.
    public init(
        streaming: Bool? = nil,
        pushNotifications: Bool? = nil,
        extensions: [A2AAgentExtension] = []
    ) {
        self.streaming = streaming
        self.pushNotifications = pushNotifications
        self.extensions = extensions
    }

    /// Builds capabilities from a JSON map.
    /// Missing fields are treated as `nil`.
    public static func fromJson(_ json: JsonMap) -> A2AAgentCapabilities {
        A2AAgentCapabilities(
            streaming: json["streaming"] as? Bool,
            pushNotifications: json["pushNotifications"] as? Bool,
            extensions: (Json.array(json["extensions"]) ?? []).compactMap { entry in
                guard let map = Json.map(entry) else { return nil }
                return A2AAgentExtension.fromJson(map)
            }
        )
    }

    /// Serializes the capabilities to a JSON map.
    /// Omits fields that are `nil`.
    public func toJson() -> JsonMap {
        var json: JsonMap = [:]
        if let streaming { json["streaming"] = streaming }
        if let pushNotifications { json["pushNotifications"] = pushNotifications }
        if !extensions.isEmpty { json["extensions"] = extensions.map { $0.toJson() } }
        return json
    }
}

/// A protocol extension advertised in an A2A agent card.
public struct A2AAgentExtension: Sendable {
    /// The canonical URI of the extension.
    public let uri: String

    /// A human-readable description of the extension.
    public let description: String?

    /// Whether the agent requires the extension to be activated.
    public let required: Bool

    /// Extension-specific parameters.
    public let params: JsonMap?

    /// Creates an extension declaration.
    /// A2UI agents put their capabilities in `params`.
    public init(uri: String, description: String? = nil, required: Bool = false, params: JsonMap? = nil) {
        self.uri = uri
        self.description = description
        self.required = required
        self.params = params
    }

    /// Parses an extension declaration.
    /// Returns nil when the URI is missing.
    public static func fromJson(_ json: JsonMap) -> A2AAgentExtension? {
        guard let uri = json["uri"] as? String else { return nil }
        return A2AAgentExtension(
            uri: uri,
            description: json["description"] as? String,
            required: Json.bool(json["required"]) ?? false,
            params: Json.map(json["params"])
        )
    }

    /// Serializes the declaration to a JSON map.
    public func toJson() -> JsonMap {
        var json: JsonMap = ["uri": uri, "required": required]
        if let description { json["description"] = description }
        if let params { json["params"] = params }
        return json
    }
}

/// Describes an A2A agent-card document.
/// Includes display metadata, endpoint URL, and capability flags.
public struct A2AAgentCard: Sendable {
    public let name: String
    public let description: String
    public let version: String
    public let url: String
    public let capabilities: A2AAgentCapabilities?

    /// Creates a fully populated agent card.
    /// Prefer `fromJson` when parsing server responses.
    public init(
        name: String,
        description: String,
        version: String,
        url: String,
        capabilities: A2AAgentCapabilities? = nil
    ) {
        self.name = name
        self.description = description
        self.version = version
        self.url = url
        self.capabilities = capabilities
    }

    /// The A2UI capabilities the agent advertises, if any.
    ///
    /// Renderers use this to decide whether to attach
    /// `a2uiRendererCapabilities` metadata and inline catalogs.
    public var a2uiCapabilities: AgentCapabilities? {
        guard let params = capabilities?.extensions
            .first(where: { $0.uri == A2UIProtocol.a2aExtensionUri })?
            .params else {
            return nil
        }
        return AgentCapabilities.fromJson(params)
    }

    /// Parses an agent card response.
    /// Throws if the response is missing a usable endpoint URL.
    public static func fromJson(_ json: JsonMap) throws -> A2AAgentCard {
        let url = json["url"] as? String ?? ""
        if url.isEmpty {
            throw A2AClientError.invalidAgentCard
        }
        let capabilitiesJson = json["capabilities"] as? JsonMap
        return A2AAgentCard(
            name: json["name"] as? String ?? "",
            description: json["description"] as? String ?? "",
            version: json["version"] as? String ?? "",
            url: url,
            capabilities: capabilitiesJson.map { A2AAgentCapabilities.fromJson($0) }
        )
    }
}

/// Encodes a JSON-RPC 2.0 request for A2A endpoints.
/// Carries the method name, request id, and parameters.
public struct A2AJsonRpcRequest: Sendable {
    public let jsonrpc: String
    public let method: String
    public let id: Int
    public let params: JsonMap

    /// Creates a JSON-RPC request wrapper.
    /// Uses the JSON-RPC 2.0 protocol version.
    public init(method: String, id: Int, params: JsonMap) {
        self.jsonrpc = "2.0"
        self.method = method
        self.id = id
        self.params = params
    }

    /// Serializes the request to a JSON map.
    /// This payload is sent to the A2A endpoint.
    public func toJson() -> JsonMap {
        [
            "jsonrpc": jsonrpc,
            "method": method,
            "id": id,
            "params": params
        ]
    }
}

/// Base protocol for parts inside an A2A message.
/// Concrete parts encode text, structured data, or files.
public protocol A2APart: Sendable {
    /// Serializes the part to a JSON map.
    /// The result is used as the wire-format payload.
    func toJson() -> JsonMap
}

/// Message part containing plain text.
/// Encoded with a `"type": "text"` discriminator.
public struct A2ATextPart: A2APart, Sendable {
    public var text: String

    /// Creates a text part with optional content.
    /// Defaults to an empty string.
    public init(text: String = "") {
        self.text = text
    }

    /// Serializes the part to a JSON map.
    /// The output is suitable for transport or logging.
    public func toJson() -> JsonMap {
        ["kind": "text", "type": "text", "text": text]
    }

    /// Parses a text part from a JSON map.
    /// Returns nil if the payload is not a text part.
    public static func fromJson(_ json: JsonMap) -> A2ATextPart? {
        let kind = (json["type"] as? String) ?? (json["kind"] as? String)
        guard kind == "text" else { return nil }
        return A2ATextPart(text: json["text"] as? String ?? "")
    }
}

/// Message part containing structured data.
///
/// A2UI carries its messages in data parts whose `data` field is an array of
/// A2UI messages, so the payload is stored as an untyped JSON value.
public struct A2ADataPart: A2APart, Sendable {
    /// The JSON payload of the part.
    public var data: any Sendable

    /// Part metadata, such as the A2UI MIME type.
    public var metadata: JsonMap?

    /// Creates a data part with an arbitrary JSON payload.
    /// Include the A2UI MIME type in `metadata` for A2UI payloads.
    public init(data: any Sendable = JsonMap(), metadata: JsonMap? = nil) {
        self.data = data
        self.metadata = metadata
    }

    /// The payload as a JSON object, when it is one.
    public var dataMap: JsonMap? {
        Json.map(data)
    }

    /// The payload as a JSON array, when it is one.
    public var dataArray: JsonArray? {
        Json.array(data)
    }

    /// Serializes the part to a JSON map.
    /// The output is suitable for transport or logging.
    public func toJson() -> JsonMap {
        var json: JsonMap = ["kind": "data", "type": "data", "data": data]
        if let metadata {
            json["metadata"] = metadata
        }
        return json
    }

    /// Parses a data part from a JSON map.
    /// Returns nil if the payload is not a data part.
    public static func fromJson(_ json: JsonMap) -> A2ADataPart? {
        let kind = (json["type"] as? String) ?? (json["kind"] as? String)
        guard kind == "data", let data = json["data"] else { return nil }
        var metadata = json["metadata"] as? JsonMap
        if let mimeType = json["mimeType"] as? String {
            if metadata == nil { metadata = [:] }
            metadata?["mimeType"] = mimeType
        }
        return A2ADataPart(data: data, metadata: metadata)
    }
}

/// Message part describing an attached file.
/// Wraps either a URI reference or base64-encoded bytes.
public struct A2AFilePart: A2APart, Sendable {
    public var file: A2AFile

    /// Creates a file part for the provided file payload.
    /// Provide either a URI or base64 bytes representation.
    public init(file: A2AFile) {
        self.file = file
    }

    /// Serializes the part to a JSON map.
    /// The output is suitable for transport or logging.
    public func toJson() -> JsonMap {
        ["kind": "file", "type": "file", "file": file.toJson()]
    }

    /// Parses a file part from a JSON map.
    /// Returns nil if the payload is not a file part.
    public static func fromJson(_ json: JsonMap) -> A2AFilePart? {
        let kind = (json["type"] as? String) ?? (json["kind"] as? String)
        guard kind == "file" else { return nil }
        guard let fileJson = json["file"] as? JsonMap else { return nil }
        if let uri = fileJson["uri"] as? String {
            let mimeType = fileJson["mimeType"] as? String ?? ""
            return A2AFilePart(file: A2AFileWithUri(uri: uri, mimeType: mimeType))
        }
        if let bytes = fileJson["bytes"] as? String {
            let mimeType = fileJson["mimeType"] as? String ?? ""
            return A2AFilePart(file: A2AFileWithBytes(bytes: bytes, mimeType: mimeType))
        }
        return nil
    }
}

/// Protocol for A2A file payload encodings.
/// Implementations serialize either a URI or inline bytes.
public protocol A2AFile: Sendable {
    /// Serializes the file payload to a JSON map.
    /// Used when sending A2A file parts.
    func toJson() -> JsonMap
}

/// File payload that references a remote URI.
/// Use this when the file is hosted elsewhere.
public struct A2AFileWithUri: A2AFile, Sendable {
    public var uri: String
    public var mimeType: String

    /// Creates a URI-based file payload.
    /// Provide the URI and associated MIME type.
    public init(uri: String, mimeType: String) {
        self.uri = uri
        self.mimeType = mimeType
    }

    /// Serializes the payload to a JSON map.
    /// The output is suitable for transport or logging.
    public func toJson() -> JsonMap {
        ["uri": uri, "mimeType": mimeType]
    }
}

/// File payload carrying base64-encoded bytes.
/// Use this when you need inline file transfer.
public struct A2AFileWithBytes: A2AFile, Sendable {
    public var bytes: String
    public var mimeType: String

    /// Creates a bytes-based file payload.
    /// Provide base64 bytes and the associated MIME type.
    public init(bytes: String, mimeType: String) {
        self.bytes = bytes
        self.mimeType = mimeType
    }

    /// Serializes the payload to a JSON map.
    /// The output is suitable for transport or logging.
    public func toJson() -> JsonMap {
        ["bytes": bytes, "mimeType": mimeType]
    }
}

/// Marker protocol for A2A result payloads.
/// Implemented by message, task, and status update types.
extension A2AMessage {
    // Unknown or unsupported parts are ignored.
    static func parts(from raw: (any Sendable)?) -> [A2APart] {
        (Json.array(raw) ?? []).compactMap { entry in
            guard let partJson = Json.map(entry) else { return nil }
            if let text = A2ATextPart.fromJson(partJson) { return text }
            if let data = A2ADataPart.fromJson(partJson) { return data }
            if let file = A2AFilePart.fromJson(partJson) { return file }
            return nil
        }
    }
}

public protocol A2AResult: Sendable {
    /// Serializes the result to a JSON map.
    /// Used for logging or transport.
    func toJson() -> JsonMap
}

/// A2A message envelope containing role and parts.
/// Supports task references, context ids, and metadata payloads.
public struct A2AMessage: A2AResult, Sendable {
    public var messageId: String
    public var role: String
    public var parts: [A2APart]
    public var referenceTaskIds: [String]?
    public var taskId: String?
    public var contextId: String?
    public var metadata: JsonMap?

    /// Creates a message with optional task and context metadata.
    /// Defaults the role to `"user"` and generates a message id.
    public init(
        messageId: String = UUID().uuidString,
        role: String = "user",
        parts: [A2APart] = [],
        referenceTaskIds: [String]? = nil,
        taskId: String? = nil,
        contextId: String? = nil,
        metadata: JsonMap? = nil
    ) {
        self.messageId = messageId
        self.role = role
        self.parts = parts
        self.referenceTaskIds = referenceTaskIds
        self.taskId = taskId
        self.contextId = contextId
        self.metadata = metadata
    }

    /// Parses a message from a JSON map.
    /// Unknown or unsupported parts are ignored.
    public static func fromJson(_ json: JsonMap) -> A2AMessage {
        A2AMessage(
            messageId: json["messageId"] as? String ?? "",
            role: json["role"] as? String ?? "",
            parts: parts(from: json["parts"]),
            referenceTaskIds: json["referenceTaskIds"] as? [String],
            taskId: json["taskId"] as? String,
            contextId: json["contextId"] as? String,
            metadata: json["metadata"] as? JsonMap
        )
    }

    /// Serializes the message to a JSON map.
    /// The output is suitable for transport or logging.
    public func toJson() -> JsonMap {
        var json: JsonMap = [
            "messageId": messageId,
            "role": role,
            "kind": "message",
            "parts": parts.map { $0.toJson() }
        ]
        if let referenceTaskIds {
            json["referenceTaskIds"] = referenceTaskIds
        }
        if let taskId {
            json["taskId"] = taskId
        }
        if let contextId {
            json["contextId"] = contextId
        }
        if let metadata {
            json["metadata"] = metadata
        }
        return json
    }
}

/// Parameters for `message/send` and `message/stream`.
/// Wraps the message plus optional extension identifiers.
public struct A2AMessageSendParams: Sendable {
    public var message: A2AMessage
    public var extensions: [String]

    /// Creates send parameters with optional extension ids.
    /// Extensions are sent via the `X-A2A-Extensions` header.
    public init(message: A2AMessage, extensions: [String] = []) {
        self.message = message
        self.extensions = extensions
    }

    /// Serializes the parameters to a JSON map.
    /// The output is suitable for transport or logging.
    public func toJson() -> JsonMap {
        var json: JsonMap = ["message": message.toJson()]
        if !extensions.isEmpty {
            json["extensions"] = extensions
        }
        return json
    }
}

/// Base protocol for SSE responses from `message/stream`.
/// Use `isError` to differentiate error and success events.
public protocol A2ASendStreamMessageResponse: Sendable {
    var isError: Bool { get }
    func toJson() -> JsonMap
}

/// Streaming event that carries a JSON-RPC error.
/// Use when the SSE payload includes an error response.
public struct A2AJSONRPCErrorResponseSSM: A2ASendStreamMessageResponse, Sendable {
    public var error: A2AError?
    public var id: Int?

    /// Creates an error response wrapper.
    /// Provide the parsed error and optional response id.
    public init(error: A2AError? = nil, id: Int? = nil) {
        self.error = error
        self.id = id
    }

    public var isError: Bool { true }

    /// Serializes the response to a JSON map.
    /// The output is suitable for transport or logging.
    public func toJson() -> JsonMap {
        ["error": error?.toJson() as any Sendable, "id": id as any Sendable]
    }
}

/// Streaming event that carries a successful result.
/// The result may be a message, task, or status update.
public struct A2ASendStreamMessageSuccessResponse: A2ASendStreamMessageResponse, Sendable {
    public var result: A2AResult?
    public var id: Int?

    /// Creates a success response wrapper.
    /// Provide the result and optional response id.
    public init(result: A2AResult? = nil, id: Int? = nil) {
        self.result = result
        self.id = id
    }

    public var isError: Bool { false }

    /// Serializes the response to a JSON map.
    /// The output is suitable for transport or logging.
    public func toJson() -> JsonMap {
        ["result": result?.toJson() as any Sendable, "id": id as any Sendable]
    }
}

/// JSON-RPC error payload returned by the A2A server.
/// Carries the error code and human-readable message.
public struct A2AError: Sendable {
    public var rpcErrorCode: Int?
    public var message: String?

    /// Creates an error payload with optional fields.
    /// Use nil values to omit fields.
    public init(rpcErrorCode: Int? = nil, message: String? = nil) {
        self.rpcErrorCode = rpcErrorCode
        self.message = message
    }

    /// Parses an error object from a JSON map.
    /// Missing fields are treated as nil.
    public static func fromJson(_ json: JsonMap) -> A2AError {
        A2AError(
            rpcErrorCode: json["code"] as? Int,
            message: json["message"] as? String
        )
    }

    /// Serializes the error to a JSON map.
    /// The output is suitable for transport or logging.
    public func toJson() -> JsonMap {
        ["rpcErrorCode": rpcErrorCode as any Sendable, "message": message as any Sendable]
    }
}

/// Task container returned by the A2A API.
/// Includes identifiers plus an optional status payload.
public struct A2ATask: A2AResult, Sendable {
    public var id: String
    public var contextId: String?
    public var status: A2ATaskStatus?
    /// The outputs the agent produced for the task.
    public var artifacts: [A2AArtifact]

    /// Creates a task with optional context, status and artifacts.
    /// Use this when constructing task results manually.
    public init(id: String, contextId: String? = nil, status: A2ATaskStatus? = nil, artifacts: [A2AArtifact] = []) {
        self.id = id
        self.contextId = contextId
        self.status = status
        self.artifacts = artifacts
    }

    /// Parses a task payload from a JSON map.
    /// Reads the id plus optional status, context and artifacts.
    public static func fromJson(_ json: JsonMap) -> A2ATask {
        let statusJson = json["status"] as? JsonMap
        return A2ATask(
            id: json["id"] as? String ?? "",
            contextId: json["contextId"] as? String,
            status: statusJson.map { A2ATaskStatus.fromJson($0) },
            artifacts: (Json.array(json["artifacts"]) ?? []).compactMap { Json.map($0).map(A2AArtifact.fromJson) }
        )
    }

    /// Serializes the task to a JSON map.
    /// The output is suitable for transport or logging.
    public func toJson() -> JsonMap {
        var json: JsonMap = ["id": id, "kind": "task"]
        if let contextId {
            json["contextId"] = contextId
        }
        if let status {
            json["status"] = status.toJson()
        }
        if !artifacts.isEmpty {
            json["artifacts"] = artifacts.map { $0.toJson() as any Sendable }
        }
        return json
    }
}

/// An output of a task: a named set of parts.
public struct A2AArtifact: Sendable {
    public var artifactId: String
    public var name: String?
    public var parts: [A2APart]

    /// Creates an artifact.
    public init(artifactId: String, name: String? = nil, parts: [A2APart] = []) {
        self.artifactId = artifactId
        self.name = name
        self.parts = parts
    }

    /// Parses an artifact from a JSON map. Unknown parts are ignored.
    public static func fromJson(_ json: JsonMap) -> A2AArtifact {
        A2AArtifact(
            artifactId: json["artifactId"] as? String ?? "",
            name: json["name"] as? String,
            parts: A2AMessage.parts(from: json["parts"])
        )
    }

    /// Serializes the artifact to a JSON map.
    public func toJson() -> JsonMap {
        var json: JsonMap = ["artifactId": artifactId, "parts": parts.map { $0.toJson() as any Sendable }]
        if let name { json["name"] = name }
        return json
    }
}

/// Streaming event that delivers an artifact, or a chunk of one, as the agent produces it.
public struct A2ATaskArtifactUpdateEvent: A2AResult, Sendable {
    public var taskId: String?
    public var contextId: String?
    public var artifact: A2AArtifact
    /// Whether the parts add to an artifact sent earlier.
    public var append: Bool
    /// Whether this is the artifact's last chunk.
    public var lastChunk: Bool

    /// Creates an artifact update.
    public init(taskId: String? = nil, contextId: String? = nil, artifact: A2AArtifact, append: Bool = false, lastChunk: Bool = false) {
        self.taskId = taskId
        self.contextId = contextId
        self.artifact = artifact
        self.append = append
        self.lastChunk = lastChunk
    }

    /// Parses an artifact update from a JSON map.
    public static func fromJson(_ json: JsonMap) -> A2ATaskArtifactUpdateEvent {
        A2ATaskArtifactUpdateEvent(
            taskId: json["taskId"] as? String,
            contextId: json["contextId"] as? String,
            artifact: A2AArtifact.fromJson(Json.map(json["artifact"]) ?? [:]),
            append: Json.bool(json["append"]) ?? false,
            lastChunk: Json.bool(json["lastChunk"]) ?? false
        )
    }

    /// Serializes the update to a JSON map.
    public func toJson() -> JsonMap {
        var json: JsonMap = ["kind": "artifact-update", "artifact": artifact.toJson(), "append": append, "lastChunk": lastChunk]
        if let taskId { json["taskId"] = taskId }
        if let contextId { json["contextId"] = contextId }
        return json
    }
}

/// Latest status snapshot for a task.
/// Holds the most recent message payload, if available.
public struct A2ATaskStatus: Sendable {
    public var message: A2AMessage?

    /// Creates a status payload with an optional message.
    /// Use nil when no message is available.
    public init(message: A2AMessage? = nil) {
        self.message = message
    }

    /// Parses task status from a JSON map.
    /// Reads the embedded message payload if present.
    public static func fromJson(_ json: JsonMap) -> A2ATaskStatus {
        let messageJson = json["message"] as? JsonMap
        return A2ATaskStatus(message: messageJson.map { A2AMessage.fromJson($0) })
    }

    /// Serializes the status to a JSON map.
    /// The output is suitable for transport or logging.
    public func toJson() -> JsonMap {
        ["message": message?.toJson() as any Sendable]
    }
}

/// Streaming event that reports task progress.
/// Carries identifiers, status payload, and an optional end flag.
public struct A2ATaskStatusUpdateEvent: A2AResult, Sendable {
    public var taskId: String?
    public var contextId: String?
    public var status: A2ATaskStatus?
    public var end: Bool?

    /// Creates a status update event with optional fields.
    /// Use nil to omit identifiers or status data.
    public init(
        taskId: String? = nil,
        contextId: String? = nil,
        status: A2ATaskStatus? = nil,
        end: Bool? = nil
    ) {
        self.taskId = taskId
        self.contextId = contextId
        self.status = status
        self.end = end
    }

    /// Parses a status update from a JSON map.
    /// Reads identifiers, nested status, and end flag.
    public static func fromJson(_ json: JsonMap) -> A2ATaskStatusUpdateEvent {
        let statusJson = json["status"] as? JsonMap
        return A2ATaskStatusUpdateEvent(
            taskId: json["taskId"] as? String,
            contextId: json["contextId"] as? String,
            status: statusJson.map { A2ATaskStatus.fromJson($0) },
            end: json["end"] as? Bool
        )
    }

    /// Serializes the update to a JSON map.
    /// The output is suitable for transport or logging.
    public func toJson() -> JsonMap {
        var json: JsonMap = [:]
        if let taskId { json["taskId"] = taskId }
        if let contextId { json["contextId"] = contextId }
        if let status { json["status"] = status.toJson() }
        if let end { json["end"] = end }
        return json
    }
}

/// Errors thrown by A2A client implementations.
/// Covers validation, HTTP, and parsing failures.
public enum A2AClientError: Error, CustomStringConvertible, Sendable {
    /// The agent card was missing or did not contain an endpoint URL.
    case invalidAgentCard
    /// The agent does not support streaming responses.
    case streamingNotSupported
    /// The response was not a valid A2A payload.
    case invalidResponse
    /// The response content type was not the expected one.
    case invalidContentType
    /// The response id did not match the request id.
    case responseIdMismatch
    /// The agent returned a JSON-RPC error.
    case serverError(code: Int, message: String)

    /// A human-readable description of the failure.
    public var description: String {
        switch self {
        case .invalidAgentCard:
            return "The agent card is missing or does not contain an endpoint URL."
        case .streamingNotSupported:
            return "The agent does not support streaming responses."
        case .invalidResponse:
            return "The agent returned an invalid response."
        case .invalidContentType:
            return "The agent returned an unexpected content type."
        case .responseIdMismatch:
            return "The agent returned a response for a different request."
        case let .serverError(code, message):
            return "The agent returned error \(code): \(message)"
        }
    }
}

/// URLSession-based A2A client implementation.
/// Handles agent-card discovery, JSON-RPC requests, and SSE streaming.
@MainActor
public final class A2AClient: A2AClientProtocol {
    public let agentBaseUrl: String
    public let agentCardPath: String
    public var customHeaders: [String: String]
    public var authenticationHandler: A2AAuthenticationHandler?

    private var serviceEndpointUrl: String?
    private var agentCard: A2AAgentCard?
    private var requestIdCounter: Int = 1
    private let session: URLSession

    /// Creates a client for the given agent base URL.
    /// Optionally prefetches the agent card in the background.
    public init(
        baseUrl: String,
        cardPath: String = "/.well-known/agent-card.json",
        customHeaders: [String: String] = [:],
        authenticationHandler: A2AAuthenticationHandler? = nil,
        agentCardBackgroundFetch: Bool = true,
        session: URLSession = .shared
    ) {
        self.agentBaseUrl = baseUrl.replacingOccurrences(of: "/$", with: "", options: .regularExpression)
        self.agentCardPath = cardPath
        self.customHeaders = customHeaders
        self.authenticationHandler = authenticationHandler
        self.serviceEndpointUrl = self.agentBaseUrl
        self.session = session

        if agentCardBackgroundFetch {
            Task {
                _ = try? await fetchAndCacheAgentCard(baseUrl: nil, cardPath: nil)
            }
        }
    }

    /// Fetches and caches the agent card.
    /// Updates the service endpoint URL when available.
    public func getAgentCard() async throws -> A2AAgentCard {
        try await fetchAndCacheAgentCard(baseUrl: nil, cardPath: nil)
    }

    /// Sends a `message/send` request to the agent.
    /// Throws if the response is invalid or indicates failure.
    public func sendMessage(_ payload: A2AMessageSendParams) async throws {
        _ = try await postRpcRequest(method: "message/send", params: payload)
    }

    /// Sends a `message/stream` request and returns an SSE stream.
    /// Throws if streaming is unsupported or the SSE payload is invalid.
    public func sendMessageStream(_ payload: A2AMessageSendParams) -> AsyncThrowingStream<A2ASendStreamMessageResponse, Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    let endpoint = try await serviceEndpoint()
                    let requestId = nextRequestId()
                    let rpcRequest = A2AJsonRpcRequest(
                        method: "message/stream",
                        id: requestId,
                        params: payload.toJson()
                    )

                    var request = URLRequest(url: endpoint)
                    request.httpMethod = "POST"
                    request.setValue("text/event-stream", forHTTPHeaderField: "Accept")
                    request.setValue("application/json", forHTTPHeaderField: "Content-Type")

                    var headers = customHeaders
                    if let authHeaders = await authenticationHandler?.headers {
                        headers.merge(authHeaders) { _, new in new }
                    }
                    if !payload.extensions.isEmpty {
                        headers["X-A2A-Extensions"] = payload.extensions.joined(separator: ",")
                    }
                    for (key, value) in headers {
                        request.setValue(value, forHTTPHeaderField: key)
                    }
                    request.httpBody = try JSONSerialization.data(withJSONObject: rpcRequest.toJson())

                    let (bytes, httpResponse) = try await streamWithAuthenticationRetry(request)
                    guard let contentType = httpResponse.value(forHTTPHeaderField: "Content-Type"),
                          contentType.starts(with: "text/event-stream") else {
                        throw A2AClientError.invalidContentType
                    }

                    for try await line in bytes.lines {
                        guard line.hasPrefix("data:") else { continue }
                        let payloadString = line.dropFirst(5).drop { $0 == " " }
                        guard let data = String(payloadString).data(using: .utf8),
                              let json = Json.decodeMap(data) else {
                            continue
                        }
                        let response = try parseStreamResponse(json, requestId: requestId)
                        continuation.yield(response)
                    }

                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    private func streamWithAuthenticationRetry(_ request: URLRequest) async throws -> (URLSession.AsyncBytes, HTTPURLResponse) {
        let (bytes, httpResponse) = try await openStream(request)
        if (200..<300).contains(httpResponse.statusCode) {
            return (bytes, httpResponse)
        }
        guard let authHandler = authenticationHandler else {
            throw A2AClientError.invalidResponse
        }
        let body = try await Self.errorBody(of: bytes)
        guard let retryHeaders = await authHandler.shouldRetryWithHeaders(request: request, response: httpResponse, body: body) else {
            throw A2AClientError.invalidResponse
        }
        var retryRequest = request
        for (key, value) in retryHeaders {
            retryRequest.setValue(value, forHTTPHeaderField: key)
        }
        let (retryBytes, retryResponse) = try await openStream(retryRequest)
        guard (200..<300).contains(retryResponse.statusCode) else {
            throw A2AClientError.invalidResponse
        }
        await authHandler.onSuccessfulRetry(retryHeaders)
        return (retryBytes, retryResponse)
    }

    private func openStream(_ request: URLRequest) async throws -> (URLSession.AsyncBytes, HTTPURLResponse) {
        let (bytes, response) = try await session.bytes(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw A2AClientError.invalidResponse
        }
        return (bytes, httpResponse)
    }

    private static func errorBody(of bytes: URLSession.AsyncBytes) async throws -> Data {
        var body = Data()
        for try await byte in bytes {
            body.append(byte)
            if body.count >= maxErrorBodyLength { break }
        }
        return body
    }

    private static let maxErrorBodyLength = 64 * 1024

    private func serviceEndpoint() async throws -> URL {
        if let serviceEndpointUrl, let url = URL(string: serviceEndpointUrl) {
            return url
        }
        let card = try await fetchAndCacheAgentCard(baseUrl: nil, cardPath: nil)
        guard let url = URL(string: card.url) else {
            throw A2AClientError.invalidAgentCard
        }
        return url
    }

    private func nextRequestId() -> Int {
        defer { requestIdCounter += 1 }
        return requestIdCounter
    }

    private func fetchAndCacheAgentCard(baseUrl: String?, cardPath: String?) async throws -> A2AAgentCard {
        let base = (baseUrl?.isEmpty == false) ? baseUrl! : agentBaseUrl
        let path = (cardPath?.isEmpty == false) ? cardPath! : agentCardPath
        let urlString = "\(base)\(path)"
        guard let url = URL(string: urlString) else {
            throw A2AClientError.invalidAgentCard
        }

        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        var headers = customHeaders
        if let authHeaders = await authenticationHandler?.headers {
            headers.merge(authHeaders) { _, new in new }
        }
        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              (200..<300).contains(httpResponse.statusCode) else {
            throw A2AClientError.invalidResponse
        }

        guard let json = Json.decodeMap(data) else {
            throw A2AClientError.invalidAgentCard
        }
        let card = try A2AAgentCard.fromJson(json)
        serviceEndpointUrl = card.url
        agentCard = card
        return card
    }

    private func postRpcRequest(method: String, params: A2AMessageSendParams) async throws -> JsonMap {
        let endpoint = try await serviceEndpoint()
        let requestId = nextRequestId()
        let rpcRequest = A2AJsonRpcRequest(method: method, id: requestId, params: params.toJson())

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        var headers = customHeaders
        if let authHeaders = await authenticationHandler?.headers {
            headers.merge(authHeaders) { _, new in new }
        }
        if !params.extensions.isEmpty {
            headers["X-A2A-Extensions"] = params.extensions.joined(separator: ",")
        }
        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }
        request.httpBody = try JSONSerialization.data(withJSONObject: rpcRequest.toJson())

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw A2AClientError.invalidResponse
        }

        if let authHandler = authenticationHandler,
           let retryHeaders = await authHandler.shouldRetryWithHeaders(request: request, response: httpResponse, body: data) {
            var retryRequest = request
            for (key, value) in retryHeaders {
                retryRequest.setValue(value, forHTTPHeaderField: key)
            }
            let (retryData, retryResponse) = try await session.data(for: retryRequest)
            guard let retryHttp = retryResponse as? HTTPURLResponse,
                  (200..<300).contains(retryHttp.statusCode) else {
                throw A2AClientError.invalidResponse
            }
            await authHandler.onSuccessfulRetry(retryHeaders)
            guard let retryJson = Json.decodeMap(retryData) else {
                throw A2AClientError.invalidResponse
            }
            return retryJson
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            throw A2AClientError.invalidResponse
        }
        guard let json = Json.decodeMap(data) else {
            throw A2AClientError.invalidResponse
        }
        return json
    }

    private func parseStreamResponse(_ json: JsonMap, requestId: Int) throws -> A2ASendStreamMessageResponse {
        if let id = json["id"] as? Int, id != requestId {
            throw A2AClientError.responseIdMismatch
        }
        if let errorJson = json["error"] as? JsonMap {
            return A2AJSONRPCErrorResponseSSM(error: A2AError.fromJson(errorJson), id: json["id"] as? Int)
        }
        let resultJson = json["result"] as? JsonMap
        let result = resultJson.flatMap { parseResult($0) }
        return A2ASendStreamMessageSuccessResponse(result: result, id: json["id"] as? Int)
    }

    private func parseResult(_ json: JsonMap) -> A2AResult? {
        if json["kind"] as? String == "artifact-update" || json["artifact"] != nil {
            return A2ATaskArtifactUpdateEvent.fromJson(json)
        }
        if json["messageId"] != nil {
            return A2AMessage.fromJson(json)
        }
        if json["id"] != nil && json["status"] != nil {
            return A2ATask.fromJson(json)
        }
        if json["status"] != nil && (json["taskId"] != nil || json["end"] != nil) {
            return A2ATaskStatusUpdateEvent.fromJson(json)
        }
        return nil
    }
}
