//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import SwiftUI

/// The steps an AI agent took while replying, in order. Show it before the reply's text.
///
/// ```swift
/// AIMessagePartsView(parts: parts, approver: approver)
/// ```
///
/// Each step shows through `AIMessagePartView`: reasoning, tool calls, and a neutral
/// placeholder for kinds this SDK doesn't know. With an `AIToolApprover`, a call waiting
/// for this person's approval shows its question under it. To show some steps your own way, such as
/// reasoning you stream separately or a kind of your own, render each part yourself and
/// fall back to `AIMessagePartView` for the rest:
///
/// ```swift
/// AIMessagePartsView(parts: parts) { part in
///     if let reasoning = part.reasoning {
///         StreamingReasoningView(part: reasoning, text: liveText[reasoning.id])
///     } else if part.kind == "ai_citation" {
///         CitationView(part: part)
///     } else {
///         AIMessagePartView(part: part)
///     }
/// }
/// ```
public struct AIMessagePartsView<Content: View>: View {
    var parts: [AIMessagePart]
    var content: (AIMessagePart) -> Content

    public init(parts: [AIMessagePart], @ViewBuilder content: @escaping (AIMessagePart) -> Content) {
        self.parts = parts
        self.content = content
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(parts) { part in
                content(part)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

public extension AIMessagePartsView where Content == AIMessagePartView {
    /// Shows every step with `AIMessagePartView`.
    /// - Parameter approver: Who answers calls' questions on this device, to ask them.
    init(parts: [AIMessagePart], approver: AIToolApprover? = nil, font: Font? = nil) {
        self.init(parts: parts) { part in
            AIMessagePartView(part: part, approver: approver, font: font)
        }
    }
}
