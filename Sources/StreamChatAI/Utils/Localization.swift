//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

enum L10n {
    enum Composer {
        static var placeholderAskAnything: String {
            localized("composer.placeholder.ask_anything", comment: "Placeholder shown in the message composer text field.")
        }
        
        static var buttonAllPhotos: String {
            localized("composer.button.all_photos", comment: "Label for the button that shows the full photo library.")
        }
    }
    
    enum StreamingMessage {
        static var codeBlockLanguageFallback: String {
            localized("streaming.code_block.language_fallback", comment: "Fallback name for code blocks when no language is provided.")
        }
    }
    
    enum Reasoning {
        static var thinking: String {
            localized("reasoning.title.thinking", comment: "Header of a model's reasoning while the model is still thinking.")
        }
        
        static func thinkingFor(_ duration: String) -> String {
            String(
                format: localized("reasoning.title.thinking_for", comment: "Header of a model's reasoning while it thinks. The argument is how long so far, such as 7s."),
                duration
            )
        }
        
        static var thought: String {
            localized("reasoning.title.thought", comment: "Header of a model's finished reasoning when its duration is unknown.")
        }
        
        static func thoughtFor(_ duration: String) -> String {
            String(
                format: localized("reasoning.title.thought_for", comment: "Header of a model's finished reasoning. The argument is a duration such as 12s."),
                duration
            )
        }
        
        static var showHint: String {
            localized("reasoning.accessibility.show", comment: "Accessibility hint of the reasoning header while the reasoning is hidden.")
        }
        
        static var hideHint: String {
            localized("reasoning.accessibility.hide", comment: "Accessibility hint of the reasoning header while the reasoning is shown.")
        }
    }
    
    enum ToolCall {
        static var awaitingClient: String {
            localized("tool_call.status.awaiting_client", comment: "A tool call waiting for a person's device to run it.")
        }
        
        static var awaitingApproval: String {
            localized("tool_call.status.awaiting_approval", comment: "A tool call waiting for a person to allow or decline it.")
        }
        
        static var declined: String {
            localized("tool_call.status.declined", comment: "A tool call the person declined, so it never ran.")
        }
        
        static var failed: String {
            localized("tool_call.status.failed", comment: "A tool call that failed, when the agent gave no reason.")
        }
        
        static var cancelled: String {
            localized("tool_call.status.cancelled", comment: "A tool call that was cancelled.")
        }
        
        static var unsupported: String {
            localized("ai_part.unsupported", comment: "Placeholder for an AI step this version of the app can't show.")
        }
    }
    
    enum ToolApproval {
        static var allow: String {
            localized("tool_approval.button.allow", comment: "Button that allows a tool call the AI agent asked to make.")
        }
        
        static var decline: String {
            localized("tool_approval.button.decline", comment: "Button that declines a tool call the AI agent asked to make, so it never runs.")
        }
        
        static var notSent: String {
            localized("tool_approval.error.not_sent", comment: "Shown under a tool call's question when the person's answer could not be sent.")
        }
    }
    
    enum Charts {
        static var series: String {
            localized("charts.series", comment: "Name of a chart's data series when the chart gives it none.")
        }
        
        static var pie: String {
            localized("charts.pie", comment: "Name of a pie chart's data when the chart gives it none.")
        }
        
        static var axisX: String {
            localized("charts.axis.x", comment: "Label of a chart's horizontal axis when the chart gives it none.")
        }
        
        static var axisY: String {
            localized("charts.axis.y", comment: "Label of a chart's vertical axis when the chart gives it none.")
        }
        
        static var size: String {
            localized("charts.size", comment: "Label of the size of a bubble chart's points.")
        }
        
        static var value: String {
            localized("charts.value", comment: "Label of the values of a pie chart or heatmap.")
        }
        
        static var category: String {
            localized("charts.category", comment: "Label of the categories of a pie chart.")
        }
        
        static var bin: String {
            localized("charts.bin", comment: "Label of a histogram's ranges of values.")
        }
        
        static var count: String {
            localized("charts.count", comment: "Label of how many values fall in each of a histogram's ranges.")
        }
    }
    
    enum Transcription {
        static var recognizerUnavailable: String {
            localized("transcription.error.recognizer_unavailable", comment: "Error shown when the speech recognizer cannot be used.")
        }
    }
    
    private static func localized(_ key: String, comment: StaticString) -> String {
        AIAppearance.localizationProvider(key, "Localizable")
    }
}
