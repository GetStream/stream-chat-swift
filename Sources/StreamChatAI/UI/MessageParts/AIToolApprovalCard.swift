//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamCore
import SwiftUI

/// A tool call's question: what it asks, the agent's reason and what allowing it shares, and
/// buttons to allow or decline it.
public struct AIToolApprovalCard: View {
    var approval: AIToolApproval
    var state: AIToolApprovalState
    var font: Font?
    var decide: @MainActor @Sendable (Bool) -> Void

    @Injected(\.aiAppearance.colors) private var colors
    @Injected(\.aiAppearance.tokens.fonts) private var fonts
    @Injected(\.aiAppearance.tokens.layout) private var layout

    /// - Parameter font: The font of the question, the design tokens' `subheadline` by default.
    public init(
        approval: AIToolApproval,
        state: AIToolApprovalState = AIToolApprovalState(),
        font: Font? = nil,
        decide: @escaping @MainActor @Sendable (_ allowed: Bool) -> Void
    ) {
        self.approval = approval
        self.state = state
        self.font = font
        self.decide = decide
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: layout.spacingSm) {
            VStack(alignment: .leading, spacing: layout.spacingXxs) {
                Text(approval.title)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color(colors.toolApprovalTitle))
                ForEach(Self.lines(of: approval), id: \.self) { line in
                    Text(line)
                        .font(fonts.footnote)
                        .foregroundStyle(Color(colors.toolApprovalMessage))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            HStack(spacing: layout.spacingXs) {
                Button(approval.allowTitle) { decide(true) }
                    .buttonStyle(.borderedProminent)
                Button(approval.declineTitle) { decide(false) }
                    .buttonStyle(.bordered)
                if state.isSending {
                    ProgressView().controlSize(.small)
                }
            }
            .controlSize(.small)
            .tint(Color(colors.toolApprovalAccent))
            .disabled(state.isSending)
            if state.failed {
                Text(L10n.ToolApproval.notSent)
                    .font(fonts.caption1)
                    .foregroundStyle(Color(colors.toolApprovalFailure))
            }
        }
        .font(font ?? fonts.subheadline)
        .padding(layout.spacingSm)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(colors.toolApprovalBackground), in: RoundedRectangle(cornerRadius: layout.radiusLg, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: layout.radiusLg, style: .continuous).strokeBorder(Color(colors.toolApprovalBorder)))
        .accessibilityElement(children: .contain)
    }

    /// The agent's reason, as a sentence, then what allowing it shares.
    static func lines(of approval: AIToolApproval) -> [String] {
        var lines: [String] = []
        if let reason = approval.reason?.trimmingCharacters(in: .whitespacesAndNewlines), let first = reason.first {
            let sentence = first.uppercased() + reason.dropFirst()
            lines.append(sentence.last.map { ".!?…".contains($0) } == true ? sentence : sentence + ".")
        }
        if let message = approval.message {
            lines.append(message)
        }
        return lines
    }
}
