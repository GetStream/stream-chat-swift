//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChatAI
import SwiftUI

/// The A2UI replies of one conversation, each with a message processor of its own.
@available(iOS 15.0, macOS 12.0, *)
@MainActor
final class A2UIEngine: AIUIEngine {
    private weak var host: (any AIUIHosting)?
    private let renderer: A2UIRenderer
    private(set) var replies: [String: A2UIReply] = [:]

    init(renderer: A2UIRenderer, host: any AIUIHosting) {
        self.renderer = renderer
        self.host = host
    }

    func remove(messageID: String) {
        replies[messageID] = nil
    }

    func view(for document: AIUIDocument, messageID: String) -> A2UIReplyView? {
        guard let source = Self.source(of: document) else { return nil }
        let reply = replies[messageID] ?? makeReply(messageID: messageID, source: source, isStreaming: document.isStreaming)
        // A reply with no surfaces of its own has no view following it, so it is brought up to
        // date here, and shows its text until a surface arrives.
        if reply.surfaceIds.isEmpty {
            reply.update(source: source, isStreaming: document.isStreaming)
        }
        guard !reply.surfaceIds.isEmpty else { return nil }
        return A2UIReplyView(reply: reply, source: source, isStreaming: document.isStreaming, theme: renderer.theme)
    }

    // A reply's surfaces start with its messages so far, before any view follows them.
    private func makeReply(messageID: String, source: String, isStreaming: Bool) -> A2UIReply {
        let components = renderer.definitions(of: host?.components ?? []) { component in
            builder(of: component, messageID: messageID)
        }
        let services = RendererServices(openUrl: { [weak host] url in host?.open(url) }, mediaURL: renderer.mediaURL)
        let processor = A2UIMessageProcessor(
            catalogs: renderer.catalogs(adding: components, entrances: true),
            defaultCatalogId: renderer.catalogId,
            services: services
        )
        let reply = A2UIReply(processor: processor) { [weak self] message in
            self?.handle(message, messageID: messageID)
        }
        replies[messageID] = reply
        reply.update(source: source, isStreaming: isStreaming)
        return reply
    }

    // What shows one of the app's components. Catalog builders return `AnyView`, because a
    // catalog picks its components by name at runtime, so this is where the app's view loses its
    // type, as the catalog's own components do.
    private func builder(of component: some AIUIComponent, messageID: String) -> ComponentViewBuilder {
        { [weak self] context in
            AnyView(self?.view(of: component, in: context, messageID: messageID))
        }
    }

    private func view(
        of component: some AIUIComponent,
        in context: ComponentRenderContext,
        messageID: String
    ) -> (some View)? {
        self.context(of: component, messageID: messageID).flatMap { componentContext in
            var arguments: [String: RawJSON] = [:]
            for parameter in component.definition.parameters {
                if let value = context.value(parameter.name) {
                    arguments[parameter.name] = RawJSON(a2ui: value)
                }
            }
            return component.view(arguments: arguments, context: componentContext)
        }
    }

    // What one of the app's components gets besides its arguments, while the host is there.
    private func context(of component: some AIUIComponent, messageID: String) -> AIUIComponentContext? {
        guard let host else { return nil }
        let isStreaming = replies[messageID]?.isStreaming ?? false
        let name = component.name
        return AIUIComponentContext(messageID: messageID, isStreaming: isStreaming, host: host) { event, label, payload in
            var payload = payload
            payload["component"] = .string(name)
            host.send(AIUIAction(messageID: messageID, format: .a2ui, name: event, label: label, payload: payload))
        }
    }

    func handle(_ message: RendererMessage, messageID: String) {
        switch message {
        case let .action(action):
            let label = buttonText(of: action, messageID: messageID) ?? Self.words(of: action.name)
            host?.send(AIUIAction(
                messageID: messageID,
                format: .a2ui,
                name: action.name,
                label: label,
                payload: payload(of: action, messageID: messageID)
            ))
        case let .error(error):
            if let onError = renderer.onError {
                onError(A2UIError(error), messageID)
            } else {
                log.error("A reply's A2UI can't show: \(error.code) \(error.message)")
            }
        case let .callAgentFunction(call):
            run(call, messageID: messageID)
        case .rendererFunctionResponse:
            break
        }
    }

    // What an action tells the agent besides its name: its surface, its component, its resolved
    // context and the agent's own words for it, and the surface's data model when the agent
    // asked for it.
    private func payload(of action: RendererAction, messageID: String) -> [String: RawJSON] {
        var payload: [String: RawJSON] = [
            "surfaceId": .string(action.surfaceId),
            "sourceComponentId": .string(action.sourceComponentId),
            "context": .dictionary(action.context.mapValues { RawJSON(a2ui: $0) })
        ]
        if let userMessage = action.userMessage, !userMessage.isEmpty {
            payload["userMessage"] = .string(userMessage)
        }
        if let surface = replies[messageID]?.processor.existingSurfaceViewModel(action.surfaceId),
           surface.definition?.sendDataModel == true {
            payload["dataModel"] = RawJSON(a2ui: surface.dataModel.snapshot)
        }
        return payload
    }

    // A function the catalog doesn't define runs as one of the host's tools, on this device, as a
    // chat has no channel to ask the agent. While a surface renders only a read-only tool runs; any
    // other only from a person's gesture. Without that tool it fails at once.
    private func run(_ call: CallAgentFunctionMessage, messageID: String) {
        guard let host else { return }
        let callId = call.functionCallId
        let name = call.callFunction.name
        let userActivated = call.userActivated
        let arguments = call.callFunction.arguments.mapValues { RawJSON(a2ui: $0) }
        Task { [weak self] in
            let response: FunctionResponse
            do {
                let output = try await host.runTool(name, arguments: arguments, userInitiated: userActivated)
                response = FunctionResponse(functionCallId: callId, value: output.a2uiValue)
            } catch {
                response = FunctionResponse(
                    functionCallId: callId,
                    error: .init(code: RendererError.Code.executionError, message: error.localizedDescription)
                )
            }
            self?.replies[messageID]?.processor.handle(.agentFunctionResponse(response))
        }
    }

    // What the button the person tapped says, when its action has no words of its own.
    private func buttonText(of action: RendererAction, messageID: String) -> String? {
        guard let processor = replies[messageID]?.processor,
              let definition = processor.existingSurfaceViewModel(action.surfaceId)?.definition,
              let childId = definition.component(action.sourceComponentId)?.property("child") as? String,
              let text = definition.component(childId)?.property("text") as? String,
              !text.isEmpty
        else { return nil }
        return text
    }

    // An event name as words, such as "Submit form" for `submit_form` or `submitForm`, for a
    // button whose action has no words of its own.
    static func words(of name: String) -> String {
        var words: [String] = []
        var word = ""
        for character in name {
            let separates = character == "_" || character == "-" || character == " "
            let startsWord = character.isUppercase && word.last?.isLowercase == true
            if separates || startsWord {
                if !word.isEmpty { words.append(word) }
                word = separates ? "" : String(character)
            } else {
                word.append(character)
            }
        }
        if !word.isEmpty { words.append(word) }
        let sentence = words.joined(separator: " ").lowercased()
        return sentence.prefix(1).uppercased() + sentence.dropFirst()
    }

    // The messages of a document as text: as the agent wrote them, or written out when a backend
    // sent them as JSON.
    static func source(of document: AIUIDocument) -> String? {
        if let text = document.text {
            return text
        }
        switch document.content {
        case .array, .dictionary:
            guard let data = try? JSONEncoder().encode(document.content) else { return nil }
            return String(decoding: data, as: UTF8.self)
        default:
            return nil
        }
    }
}
