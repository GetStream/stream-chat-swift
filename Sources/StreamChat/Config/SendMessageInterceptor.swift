//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

/// A struct that contains additional info when sending messages.
public struct SendMessageOptions {
    public let skipPush: Bool
    public let skipEnrichUrl: Bool
}

/// A struct that represents the response when sending a message.
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
public protocol SendMessageInterceptorFactory: Sendable {
    func makeSendMessageInterceptor(client: ChatClient) -> SendMessageInterceptor
}
