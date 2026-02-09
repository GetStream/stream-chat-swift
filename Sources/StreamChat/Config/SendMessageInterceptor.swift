//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// Contains additional info when sending messages.
public final class SendMessageOptions {
    public let skipPush: Bool
    public let skipEnrichUrl: Bool
    
    public init(skipPush: Bool = false, skipEnrichUrl: Bool = false) {
        self.skipPush = skipPush
        self.skipEnrichUrl = skipEnrichUrl
    }
}

/// Represents the response when sending a message.
public final class SendMessageResponse {
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
