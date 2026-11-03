//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamCore
import SwiftUI

/// What a component gets besides its arguments: which reply it is in, and how it tells the
/// agent what the person did.
@MainActor
public struct AIUIComponentContext {
    /// The reply the component is in.
    public let messageID: String
    /// Whether the agent is still writing the reply's UI, so the arguments may still change.
    public let isStreaming: Bool
    /// The conversation's host, for running the app's tools and opening links.
    public let host: any AIUIHosting
    private let emitEvent: @MainActor (_ event: String, _ label: String, _ payload: [String: RawJSON]) -> Void

    /// - Parameter emit: Sends an event to the agent the way the renderer's format does.
    public init(
        messageID: String,
        isStreaming: Bool,
        host: any AIUIHosting,
        emit: @escaping @MainActor (_ event: String, _ label: String, _ payload: [String: RawJSON]) -> Void
    ) {
        self.messageID = messageID
        self.isStreaming = isStreaming
        self.host = host
        emitEvent = emit
    }

    /// Tells the agent about one of the component's events, as the person's next message.
    /// - Parameters:
    ///   - event: The event's name in the component's definition.
    ///   - label: What the person did, in their words, such as "Tell me more about St. Naum".
    ///   - payload: What the event carries.
    public func emit(_ event: String, label: String, payload: [String: RawJSON] = [:]) {
        emitEvent(event, label, payload)
    }
}
