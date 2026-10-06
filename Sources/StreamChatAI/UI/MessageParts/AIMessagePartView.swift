//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamCore
import SwiftUI

/// One step of a reply: a round of reasoning with its preview, a tool call (with its
/// question, when it waits for the approver), or a neutral placeholder for a step this SDK
/// doesn't know.
public struct AIMessagePartView: View {
    var part: AIMessagePart
    var approver: AIToolApprover?
    var font: Font?

    @Injected(\.aiAppearance.tokens.fonts) private var fonts
    @Injected(\.aiAppearance.tokens.layout) private var layout

    /// - Parameter font: The font of the step, the design tokens' `subheadline` by default.
    public init(part: AIMessagePart, approver: AIToolApprover? = nil, font: Font? = nil) {
        self.part = part
        self.approver = approver
        self.font = font
    }

    public var body: some View {
        if let reasoning = part.reasoning {
            StreamingReasoningView(part: reasoning, font: font)
        } else if let call = part.toolCall {
            VStack(alignment: .leading, spacing: layout.spacingXs) {
                AIToolCallView(part: call, font: font)
                if let approver {
                    AIToolApprovalView(call: call, approver: approver, font: font)
                }
            }
        } else {
            UnsupportedPartView(font: font ?? fonts.subheadline)
        }
    }
}
