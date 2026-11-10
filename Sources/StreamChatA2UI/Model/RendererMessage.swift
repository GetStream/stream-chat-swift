//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// A renderer-to-agent message, as defined by `renderer_to_agent.json`.
@available(iOS 15.0, macOS 12.0, *)
enum RendererMessage: Equatable {
    /// Reports a user interaction with a component.
    case action(RendererAction)

    /// Asks the agent to execute a function on the renderer's behalf.
    case callAgentFunction(CallAgentFunctionMessage)

    /// Returns the result of an agent-initiated renderer function call.
    case rendererFunctionResponse(FunctionResponse)

    /// Reports a renderer-side error.
    case error(RendererError)

    /// The serialized wire representation, including the protocol version.
    func toJson() -> JsonMap {
        var json: JsonMap = [A2UIProtocol.versionKey: A2UIProtocol.version]
        switch self {
        case let .action(action): json["action"] = action.toJson()
        case let .callAgentFunction(call): json["callAgentFunction"] = call.toJson()
        case let .rendererFunctionResponse(response): json["rendererFunctionResponse"] = response.toJson()
        case let .error(error): json["error"] = error.toJson()
        }
        return json
    }

    /// Decodes a renderer-to-agent message.
    /// Agents use this to interpret events coming back from a renderer.
    static func fromJson(_ json: JsonMap) throws -> RendererMessage {
        if let version = json[A2UIProtocol.versionKey] as? String, version != A2UIProtocol.version {
            throw A2UIDecodingError.unsupportedVersion(version)
        }
        if let payload = Json.map(json["action"]) {
            return .action(try RendererAction.fromJson(payload))
        }
        if let payload = Json.map(json["callAgentFunction"]) {
            return .callAgentFunction(try CallAgentFunctionMessage.fromJson(payload))
        }
        if let payload = Json.map(json["rendererFunctionResponse"]) {
            return .rendererFunctionResponse(try FunctionResponse.fromJson(payload))
        }
        if let payload = Json.map(json["error"]) {
            return .error(try RendererError.fromJson(payload))
        }
        throw A2UIDecodingError.unknownMessageType(Array(json.keys))
    }

    /// Whether a JSON object looks like an A2UI renderer-to-agent message.
    static func isMessage(_ json: JsonMap) -> Bool {
        let keys: Set<String> = ["action", "callAgentFunction", "rendererFunctionResponse", "error"]
        return !keys.isDisjoint(with: json.keys)
    }

    /// Compares two messages by their wire representation.
    static func == (lhs: RendererMessage, rhs: RendererMessage) -> Bool {
        Json.isEqual(lhs.toJson(), rhs.toJson())
    }
}

/// A user interaction reported to the agent.
@available(iOS 15.0, macOS 12.0, *)
struct RendererAction {
    /// The action name taken from the component's `action.event.name`.
    let name: String

    /// A human-readable description of what the user did.
    let userMessage: String?

    /// The surface the interaction happened on.
    let surfaceId: String

    /// The component that triggered the interaction.
    let sourceComponentId: String

    /// When the interaction happened.
    let timestamp: Date

    /// The resolved context values declared by the action.
    let context: JsonMap

    /// Client-side extension metadata sent with the action.
    let metadata: JsonMap?

    /// Creates a user action payload.
    /// Context values must already be resolved against the data model.
    init(
        name: String,
        userMessage: String? = nil,
        surfaceId: String,
        sourceComponentId: String,
        timestamp: Date = Date(),
        context: JsonMap = [:],
        metadata: JsonMap? = nil
    ) {
        self.name = name
        self.userMessage = userMessage
        self.surfaceId = surfaceId
        self.sourceComponentId = sourceComponentId
        self.timestamp = timestamp
        self.context = context
        self.metadata = metadata
    }

    /// Parses a user action payload.
    /// Throws when a required field is missing.
    static func fromJson(_ json: JsonMap) throws -> RendererAction {
        guard let name = json["name"] as? String else {
            throw A2UIDecodingError.missingField("name", in: "action")
        }
        guard let surfaceId = json[surfaceIdKey] as? String else {
            throw A2UIDecodingError.missingField(surfaceIdKey, in: "action")
        }
        guard let sourceComponentId = json["sourceComponentId"] as? String else {
            throw A2UIDecodingError.missingField("sourceComponentId", in: "action")
        }
        let timestamp = (json["timestamp"] as? String).flatMap(A2UITimestamp.date(from:)) ?? Date()
        return RendererAction(
            name: name,
            userMessage: json["userMessage"] as? String,
            surfaceId: surfaceId,
            sourceComponentId: sourceComponentId,
            timestamp: timestamp,
            context: Json.map(json["context"]) ?? [:],
            metadata: Json.map(json["metadata"])
        )
    }

    /// The serialized wire representation of the action.
    func toJson() -> JsonMap {
        var json: JsonMap = [
            "name": name,
            surfaceIdKey: surfaceId,
            "sourceComponentId": sourceComponentId,
            "timestamp": A2UITimestamp.string(from: timestamp),
            "context": context
        ]
        if let userMessage { json["userMessage"] = userMessage }
        if let metadata { json["metadata"] = metadata }
        return json
    }
}

/// A renderer-initiated agent function call.
@available(iOS 15.0, macOS 12.0, *)
struct CallAgentFunctionMessage {
    /// The surface the call originated from.
    let surfaceId: String

    /// The id correlating this call with its response.
    let functionCallId: String

    /// The function to execute on the agent.
    let callFunction: FunctionCall

    /// Whether a person's gesture started the call, such as a button's action, rather than the
    /// surface while it renders. It stays on this device.
    let userActivated: Bool

    /// Creates an agent function call.
    /// The agent must echo `functionCallId` in its response.
    init(surfaceId: String, functionCallId: String, callFunction: FunctionCall, userActivated: Bool = false) {
        self.surfaceId = surfaceId
        self.functionCallId = functionCallId
        self.callFunction = callFunction
        self.userActivated = userActivated
    }

    /// Parses an agent function call payload.
    /// Throws when a required field is missing.
    static func fromJson(_ json: JsonMap) throws -> CallAgentFunctionMessage {
        guard let surfaceId = json[surfaceIdKey] as? String else {
            throw A2UIDecodingError.missingField(surfaceIdKey, in: "callAgentFunction")
        }
        guard let functionCallId = json["functionCallId"] as? String else {
            throw A2UIDecodingError.missingField("functionCallId", in: "callAgentFunction")
        }
        guard let callJson = Json.map(json["callFunction"]), let call = FunctionCall(callJson) else {
            throw A2UIDecodingError.missingField("callFunction", in: "callAgentFunction")
        }
        return CallAgentFunctionMessage(surfaceId: surfaceId, functionCallId: functionCallId, callFunction: call)
    }

    /// The serialized wire representation of the call.
    func toJson() -> JsonMap {
        [
            surfaceIdKey: surfaceId,
            "functionCallId": functionCallId,
            "callFunction": callFunction.rawValue
        ]
    }
}

/// A renderer-side error reported to the agent.
@available(iOS 15.0, macOS 12.0, *)
struct RendererError {
    /// Well-known error codes defined by the specification.
    enum Code {
        /// A message failed schema validation.
        static let validationFailed = "VALIDATION_FAILED"

        /// A component was placed under a parent that does not allow it.
        static let unallowedParent = "UNALLOWED_PARENT"

        /// A container received a child type it does not allow.
        static let unallowedChild = "UNALLOWED_CHILD"

        /// A function call was rejected, for example because of its call boundary.
        static let invalidFunctionCall = "INVALID_FUNCTION_CALL"

        /// A function was not registered with the agent.
        static let unknownFunction = "UNKNOWN_FUNCTION"

        /// A function threw while executing.
        static let executionError = "EXECUTION_ERROR"

        /// A binding or check referenced a function it may not run, such as one
        /// that requires a user gesture.
        static let expressionError = "EXPRESSION_ERROR"

        /// A message referenced a catalog the renderer does not support.
        static let catalogNotFound = "CATALOG_NOT_FOUND"

        /// A message conflicts with the renderer's state, for example by
        /// targeting a surface that does not exist.
        static let integrityError = "INTEGRITY_ERROR"

        /// A data model write could not be applied.
        static let dataError = "DATA_ERROR"

        /// The component tree nests deeper than the renderer supports.
        static let recursionLimitExceeded = "RECURSION_LIMIT_EXCEEDED"

        /// A function call routed to the agent got no answer in time.
        static let timeout = "TIMEOUT"
    }

    /// The machine-readable error code.
    let code: String

    /// A short description of what went wrong.
    let message: String

    /// The surface the error occurred on, mutually exclusive with `functionCallId`.
    let surfaceId: String?

    /// The JSON pointer to the field that failed validation.
    let path: String?

    /// The function call that failed, mutually exclusive with `surfaceId`.
    let functionCallId: String?

    /// Creates a renderer error.
    /// Provide either a surface id or a function call id, not both.
    init(
        code: String,
        message: String,
        surfaceId: String? = nil,
        path: String? = nil,
        functionCallId: String? = nil
    ) {
        self.code = code
        self.message = message
        self.surfaceId = surfaceId
        self.path = path
        self.functionCallId = functionCallId
    }

    /// Parses a renderer error payload.
    /// Throws when a required field is missing.
    static func fromJson(_ json: JsonMap) throws -> RendererError {
        guard let code = json["code"] as? String else {
            throw A2UIDecodingError.missingField("code", in: "error")
        }
        guard let message = json["message"] as? String else {
            throw A2UIDecodingError.missingField("message", in: "error")
        }
        return RendererError(
            code: code,
            message: message,
            surfaceId: json[surfaceIdKey] as? String,
            path: json["path"] as? String,
            functionCallId: json["functionCallId"] as? String
        )
    }

    /// The serialized wire representation of the error.
    func toJson() -> JsonMap {
        var json: JsonMap = ["code": code, "message": message]
        if let surfaceId { json[surfaceIdKey] = surfaceId }
        if let path { json["path"] = path }
        if let functionCallId { json["functionCallId"] = functionCallId }
        return json
    }
}

/// ISO 8601 timestamp formatting shared by renderer-to-agent messages.
@available(iOS 15.0, macOS 12.0, *)
enum A2UITimestamp {
    /// Formats a date as an ISO 8601 string.
    /// Used for the `timestamp` field of action messages.
    static func string(from date: Date) -> String {
        formatter(fractionalSeconds: false).string(from: date)
    }

    /// Parses an ISO 8601 string, with and without fractional seconds.
    /// Returns `nil` when the string is not a valid timestamp.
    static func date(from string: String) -> Date? {
        formatter(fractionalSeconds: false).date(from: string)
            ?? formatter(fractionalSeconds: true).date(from: string)
    }

    private static func formatter(fractionalSeconds: Bool) -> ISO8601DateFormatter {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = fractionalSeconds ? [.withInternetDateTime, .withFractionalSeconds] : [.withInternetDateTime]
        return formatter
    }
}
