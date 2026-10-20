//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamCore
import SwiftUI
import UIKit

/// The buttons under a finished reply: copy and share, then regenerate and rate when the app
/// handles them.
public struct AIReplyActionsView: View {
    var text: String
    var actions: AIReplyActions

    @State private var isCopied = false

    @Injected(\.aiAppearance.colors) private var colors
    @Injected(\.aiAppearance.fonts) private var fonts
    @Injected(\.aiAppearance.images) private var images
    @Injected(\.aiAppearance.tokens.layout) private var layout

    /// - Parameters:
    ///   - text: The reply's text, which copying and sharing hand on.
    ///   - actions: What else the person can do with the reply.
    public init(text: String, actions: AIReplyActions) {
        self.text = text
        self.actions = actions
    }

    public var body: some View {
        HStack(spacing: layout.spacingXs) {
            button(isCopied ? images.messageCopied : images.messageCopy, isCopied ? L10n.MessageActions.copied : L10n.MessageActions.copy) {
                UIPasteboard.general.string = text
                isCopied = true
                Task {
                    try? await Task.sleep(nanoseconds: 1_500_000_000)
                    isCopied = false
                }
            }
            if #available(iOS 16.0, *) {
                ShareLink(item: text) {
                    icon(images.messageShare)
                }
                .accessibilityLabel(L10n.MessageActions.share)
            }
            if let onRegenerate = actions.onRegenerate {
                button(images.messageRegenerate, L10n.MessageActions.regenerate, action: onRegenerate)
            }
            if let onRate = actions.onRate {
                let positive = actions.rating == .positive
                let negative = actions.rating == .negative
                button(positive ? images.messageRatedPositive : images.messageRatePositive, L10n.MessageActions.ratePositive) {
                    onRate(positive ? nil : .positive)
                }
                .accessibilityAddTraits(positive ? .isSelected : [])
                button(negative ? images.messageRatedNegative : images.messageRateNegative, L10n.MessageActions.rateNegative) {
                    onRate(negative ? nil : .negative)
                }
                .accessibilityAddTraits(negative ? .isSelected : [])
            }
        }
        .buttonStyle(.plain)
    }

    private func button(_ image: Image, _ label: String, action: @escaping @MainActor () -> Void) -> some View {
        Button(action: action) {
            icon(image)
        }
        .accessibilityLabel(label)
    }

    private func icon(_ image: Image) -> some View {
        image
            .font(fonts.messageAction)
            .foregroundStyle(Color(colors.messageAction))
            .frame(width: layout.buttonVisualHeightMd, height: layout.buttonVisualHeightMd)
            .contentShape(Rectangle())
    }
}
