//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import SwiftUI
import UIKit

/// Defines the palette that StreamChatAI views rely on.
public class Colors {
    /// Appearance configuration for `ComposerView`.
    public var composer: Composer
    /// Appearance configuration for `SuggestionsView`.
    public var suggestions: Suggestions
    /// Appearance configuration for `TranscribeSpeechButton`.
    public var transcription: Transcription
    /// Appearance configuration for `StreamingReasoningView`.
    public var reasoning: Reasoning
    /// Appearance configuration for `AIToolCallView` and the other steps of `AIMessagePartsView`.
    public var toolCalls: ToolCalls
    /// Appearance configuration for `AIToolApprovalView`, the question a client tool asks before it runs.
    public var toolApprovals: ToolApprovals
    
    /// Creates a new palette with optional overrides for each supported view.
    public init(
        composer: Composer = .init(),
        suggestions: Suggestions = .init(),
        transcription: Transcription = .init(),
        reasoning: Reasoning = .init(),
        toolCalls: ToolCalls = .init(),
        toolApprovals: ToolApprovals = .init()
    ) {
        self.composer = composer
        self.suggestions = suggestions
        self.transcription = transcription
        self.reasoning = reasoning
        self.toolCalls = toolCalls
        self.toolApprovals = toolApprovals
    }
}

public extension Colors {
    /// Palette for all composer-specific elements.
    struct Composer {
        /// Background color of the plus button.
        public var attachmentButtonBackground: Color
        /// Color of the plus icon.
        public var attachmentButtonIcon: Color
        /// Background color of the main composer container.
        public var containerBackground: Color
        /// Foreground color used for text/icons inside the composer.
        public var containerForeground: Color
        /// Background of the selected chat option chip.
        public var selectedOptionBackground: Color
        /// Foreground of the selected chat option chip.
        public var selectedOptionForeground: Color
        
        /// Creates the composer palette with optional overrides.
        public init(
            attachmentButtonBackground: Color = Color(UIColor.secondarySystemBackground),
            attachmentButtonIcon: Color = .gray,
            containerBackground: Color = Color(UIColor.secondarySystemBackground),
            containerForeground: Color = .primary,
            selectedOptionBackground: Color = Color(UIColor.systemBackground),
            selectedOptionForeground: Color = .blue
        ) {
            self.attachmentButtonBackground = attachmentButtonBackground
            self.attachmentButtonIcon = attachmentButtonIcon
            self.containerBackground = containerBackground
            self.containerForeground = containerForeground
            self.selectedOptionBackground = selectedOptionBackground
            self.selectedOptionForeground = selectedOptionForeground
        }
    }
    
    /// Palette for suggestion chips.
    struct Suggestions {
        /// Text color of the suggestion.
        public var text: Color
        /// Background color for each suggestion card.
        public var background: Color
        
        /// Creates the suggestions palette with optional overrides.
        public init(
            text: Color = .primary,
            background: Color = Color(UIColor.secondarySystemBackground)
        ) {
            self.text = text
            self.background = background
        }
    }
    
    /// Palette for the transcription button state.
    struct Transcription {
        /// Color of the microphone / stop icon.
        public var icon: Color
        
        /// Creates the transcription palette with optional overrides.
        public init(icon: Color = .gray) {
            self.icon = icon
        }
    }
    
    /// Palette for a model's reasoning.
    struct Reasoning {
        /// Color of the header ("Thinking…", "Thought for 12s") and its icons.
        public var title: Color
        /// Color of the reasoning itself.
        public var text: Color
        /// Color of the note under the open reasoning.
        public var footnote: Color
        /// Color of the highlight that sweeps across the header while the model thinks.
        public var shimmer: Color
        /// Color of the rule along the reasoning's leading edge.
        public var rule: Color
        
        /// Creates the reasoning palette with optional overrides.
        public init(
            title: Color = .secondary,
            text: Color = .secondary,
            footnote: Color = Color(UIColor.tertiaryLabel),
            shimmer: Color = .primary,
            rule: Color = Color(UIColor.separator)
        ) {
            self.title = title
            self.text = text
            self.footnote = footnote
            self.shimmer = shimmer
            self.rule = rule
        }
    }
    
    /// Palette for an agent's tool calls.
    struct ToolCalls {
        /// Color of what a call is doing, such as "Checking your location".
        public var title: Color
        /// Color of a call's outcome, its duration and the placeholder for unknown steps.
        public var detail: Color
        /// Color of a call in progress, including one waiting for a device.
        public var accent: Color
        /// Color of a completed call's check mark.
        public var success: Color
        /// Color of a failed call's mark.
        public var failure: Color
        
        /// Creates the tool call palette with optional overrides.
        public init(
            title: Color = .primary,
            detail: Color = .secondary,
            accent: Color = .accentColor,
            success: Color = .green,
            failure: Color = .red
        ) {
            self.title = title
            self.detail = detail
            self.accent = accent
            self.success = success
            self.failure = failure
        }
    }
    
    /// Palette for the question a client tool asks before it runs.
    struct ToolApprovals {
        /// Color of the question, such as "Share your location?".
        public var title: Color
        /// Color of the agent's reason and what allowing it shares.
        public var message: Color
        /// Background of the question's card.
        public var background: Color
        /// Border of the question's card.
        public var border: Color
        /// Tint of the buttons that allow or decline the call.
        public var accent: Color
        /// Color of the note when an answer could not be sent.
        public var failure: Color
        
        /// Creates the tool approval palette with optional overrides.
        public init(
            title: Color = .primary,
            message: Color = .secondary,
            background: Color = Color(UIColor.secondarySystemBackground),
            border: Color = Color(UIColor.separator),
            accent: Color = .accentColor,
            failure: Color = .red
        ) {
            self.title = title
            self.message = message
            self.background = background
            self.border = border
            self.accent = accent
            self.failure = failure
        }
    }
}
