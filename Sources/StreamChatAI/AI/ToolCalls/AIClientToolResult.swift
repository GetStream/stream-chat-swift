//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// What a device reports for a call.
public struct AIClientToolResult: Equatable, Sendable {
    /// The result for the model, as a JSON object.
    public var output: Data?
    /// A short outcome every channel member sees on the step, such as "Shared approximate
    /// location". Keep the data itself out of it.
    public var summary: String?
    /// Why the device could not run the call, such as "Location not shared". Shown on the
    /// step and told to the model.
    public var failure: String?

    public init(output: Data? = nil, summary: String? = nil, failure: String? = nil) {
        self.output = output
        self.summary = summary
        self.failure = failure
    }

    /// A completed call, with its result for the model.
    public static func completed(_ output: some Encodable, summary: String? = nil) -> AIClientToolResult {
        guard let data = try? JSONEncoder().encode(output) else {
            return .failed("The result couldn't be read")
        }
        return AIClientToolResult(output: data, summary: summary)
    }

    /// A call the device could not run.
    public static func failed(_ reason: String) -> AIClientToolResult {
        AIClientToolResult(failure: reason)
    }
}
