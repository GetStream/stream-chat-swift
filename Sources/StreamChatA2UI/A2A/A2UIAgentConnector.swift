//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation

/// Connects a renderer to an A2UI agent over the A2A protocol.
///
/// The connector implements the A2UI A2A extension v1.0:
///
/// * the extension URI `https://a2ui.org/a2a-extension/a2ui/v1.0` is activated
///   through the `X-A2A-Extensions` header,
/// * renderer capabilities and synchronized data models travel in message
///   metadata,
/// * A2UI messages travel in data parts whose MIME type is
///   `application/a2ui+json` and whose payload is an array of messages.
@MainActor
public final class A2UIAgentConnector {
    /// The base URL of the agent.
    public let url: URL

    /// The A2A client used for transport.
    public let client: A2AClientProtocol

    /// The task the agent created for this conversation, if any.
    public private(set) var taskId: String?

    /// The context id shared by every message of this conversation.
    public private(set) var contextId: String?

    private let messagesSubject = PassthroughSubject<A2UIMessage, Never>()
    private let textSubject = PassthroughSubject<String, Never>()
    private let errorSubject = PassthroughSubject<Error, Never>()
    private var receivedArtifactIds: Set<String> = []

    /// Creates a connector for an agent URL.
    /// Inject a client to test without a network connection.
    public init(url: URL, client: A2AClientProtocol? = nil, contextId: String? = nil) {
        self.url = url
        self.client = client ?? A2AClient(baseUrl: url.absoluteString)
        self.contextId = contextId
    }

    /// A2UI messages streamed by the agent.
    public var messages: AnyPublisher<A2UIMessage, Never> {
        messagesSubject.eraseToAnyPublisher()
    }

    /// Plain text responses streamed by the agent.
    public var textResponses: AnyPublisher<String, Never> {
        textSubject.eraseToAnyPublisher()
    }

    /// Transport and decoding failures.
    public var errors: AnyPublisher<Error, Never> {
        errorSubject.eraseToAnyPublisher()
    }

    /// Fetches the agent card, including its A2UI capabilities.
    /// Use it to check which catalogs the agent can generate.
    public func agentCard() async throws -> A2AAgentCard {
        try await client.getAgentCard()
    }

    /// Sends a request and streams the agent's response.
    ///
    /// A2UI messages are published on ``messages`` as they arrive so the UI can
    /// render progressively. The final text response, if any, is returned and
    /// also published on ``textResponses``.
    @discardableResult
    public func send(_ request: GenerationRequest) async -> String? {
        let payload = A2AMessageSendParams(
            message: makeMessage(for: request),
            extensions: [A2UIProtocol.a2aExtensionUri]
        )

        a2uiLogger.info("Sending message/stream to \(url.absoluteString)")
        a2uiLogger.finer("Payload: \(Json.encodeToString(payload.toJson(), pretty: true) ?? "<unencodable>")")

        var responseText: String?
        do {
            for try await event in client.sendMessageStream(payload) {
                if let text = handle(event: event) {
                    responseText = text
                }
            }
        } catch {
            a2uiLogger.severe("A2A stream failed: \(error)")
            errorSubject.send(error)
        }

        if let responseText, !responseText.isEmpty {
            textSubject.send(responseText)
        }
        return responseText
    }

    /// Closes the connector's streams.
    /// Call when the conversation ends.
    public func dispose() {
        messagesSubject.send(completion: .finished)
        textSubject.send(completion: .finished)
        errorSubject.send(completion: .finished)
    }

    // MARK: - Outgoing messages

    private func makeMessage(for request: GenerationRequest) -> A2AMessage {
        var message = A2AMessage()
        message.role = "user"
        message.parts = parts(for: request)

        var metadata: JsonMap = [:]
        if let capabilities = request.capabilities {
            metadata[A2UIProtocol.rendererCapabilitiesKey] = capabilities.toJson()
        }
        if let dataModel = request.dataModel, !dataModel.isEmpty {
            metadata[A2UIProtocol.rendererDataModelKey] = dataModel.toJson()
        }
        if !metadata.isEmpty {
            message.metadata = metadata
        }

        if let taskId {
            message.referenceTaskIds = [taskId]
        }
        message.contextId = contextId
        return message
    }

    private func parts(for request: GenerationRequest) -> [A2APart] {
        var parts: [A2APart] = []

        if !request.rendererMessages.isEmpty {
            parts.append(
                A2ADataPart(
                    data: request.rendererMessages.map { $0.toJson() },
                    metadata: ["mimeType": A2UIProtocol.mimeType]
                )
            )
        }

        for part in request.userMessage?.parts ?? [] {
            switch part {
            case let text as TextPart:
                parts.append(A2ATextPart(text: text.text))
            case let data as DataPart:
                parts.append(A2ADataPart(data: data.data ?? JsonMap()))
            case let image as ImagePart:
                if let url = image.url {
                    parts.append(A2AFilePart(file: A2AFileWithUri(uri: url.absoluteString, mimeType: image.mimeType)))
                } else if let bytes = image.bytes {
                    parts.append(
                        A2AFilePart(
                            file: A2AFileWithBytes(bytes: bytes.base64EncodedString(), mimeType: image.mimeType)
                        )
                    )
                } else if let base64 = image.base64 {
                    parts.append(A2AFilePart(file: A2AFileWithBytes(bytes: base64, mimeType: image.mimeType)))
                } else {
                    a2uiLogger.warning("Skipping an image part without data.")
                }
            default:
                a2uiLogger.warning("Skipping unsupported message part \(type(of: part)).")
            }
        }
        return parts
    }

    // MARK: - Incoming messages

    private func handle(event: A2ASendStreamMessageResponse) -> String? {
        a2uiLogger.finest("Received A2A event: \(Json.encodeToString(event.toJson(), pretty: true) ?? "")")

        if let errorResponse = event as? A2AJSONRPCErrorResponseSSM {
            let message = errorResponse.error?.message ?? "unknown error"
            let code = errorResponse.error?.rpcErrorCode ?? 0
            a2uiLogger.severe("A2A error \(code): \(message)")
            errorSubject.send(A2AClientError.serverError(code: code, message: message))
            return nil
        }

        guard let response = event as? A2ASendStreamMessageSuccessResponse else { return nil }

        if let task = response.result as? A2ATask {
            taskId = task.id
            contextId = task.contextId ?? contextId
        }
        if let update = response.result as? A2ATaskStatusUpdateEvent {
            taskId = update.taskId ?? taskId
            contextId = update.contextId ?? contextId
        }

        var parts: [A2APart] = []
        switch response.result {
        case let task as A2ATask:
            parts = task.status?.message?.parts ?? []
            // A task's artifacts repeat the ones streamed before it.
            for artifact in task.artifacts where receivedArtifactIds.insert(artifact.artifactId).inserted {
                parts += artifact.parts
            }
        case let direct as A2AMessage:
            parts = direct.parts
            contextId = direct.contextId ?? contextId
        case let update as A2ATaskStatusUpdateEvent:
            parts = update.status?.message?.parts ?? []
            contextId = update.status?.message?.contextId ?? contextId
        case let update as A2ATaskArtifactUpdateEvent:
            taskId = update.taskId ?? taskId
            contextId = update.contextId ?? contextId
            receivedArtifactIds.insert(update.artifact.artifactId)
            parts = update.artifact.parts
        default:
            break
        }
        guard !parts.isEmpty else { return nil }

        var text: String?
        for part in parts {
            switch part {
            case let dataPart as A2ADataPart where isA2UIPart(dataPart):
                process(dataPart)
            case let textPart as A2ATextPart:
                text = [text, textPart.text].compactMap { $0 }.joined(separator: "\n")
            default:
                break
            }
        }
        return text
    }

    private func isA2UIPart(_ part: A2ADataPart) -> Bool {
        if let mimeType = part.metadata?["mimeType"] as? String {
            return mimeType == A2UIProtocol.mimeType || Self.legacyMimeTypes.contains(mimeType)
        }
        // Older agents omit the MIME type; fall back to payload inspection.
        if let array = part.dataArray {
            return array.contains { Json.map($0).map(A2UIMessageDecoder.isMessage) ?? false }
        }
        if let map = part.dataMap {
            return A2UIMessageDecoder.isMessage(map) || map["messages"] != nil
        }
        return false
    }

    private func process(_ part: A2ADataPart) {
        if let array = part.dataArray {
            emit(array)
            return
        }
        guard let map = part.dataMap else { return }
        if let wrapped = Json.array(map["messages"]) {
            emit(wrapped)
            return
        }
        emit([map])
    }

    private func emit(_ values: JsonArray) {
        for value in values {
            let json = Json.map(value) ?? [:]
            do {
                messagesSubject.send(try A2UIMessageDecoder.decode(json))
            } catch {
                a2uiLogger.severe("Could not decode an A2UI message: \(error)")
                errorSubject.send(A2UIDecodingFailure(error: error, payload: json))
            }
        }
    }

    private static let legacyMimeTypes: Set<String> = [
        "application/json+a2ui",
        "application/json+a2aui"
    ]
}
