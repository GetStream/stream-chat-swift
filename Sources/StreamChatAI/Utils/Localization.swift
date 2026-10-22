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
    
    enum Conversation {
        static var scrollToLatest: String {
            localized("conversation.button.scroll_to_latest", comment: "Accessibility label of the button that scrolls to the end of the conversation.")
        }
    }

    enum Attachment {
        static var image: String {
            localized("attachment.image", comment: "The name of an image attachment without one of its own.")
        }

        static var file: String {
            localized("attachment.file", comment: "The name of a file attachment without one of its own.")
        }

        static func details(_ type: String, _ size: String) -> String {
            String(
                format: localized("attachment.details", comment: "A file's type and size. The arguments are its type, such as PDF, and its size, such as 2.4 MB."),
                type,
                size
            )
        }
    }

    enum MessageActions {
        static var copy: String {
            localized("message_actions.copy", comment: "Copies a message's text.")
        }

        static var copied: String {
            localized("message_actions.copied", comment: "Said for a moment once a message's text is copied.")
        }

        static var share: String {
            localized("message_actions.share", comment: "Shares a reply's text.")
        }

        static var regenerate: String {
            localized("message_actions.regenerate", comment: "Asks the AI agent for a new reply in place of this one.")
        }

        static var ratePositive: String {
            localized("message_actions.rate_positive", comment: "Rates a reply as good.")
        }

        static var rateNegative: String {
            localized("message_actions.rate_negative", comment: "Rates a reply as bad.")
        }

        static var edit: String {
            localized("message_actions.edit", comment: "Edits a message the person sent.")
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
        
        static var awaitingAuthorization: String {
            localized("tool_call.status.awaiting_authorization", comment: "A tool call waiting for a person to sign in at a provider it needs.")
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
    
    enum ToolAuthorization {
        static var connect: String {
            localized("tool_authorization.button.connect", comment: "Button that opens the sign-in at a provider a tool call of the AI agent needs.")
        }
        
        static var connecting: String {
            localized("tool_authorization.button.connecting", comment: "The connect button while the sign-in is open or finishing.")
        }
        
        static var decline: String {
            localized("tool_authorization.button.decline", comment: "Button that declines to sign in, so the tool call never runs.")
        }
        
        static var notOpened: String {
            localized("tool_authorization.error.not_opened", comment: "Shown under a tool call's sign-in when the sign-in page couldn't be opened.")
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

    enum Voice {
        static var agent: String {
            localized("voice.accessibility.agent", comment: "Accessibility label of the animation that shows what a voice agent is doing.")
        }

        static var idle: String {
            localized("voice.state.idle", comment: "A voice agent waiting to be spoken to.")
        }

        static var connecting: String {
            localized("voice.state.connecting", comment: "A voice agent that is not ready to talk yet.")
        }

        static var listening: String {
            localized("voice.state.listening", comment: "A voice agent hearing somebody talk.")
        }

        static var thinking: String {
            localized("voice.state.thinking", comment: "A voice agent working on its answer.")
        }

        static var speaking: String {
            localized("voice.state.speaking", comment: "A voice agent talking.")
        }
    }
    
    private static func localized(_ key: String, comment: StaticString) -> String {
        AIAppearance.localizationProvider(key, "Localizable")
    }
}
