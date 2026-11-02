//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation

/// A ``ContentGenerator`` backed by an A2UI agent reached over A2A.
///
/// The generator owns an ``A2UIAgentConnector`` and republishes its streams on
/// the main queue, so surface state is always mutated where SwiftUI reads it.
@MainActor
public final class A2UIContentGenerator: ContentGenerator {
    /// The connector used for transport.
    public let connector: A2UIAgentConnector

    private let processingNotifier = ValueNotifier(false)
    private let errorSubject = PassthroughSubject<ContentGeneratorError, Never>()
    private var cancellables: Set<AnyCancellable> = []

    /// Creates a generator for an agent URL.
    /// Inject a connector to test without a network connection.
    public init(serverUrl: URL, connector: A2UIAgentConnector? = nil) {
        self.connector = connector ?? A2UIAgentConnector(url: serverUrl)
        self.connector.errors
            .sink { [weak self] error in
                self?.errorSubject.send(ContentGeneratorError(error, context: "A2UI agent"))
            }
            .store(in: &cancellables)
    }

    /// A2UI messages streamed by the agent, delivered on the main queue.
    public var messages: AnyPublisher<A2UIMessage, Never> {
        connector.messages.receive(on: DispatchQueue.main).eraseToAnyPublisher()
    }

    /// Text responses streamed by the agent, delivered on the main queue.
    public var textResponses: AnyPublisher<String, Never> {
        connector.textResponses.receive(on: DispatchQueue.main).eraseToAnyPublisher()
    }

    /// Failures encountered while talking to the agent.
    public var errors: AnyPublisher<ContentGeneratorError, Never> {
        errorSubject.receive(on: DispatchQueue.main).eraseToAnyPublisher()
    }

    /// Whether a request is currently in flight.
    public var isProcessing: ValueNotifier<Bool> {
        processingNotifier
    }

    /// Sends a request to the agent and waits for the stream to finish.
    /// Skips empty requests so no-op events do not wake the agent.
    public func send(_ request: GenerationRequest) async {
        guard !request.isEmpty else { return }

        await MainActor.run { processingNotifier.value = true }
        await connector.send(request)
        await MainActor.run { processingNotifier.value = false }
    }

    /// Releases the generator's resources.
    public func dispose() {
        cancellables.removeAll()
        connector.dispose()
    }
}
