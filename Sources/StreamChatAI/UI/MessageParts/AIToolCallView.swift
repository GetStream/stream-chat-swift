//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamCore
import SwiftUI

/// One tool call: what it is doing, where it runs, and how it went.
public struct AIToolCallView: View {
    var part: AIToolCallPart
    var font: Font?

    @Injected(\.aiAppearance.colors) private var colors
    @Injected(\.aiAppearance.images) private var images
    @Injected(\.aiAppearance.fonts) private var fonts
    @Injected(\.aiAppearance.tokens.layout) private var layout

    /// - Parameter font: The font of the call, `AIAppearance.fonts.messagePart` by default.
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
                        .font(fonts.toolCallDetail)
                        .foregroundStyle(Color(colors.toolCallDetail))
                        .lineLimit(2)
                }
            }
            Spacer(minLength: layout.spacingXs)
            if let duration = part.duration, part.status.isFinished {
                Text(Self.format(duration))
                    .font(fonts.toolCallDetail.monospacedDigit())
                    .foregroundStyle(Color(colors.toolCallDetail))
            }
        }
        .font(font ?? fonts.messagePart)
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
            images.toolCallCompleted.font(fonts.toolCallDetail.weight(.bold)).foregroundStyle(Color(colors.toolCallSuccess))
        case .failed:
            images.toolCallFailed.font(fonts.toolCallDetail.weight(.bold)).foregroundStyle(Color(colors.toolCallFailure))
        case .cancelled:
            images.toolCallCancelled.font(fonts.toolCallDetail.weight(.bold)).foregroundStyle(Color(colors.toolCallDetail))
        default:
            ProgressView().controlSize(.mini).tint(Color(colors.toolCallAccent))
        }
    }

    static func format(_ duration: TimeInterval) -> String {
        duration < 1 ? String(format: "%.1fs", duration) : DurationFormatting.minutesAndSeconds(Int(duration.rounded()))
    }
}
