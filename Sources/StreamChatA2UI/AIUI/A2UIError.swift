//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// A problem with a reply's A2UI, as A2UI reports it to the agent: a message that doesn't read, a
/// component or function its catalog doesn't have, or a value its data model can't take.
@available(iOS 15.0, macOS 12.0, *)
public struct A2UIError: Error, Equatable, Sendable {
    /// The error's code in A2UI 1.0, such as `VALIDATION_FAILED`.
    public let code: String
    /// What went wrong, written for the agent.
    public let message: String
    /// The surface it happened on, when it belongs to one.
    public let surfaceId: String?
    /// A JSON pointer to the part of the agent's message at fault, when there is one.
    public let path: String?

    init(_ error: RendererError) {
        code = error.code
        message = error.message
        surfaceId = error.surfaceId
        path = error.path
    }
}
