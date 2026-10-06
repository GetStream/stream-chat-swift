//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamCore
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

public extension StreamingReasoningView {
    /// Shows a reasoning step: its live `text` when the app has it, otherwise the step's
    /// preview, with its summary beside "Thought for 12s" once it is done.
    init(
        part: AIReasoningPart,
        text: String? = nil,
        footnote: String? = nil,
        font: Font? = nil
    ) {
        self.init(
            text: text ?? part.preview ?? part.summary ?? "",
            isThinking: part.isStreaming,
            duration: part.duration,
            summary: part.summary,
            footnote: footnote,
            font: font
        )
    }
}

/// One tool call: what it is doing, where it runs, and how it went.
public struct AIToolCallView: View {
    var part: AIToolCallPart
    var font: Font?

    @Injected(\.aiAppearance.colors) private var colors
    @Injected(\.aiAppearance.images) private var images
    @Injected(\.aiAppearance.tokens.fonts) private var fonts
    @Injected(\.aiAppearance.tokens.layout) private var layout

    /// - Parameter font: The font of the call, the design tokens' `subheadline` by default.
    public init(part: AIToolCallPart, font: Font? = nil) {
        self.part = part
        self.font = font
    }

    public var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: layout.spacingXs) {
            icon
                .frame(width: 16)
            VStack(alignment: .leading, spacing: layout.spacingXxxs) {
                Text(title)
                    .foregroundStyle(Color(colors.toolCallTitle))
                if let detail {
                    Text(detail)
                        .font(fonts.caption1)
                        .foregroundStyle(Color(colors.toolCallDetail))
                        .lineLimit(2)
                }
            }
            Spacer(minLength: layout.spacingXs)
            if let duration = part.duration, part.status.isFinished {
                Text(Self.format(duration))
                    .font(fonts.caption1.monospacedDigit())
                    .foregroundStyle(Color(colors.toolCallDetail))
            }
        }
        .font(font ?? fonts.subheadline)
        .accessibilityElement(children: .combine)
    }

    private var title: String {
        part.displayTitle ?? part.name.replacingOccurrences(of: "_", with: " ")
    }

    private var detail: String? {
        if part.isDeclined {
            return part.summary ?? L10n.ToolCall.declined
        }
        return switch part.status {
        case .awaitingApproval: part.summary ?? L10n.ToolCall.awaitingApproval
        case .awaitingClient: part.summary ?? L10n.ToolCall.awaitingClient
        case .failed: part.summary ?? L10n.ToolCall.failed
        case .cancelled: part.summary ?? L10n.ToolCall.cancelled
        default: part.summary
        }
    }

    /// A status this SDK doesn't know reads as still in progress.
    @ViewBuilder private var icon: some View {
        switch part.status {
        case .awaitingApproval:
            images.toolCallAwaitingApproval
                .foregroundStyle(Color(colors.toolCallAccent))
                .modifier(Shimmer(isActive: true, highlight: Color(colors.toolCallTitle)))
        case .awaitingClient:
            images.toolCallAwaitingDevice
                .foregroundStyle(Color(colors.toolCallAccent))
                .modifier(Shimmer(isActive: true, highlight: Color(colors.toolCallTitle)))
        case .completed:
            images.toolCallCompleted.font(fonts.caption1.weight(.bold)).foregroundStyle(Color(colors.toolCallSuccess))
        case .failed:
            images.toolCallFailed.font(fonts.caption1.weight(.bold)).foregroundStyle(Color(colors.toolCallFailure))
        case .cancelled:
            images.toolCallCancelled.font(fonts.caption1.weight(.bold)).foregroundStyle(Color(colors.toolCallDetail))
        default:
            ProgressView().controlSize(.mini).tint(Color(colors.toolCallAccent))
        }
    }

    static func format(_ duration: TimeInterval) -> String {
        duration < 1 ? String(format: "%.1fs", duration) : DurationFormatting.minutesAndSeconds(Int(duration.rounded()))
    }
}

/// A step from a newer SDK: say that something happened without guessing what.
struct UnsupportedPartView: View {
    var font: Font

    @Injected(\.aiAppearance.colors) private var colors
    @Injected(\.aiAppearance.images) private var images

    var body: some View {
        Label {
            Text(L10n.ToolCall.unsupported)
        } icon: {
            images.unsupportedPart
        }
        .font(font)
        .foregroundStyle(Color(colors.toolCallDetail))
    }
}
