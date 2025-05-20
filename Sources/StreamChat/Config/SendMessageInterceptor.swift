//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

/// A struct that contains additional date when sending messages.
public struct SendMessageOptions {
    public let skipPush: Bool
    public let skipEnrichUrl: Bool
}

/// A struct that represents the response of sending a message.
public struct SendMessageResponse {
    public let message: ChatMessage

    public init(message: ChatMessage) {
        self.message = message
    }
}

/// A protocol that defines a way to intercept messages before sending them to the server.
public protocol SendMessageInterceptor {
    func sendMessage(
        _ message: ChatMessage,
        options: SendMessageOptions,
        completion: @escaping ((Result<SendMessageResponse, Error>) -> Void)
    )
}

/// A factory responsible for creating message interceptors.
public protocol SendMessageInterceptorFactory {
    func makeSendMessageInterceptor(client: ChatClient) -> SendMessageInterceptor
}

class CustomMessageInterceptor: SendMessageInterceptor {
    let defaultInterceptor: DefaultMessageInterceptor

    init(defaultInterceptor: DefaultMessageInterceptor) {
        self.defaultInterceptor = defaultInterceptor
    }

    func sendMessage(
        _ message: ChatMessage,
        options: SendMessageOptions,
        completion: @escaping ((Result<SendMessageResponse, any Error>) -> Void)
    ) {
        if message.type == .regular {
            defaultInterceptor.sendMessage(message, options: options, completion: completion)
            return
        }
        // Custom logic for other message types
        print(message)
        completion(.success(SendMessageResponse(message: message)))
    }
}
