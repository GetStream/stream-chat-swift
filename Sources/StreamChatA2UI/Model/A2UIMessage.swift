//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// An agent-to-renderer message, as defined by `agent_to_renderer.json`.
///
/// Every wire message is a JSON object carrying a `version` discriminator plus
/// exactly one message key.
@available(iOS 15.0, macOS 12.0, *)
enum A2UIMessage: Equatable, Sendable {
    /// Creates a surface and optionally seeds its components and data.
    case createSurface(CreateSurfaceMessage)

    /// Adds or replaces components of an existing surface.
    case updateComponents(UpdateComponentsMessage)

    /// Patches or replaces the data model of an existing surface.
    case updateDataModel(UpdateDataModelMessage)

    /// Removes a surface and all of its state.
    case deleteSurface(DeleteSurfaceMessage)

    /// Asks the renderer to execute a locally registered function.
    case callRendererFunction(CallRendererFunctionMessage)

    /// Returns the result of a renderer-initiated agent function call.
    case agentFunctionResponse(FunctionResponse)

    /// The id of the surface this message applies to, when it targets one.
    var surfaceId: String? {
        switch self {
        case let .createSurface(message): return message.surfaceId
        case let .updateComponents(message): return message.surfaceId
        case let .updateDataModel(message): return message.surfaceId
        case let .deleteSurface(message): return message.surfaceId
        case .callRendererFunction, .agentFunctionResponse: return nil
        }
    }

    /// The serialized wire representation, including the protocol version.
    func toJson() -> JsonMap {
        var json: JsonMap = [A2UIProtocol.versionKey: A2UIProtocol.version]
        switch self {
        case let .createSurface(message): json["createSurface"] = message.toJson()
        case let .updateComponents(message): json["updateComponents"] = message.toJson()
        case let .updateDataModel(message): json["updateDataModel"] = message.toJson()
        case let .deleteSurface(message): json["deleteSurface"] = message.toJson()
        case let .callRendererFunction(message): json["callRendererFunction"] = message.toJson()
        case let .agentFunctionResponse(message): json["agentFunctionResponse"] = message.toJson()
        }
        return json
    }

    /// Compares two messages by their wire representation.
    static func == (lhs: A2UIMessage, rhs: A2UIMessage) -> Bool {
        Json.isEqual(lhs.toJson(), rhs.toJson())
    }
}

/// Payload of a `createSurface` message.
///
/// Creating a surface implicitly instantiates the reserved `Surface` container
/// whose child is the component with id `root`.
@available(iOS 15.0, macOS 12.0, *)
struct CreateSurfaceMessage: Sendable {
    /// The globally unique id of the new surface.
    let surfaceId: String

    /// The default catalog for components and functions on this surface.
    let catalogId: String?

    /// Whether the renderer attaches this surface's data model to agent messages.
    let sendDataModel: Bool

    /// Components to render immediately, allowing single-message UI creation.
    let components: [Component]

    /// The initial data model of the surface.
    let dataModel: JsonMap?

    /// Surface-level extension metadata.
    let metadata: JsonMap?

    /// Creates a `createSurface` payload.
    /// Pass `components` and `dataModel` to build the UI in a single message.
    init(
        surfaceId: String,
        catalogId: String? = nil,
        sendDataModel: Bool = false,
        components: [Component] = [],
        dataModel: JsonMap? = nil,
        metadata: JsonMap? = nil
    ) {
        self.surfaceId = surfaceId
        self.catalogId = catalogId
        self.sendDataModel = sendDataModel
        self.components = components
        self.dataModel = dataModel
        self.metadata = metadata
    }

    /// Parses the payload of a `createSurface` message.
    /// Throws when the required surface id is missing.
    static func fromJson(_ json: JsonMap) throws -> CreateSurfaceMessage {
        guard let surfaceId = json[surfaceIdKey] as? String, !surfaceId.isEmpty else {
            throw A2UIDecodingError.missingField(surfaceIdKey, in: "createSurface")
        }
        if let raw = json["metadata"] {
            guard let metadata = Json.map(raw) else {
                throw A2UIDecodingError.invalidField("metadata", in: "createSurface", reason: "'metadata' must be an object.")
            }
            if let violation = ExtensionMetadata.violation(in: metadata) {
                throw A2UIDecodingError.invalidField("metadata" + violation.pointer, in: "createSurface", reason: violation.reason)
            }
        }
        return CreateSurfaceMessage(
            surfaceId: surfaceId,
            catalogId: json["catalogId"] as? String,
            sendDataModel: Json.bool(json["sendDataModel"]) ?? false,
            components: A2UIMessageDecoder.components(from: json["components"]),
            dataModel: Json.map(json["dataModel"]),
            metadata: Json.map(json["metadata"])
        )
    }

    /// The serialized wire representation of the payload.
    func toJson() -> JsonMap {
        var json: JsonMap = [surfaceIdKey: surfaceId]
        if let catalogId { json["catalogId"] = catalogId }
        if sendDataModel { json["sendDataModel"] = true }
        if !components.isEmpty { json["components"] = components.map { $0.toJson() } }
        if let dataModel { json["dataModel"] = dataModel }
        if let metadata { json["metadata"] = metadata }
        return json
    }
}

/// Payload of an `updateComponents` message.
@available(iOS 15.0, macOS 12.0, *)
struct UpdateComponentsMessage: Sendable {
    /// The surface to update.
    let surfaceId: String

    /// The components to add or replace.
    let components: [Component]

    /// Creates an `updateComponents` payload.
    /// One component of the surface must eventually use the id `root`.
    init(surfaceId: String, components: [Component]) {
        self.surfaceId = surfaceId
        self.components = components
    }

    /// Parses the payload of an `updateComponents` message.
    /// Throws when the required surface id is missing.
    static func fromJson(_ json: JsonMap) throws -> UpdateComponentsMessage {
        guard let surfaceId = json[surfaceIdKey] as? String, !surfaceId.isEmpty else {
            throw A2UIDecodingError.missingField(surfaceIdKey, in: "updateComponents")
        }
        guard Json.array(json["components"]) != nil else {
            throw A2UIDecodingError.missingField("components", in: "updateComponents")
        }
        return UpdateComponentsMessage(
            surfaceId: surfaceId,
            components: A2UIMessageDecoder.components(from: json["components"])
        )
    }

    /// The serialized wire representation of the payload.
    func toJson() -> JsonMap {
        [surfaceIdKey: surfaceId, "components": components.map { $0.toJson() }]
    }
}

/// Payload of an `updateDataModel` message.
///
/// Updates are upserts: existing paths are replaced, missing paths are created,
/// and an explicit `null` value removes the entry.
@available(iOS 15.0, macOS 12.0, *)
struct UpdateDataModelMessage: Sendable {
    /// The surface whose data model is updated.
    let surfaceId: String

    /// The path to update, defaulting to the whole data model.
    let path: DataPath

    /// The new value, or `nil` to delete the entry at `path`.
    let value: (any Sendable)?

    /// Creates an `updateDataModel` payload.
    /// Omit `path` to replace the entire data model.
    init(surfaceId: String, path: DataPath = .root, value: (any Sendable)?) {
        self.surfaceId = surfaceId
        self.path = path
        self.value = Json.normalized(value)
    }

    /// Parses the payload of an `updateDataModel` message.
    /// Throws when the required surface id is missing.
    static func fromJson(_ json: JsonMap) throws -> UpdateDataModelMessage {
        guard let surfaceId = json[surfaceIdKey] as? String, !surfaceId.isEmpty else {
            throw A2UIDecodingError.missingField(surfaceIdKey, in: "updateDataModel")
        }
        guard json.keys.contains("value") else {
            throw A2UIDecodingError.missingField("value", in: "updateDataModel")
        }
        var path = DataPath.root
        if let rawPath = json["path"] {
            guard let pointer = rawPath as? String, pointer.isEmpty || pointer.hasPrefix("/") else {
                throw A2UIDecodingError.invalidField("path", in: "updateDataModel", reason: "It must be a JSON Pointer.")
            }
            guard DataPath.isValidSyntax(pointer) else {
                throw A2UIDecodingError.invalidField("path", in: "updateDataModel", reason: "Invalid path syntax: '\(pointer)'.")
            }
            path = pointer.isEmpty ? .root : DataPath(pointer)
        }
        return UpdateDataModelMessage(surfaceId: surfaceId, path: path, value: json["value"])
    }

    /// The serialized wire representation of the payload.
    func toJson() -> JsonMap {
        var json: JsonMap = [surfaceIdKey: surfaceId, "value": value ?? NSNull()]
        if !path.isRoot { json["path"] = path.description }
        return json
    }
}

/// Payload of a `deleteSurface` message.
@available(iOS 15.0, macOS 12.0, *)
struct DeleteSurfaceMessage: Sendable {
    /// The surface to remove.
    let surfaceId: String

    /// Creates a `deleteSurface` payload.
    /// The surface and its data model are discarded.
    init(surfaceId: String) {
        self.surfaceId = surfaceId
    }

    /// Parses the payload of a `deleteSurface` message.
    /// Throws when the required surface id is missing.
    static func fromJson(_ json: JsonMap) throws -> DeleteSurfaceMessage {
        guard let surfaceId = json[surfaceIdKey] as? String, !surfaceId.isEmpty else {
            throw A2UIDecodingError.missingField(surfaceIdKey, in: "deleteSurface")
        }
        return DeleteSurfaceMessage(surfaceId: surfaceId)
    }

    /// The serialized wire representation of the payload.
    func toJson() -> JsonMap {
        [surfaceIdKey: surfaceId]
    }
}

/// Payload of a `callRendererFunction` message.
///
/// The renderer must always answer with a `rendererFunctionResponse` or an
/// `error`, even for functions that return no value.
@available(iOS 15.0, macOS 12.0, *)
struct CallRendererFunctionMessage: Sendable {
    /// The id correlating this call with its response.
    let functionCallId: String

    /// The function to execute, including its catalog and arguments.
    let callFunction: FunctionCall

    /// The surface whose data model the arguments are evaluated against.
    ///
    /// When `nil`, the call runs against an empty data model.
    let surfaceId: String?

    /// Creates a `callRendererFunction` payload.
    /// The catalog id is required so the renderer can check the call boundary.
    init(functionCallId: String, callFunction: FunctionCall, surfaceId: String? = nil) {
        self.functionCallId = functionCallId
        self.callFunction = callFunction
        self.surfaceId = surfaceId
    }

    /// Parses the payload of a `callRendererFunction` message.
    ///
    /// Throws ``A2UIDecodingError/invalidFunctionCall(functionCallId:reason:)``
    /// for a malformed call, so the renderer can still answer the agent.
    static func fromJson(_ json: JsonMap) throws -> CallRendererFunctionMessage {
        guard let functionCallId = json["functionCallId"] as? String, !functionCallId.isEmpty else {
            throw A2UIDecodingError.missingField("functionCallId", in: "callRendererFunction")
        }
        guard let callJson = Json.map(json["callFunction"]) else {
            throw A2UIDecodingError.invalidFunctionCall(
                functionCallId: functionCallId,
                reason: "The 'callFunction' object is missing."
            )
        }
        guard callJson["catalogId"] is String else {
            throw A2UIDecodingError.invalidFunctionCall(
                functionCallId: functionCallId,
                reason: "The function call must name its 'catalogId'."
            )
        }
        if let args = callJson["args"], Json.map(args) == nil {
            throw A2UIDecodingError.invalidFunctionCall(
                functionCallId: functionCallId,
                reason: "The function call 'args' must be an object."
            )
        }
        guard let call = FunctionCall(callJson) else {
            throw A2UIDecodingError.invalidFunctionCall(
                functionCallId: functionCallId,
                reason: "The function call must name the function in '@call'."
            )
        }
        return CallRendererFunctionMessage(
            functionCallId: functionCallId,
            callFunction: call,
            surfaceId: json[surfaceIdKey] as? String
        )
    }

    /// The serialized wire representation of the payload.
    func toJson() -> JsonMap {
        var json: JsonMap = ["functionCallId": functionCallId, "callFunction": callFunction.rawValue]
        if let surfaceId { json[surfaceIdKey] = surfaceId }
        return json
    }
}

/// The result of a function call, in either direction.
///
/// Exactly one of `value` and `error` is present.
@available(iOS 15.0, macOS 12.0, *)
struct FunctionResponse: Sendable {
    /// An error returned instead of a value.
    struct Failure: Equatable, Sendable {
        /// A machine-readable error code.
        let code: String

        /// A human-readable description of the failure.
        let message: String

        /// Creates a function failure.
        /// Use a stable code so agents can branch on it.
        init(code: String, message: String) {
            self.code = code
            self.message = message
        }

        /// The serialized wire representation of the failure.
        var rawValue: JsonMap {
            ["code": code, "message": message]
        }
    }

    /// The id of the call this response belongs to.
    let functionCallId: String

    /// The returned value, when the call succeeded.
    let value: (any Sendable)?

    /// The failure, when the call did not succeed.
    let error: Failure?

    /// Creates a successful response.
    /// Pass `NSNull()` for functions that return no value.
    init(functionCallId: String, value: (any Sendable)?) {
        self.functionCallId = functionCallId
        self.value = value
        self.error = nil
    }

    /// Creates a failed response.
    /// The call id must match the originating call.
    init(functionCallId: String, error: Failure) {
        self.functionCallId = functionCallId
        self.value = nil
        self.error = error
    }

    /// Parses a function response from a JSON object.
    /// Throws when the call id is missing.
    static func fromJson(_ json: JsonMap) throws -> FunctionResponse {
        guard let functionCallId = json["functionCallId"] as? String, !functionCallId.isEmpty else {
            throw A2UIDecodingError.missingField("functionCallId", in: "functionResponse")
        }
        let hasValue = json.keys.contains("value")
        let hasError = json.keys.contains("error")
        guard hasValue != hasError else {
            throw A2UIDecodingError.invalidField(
                "value",
                in: "functionResponse",
                reason: "Exactly one of 'value' and 'error' must be present."
            )
        }
        if hasError {
            guard let errorJson = Json.map(json["error"]),
                  let code = errorJson["code"] as? String,
                  let message = errorJson["message"] as? String else {
                throw A2UIDecodingError.invalidField(
                    "error",
                    in: "functionResponse",
                    reason: "The error must carry a 'code' and a 'message'."
                )
            }
            return FunctionResponse(functionCallId: functionCallId, error: Failure(code: code, message: message))
        }
        return FunctionResponse(functionCallId: functionCallId, value: json["value"])
    }

    /// The serialized wire representation of the response.
    func toJson() -> JsonMap {
        var json: JsonMap = ["functionCallId": functionCallId]
        if let error {
            json["error"] = error.rawValue
        } else {
            json["value"] = value ?? NSNull()
        }
        return json
    }
}

/// Errors raised while decoding A2UI payloads.
@available(iOS 15.0, macOS 12.0, *)
enum A2UIDecodingError: Error, Equatable, CustomStringConvertible, Sendable {
    /// The payload did not contain a known message key.
    case unknownMessageType([String])

    /// A required field was missing from a message payload.
    case missingField(String, in: String)

    /// The payload declared a protocol version this renderer does not support.
    case unsupportedVersion(String)

    /// The payload carried more than one message key.
    case multipleMessageTypes([String])

    /// A field had a value of the wrong shape.
    case invalidField(String, in: String, reason: String)

    /// A `callRendererFunction` message was malformed.
    ///
    /// The renderer answers it with an `INVALID_FUNCTION_CALL` error.
    case invalidFunctionCall(functionCallId: String, reason: String)

    /// A human-readable description of the failure.
    var description: String {
        switch self {
        case let .unknownMessageType(keys):
            return "Unknown A2UI message type. Keys: \(keys.sorted().joined(separator: ", "))"
        case let .missingField(field, message):
            return "Missing required field '\(field)' in '\(message)' message."
        case let .unsupportedVersion(version):
            return "Unsupported A2UI protocol version '\(version)'. Expected '\(A2UIProtocol.version)'."
        case let .multipleMessageTypes(keys):
            return "A message must carry exactly one message type, but it has: \(keys.sorted().joined(separator: ", "))."
        case let .invalidField(field, message, reason):
            return "Invalid field '\(field)' in '\(message)' message. \(reason)"
        case let .invalidFunctionCall(_, reason):
            return "Invalid function call. \(reason)"
        }
    }

    /// The error to report to the agent for this failure.
    ///
    /// - Parameter surfaceId: The surface the failing message targeted, when known.
    func rendererError(surfaceId: String?) -> RendererError {
        switch self {
        case let .invalidFunctionCall(functionCallId, _):
            return RendererError(
                code: RendererError.Code.invalidFunctionCall,
                message: description,
                functionCallId: functionCallId
            )
        case let .missingField(field, _), let .invalidField(field, _, _):
            return RendererError(
                code: RendererError.Code.validationFailed,
                message: description,
                surfaceId: surfaceId ?? "",
                path: "/\(field)"
            )
        case .unsupportedVersion:
            return RendererError(
                code: RendererError.Code.validationFailed,
                message: description,
                surfaceId: surfaceId ?? "",
                path: "/\(A2UIProtocol.versionKey)"
            )
        case .unknownMessageType, .multipleMessageTypes:
            return RendererError(
                code: RendererError.Code.validationFailed,
                message: description,
                surfaceId: surfaceId ?? "",
                path: ""
            )
        }
    }
}

/// A wire message that could not be decoded, with the payload it came from.
///
/// ``A2UIConversation`` reports these to the agent, so the agent can correct
/// the message.
@available(iOS 15.0, macOS 12.0, *)
struct A2UIDecodingFailure: Error, CustomStringConvertible {
    /// Why decoding failed.
    let error: Error

    /// The payload that failed to decode.
    let payload: JsonMap

    /// Creates a decoding failure.
    init(error: Error, payload: JsonMap) {
        self.error = error
        self.payload = payload
    }

    /// The error to report to the agent.
    var rendererError: RendererError {
        A2UIMessageDecoder.rendererError(for: error, in: payload)
    }

    /// A human-readable description of the failure.
    var description: String {
        A2UIErrorFormatter.describe(error)
    }
}

/// Decodes agent-to-renderer messages from wire payloads.
@available(iOS 15.0, macOS 12.0, *)
enum A2UIMessageDecoder {
    /// Decodes a single A2UI message envelope.
    ///
    /// The `version` field is validated when present so that a v0.9 agent
    /// talking to a v1.0 renderer fails loudly instead of rendering nothing.
    static func decode(_ json: JsonMap) throws -> A2UIMessage {
        guard let rawVersion = json[A2UIProtocol.versionKey] else {
            throw A2UIDecodingError.missingField(A2UIProtocol.versionKey, in: "envelope")
        }
        guard let version = rawVersion as? String, version == A2UIProtocol.version else {
            throw A2UIDecodingError.unsupportedVersion(Json.stringify(rawVersion))
        }
        let messageKeys = json.keys.filter { messageTypes.contains($0) }
        guard messageKeys.count <= 1 else {
            throw A2UIDecodingError.multipleMessageTypes(messageKeys)
        }
        if let key = messageKeys.first, Json.map(json[key]) == nil {
            throw A2UIDecodingError.invalidField(key, in: "envelope", reason: "The message payload must be an object.")
        }

        if let payload = Json.map(json["createSurface"]) {
            return .createSurface(try CreateSurfaceMessage.fromJson(payload))
        }
        if let payload = Json.map(json["updateComponents"]) {
            return .updateComponents(try UpdateComponentsMessage.fromJson(payload))
        }
        if let payload = Json.map(json["updateDataModel"]) {
            return .updateDataModel(try UpdateDataModelMessage.fromJson(payload))
        }
        if let payload = Json.map(json["deleteSurface"]) {
            return .deleteSurface(try DeleteSurfaceMessage.fromJson(payload))
        }
        if let payload = Json.map(json["callRendererFunction"]) {
            return .callRendererFunction(try CallRendererFunctionMessage.fromJson(payload))
        }
        if let payload = Json.map(json["agentFunctionResponse"]) {
            return .agentFunctionResponse(try FunctionResponse.fromJson(payload))
        }
        throw A2UIDecodingError.unknownMessageType(Array(json.keys))
    }

    /// Whether a JSON object looks like an A2UI agent-to-renderer message.
    /// Used to filter A2A data parts that carry other payloads.
    static func isMessage(_ json: JsonMap) -> Bool {
        !messageTypes.isDisjoint(with: json.keys)
    }

    /// The error to report to the agent when a payload fails to decode.
    ///
    /// The surface id is taken from the payload when it has one, so the agent
    /// can tell which surface the failing message targeted.
    static func rendererError(for error: Error, in json: JsonMap) -> RendererError {
        let surfaceId = messageTypes.lazy
            .compactMap { Json.map(json[$0])?[surfaceIdKey] as? String }
            .first
        if let error = error as? A2UIDecodingError {
            return error.rendererError(surfaceId: surfaceId)
        }
        return RendererError(
            code: RendererError.Code.validationFailed,
            message: A2UIErrorFormatter.describe(error),
            surfaceId: surfaceId ?? "",
            path: ""
        )
    }

    private static let messageTypes: Set<String> = [
        "createSurface", "updateComponents", "updateDataModel",
        "deleteSurface", "callRendererFunction", "agentFunctionResponse"
    ]

    /// Decodes a list of messages, reporting per-message failures.
    ///
    /// The A2A binding states that a message list is not a transactional unit:
    /// a failing message is reported and the remaining messages are still
    /// processed.
    static func decodeList(_ values: JsonArray) -> (messages: [A2UIMessage], errors: [Error]) {
        var messages: [A2UIMessage] = []
        var errors: [Error] = []
        for value in values {
            guard let json = Json.map(value) else {
                errors.append(A2UIDecodingError.unknownMessageType([]))
                continue
            }
            do {
                messages.append(try decode(json))
            } catch {
                errors.append(error)
            }
        }
        return (messages, errors)
    }

    /// Parses a `components` array, skipping malformed entries.
    static func components(from raw: (any Sendable)?) -> [Component] {
        (Json.array(raw) ?? []).compactMap { entry in
            guard let json = Json.map(entry) else { return nil }
            return Component.fromJson(json)
        }
    }
}
