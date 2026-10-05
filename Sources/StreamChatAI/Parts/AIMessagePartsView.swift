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
    init(parts: [AIMessagePart], approver: AIToolApprover? = nil, font: Font = .subheadline, colors: Colors = Colors()) {
        self.init(parts: parts) { part in
            AIMessagePartView(part: part, approver: approver, font: font, colors: colors)
        }
    }
}

/// One step of a reply: a round of reasoning with its preview, a tool call (with its
/// question, when it waits for the approver), or a neutral placeholder for a step this SDK
/// doesn't know.
public struct AIMessagePartView: View {
    var part: AIMessagePart
    var approver: AIToolApprover?
    var font: Font
    var colors: Colors

    public init(part: AIMessagePart, approver: AIToolApprover? = nil, font: Font = .subheadline, colors: Colors = Colors()) {
        self.part = part
        self.approver = approver
        self.font = font
        self.colors = colors
    }

    public var body: some View {
        if let reasoning = part.reasoning {
            StreamingReasoningView(part: reasoning, font: font, colors: colors)
        } else if let call = part.toolCall {
            VStack(alignment: .leading, spacing: 8) {
                AIToolCallView(part: call, font: font, colors: colors)
                if let approver {
                    AIToolApprovalView(call: call, approver: approver, font: font, colors: colors)
                }
            }
        } else {
            UnsupportedPartView(font: font, colors: colors.toolCalls)
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
        font: Font = .subheadline,
        colors: Colors = Colors()
    ) {
        self.init(
            text: text ?? part.preview ?? part.summary ?? "",
            isThinking: part.isStreaming,
            duration: part.duration,
            summary: part.summary,
            footnote: footnote,
            font: font,
            colors: colors
        )
    }
}

/// One tool call: what it is doing, where it runs, and how it went.
public struct AIToolCallView: View {
    var part: AIToolCallPart
    var font: Font
    var colors: Colors.ToolCalls

    public init(part: AIToolCallPart, font: Font = .subheadline, colors: Colors = Colors()) {
        self.part = part
        self.font = font
        self.colors = colors.toolCalls
    }

    public var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            icon
                .frame(width: 16)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .foregroundStyle(colors.title)
                if let detail {
                    Text(detail)
                        .font(.caption)
                        .foregroundStyle(colors.detail)
                        .lineLimit(2)
                }
            }
            Spacer(minLength: 8)
            if let duration = part.duration, part.status.isFinished {
                Text(Self.format(duration))
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(colors.detail)
            }
        }
        .font(font)
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
            Image(systemName: "hand.raised")
                .foregroundStyle(colors.accent)
                .modifier(Shimmer(isActive: true, highlight: colors.title))
        case .awaitingClient:
            Image(systemName: "iphone")
                .foregroundStyle(colors.accent)
                .modifier(Shimmer(isActive: true, highlight: colors.title))
        case .completed:
            Image(systemName: "checkmark").font(.caption.weight(.bold)).foregroundStyle(colors.success)
        case .failed:
            Image(systemName: "exclamationmark").font(.caption.weight(.bold)).foregroundStyle(colors.failure)
        case .cancelled:
            Image(systemName: "xmark").font(.caption.weight(.bold)).foregroundStyle(colors.detail)
        default:
            ProgressView().controlSize(.mini).tint(colors.accent)
        }
    }

    static func format(_ duration: TimeInterval) -> String {
        duration < 1 ? String(format: "%.1fs", duration) : DurationFormatting.minutesAndSeconds(Int(duration.rounded()))
    }
}

/// A step from a newer SDK: say that something happened without guessing what.
struct UnsupportedPartView: View {
    var font: Font
    var colors: Colors.ToolCalls

    var body: some View {
        Label(L10n.ToolCall.unsupported, systemImage: "sparkles")
            .font(font)
            .foregroundStyle(colors.detail)
    }
}
