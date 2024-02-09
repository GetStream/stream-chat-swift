//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
import XCTest
import StreamChat
@testable import StreamChatUI

// swiftlint:disable convenience_type

class MessageListPage {

    static var cells: XCUIElementQuery {
        app.cells.matching(NSPredicate(format: "identifier LIKE 'ChatMessageCell'"))
    }

    static var list: XCUIElement {
        app.tables.firstMatch
    }

    static var typingIndicator: XCUIElement {
        app.otherElements["TypingIndicatorView"].staticTexts.firstMatch
    }

    static var scrollToBottomButton: XCUIElement {
        app.buttons["ScrollToBottomButton"]
    }
    
    static var scrollToBottomButtonUnreadCount: XCUIElement {
        app.staticTexts["unreadCountLabel"]
    }

    enum NavigationBar {

        static var header: XCUIElement { app.otherElements["ChatChannelHeaderView"] }

        static var chatAvatar: XCUIElement {
            app.otherElements["ChatAvatarView"].images.firstMatch
        }

        static var chatName: XCUIElement {
            app.staticTexts.firstMatch
        }

        static var participants: XCUIElement {
            app.staticTexts.lastMatch!
        }

        static var debugMenu: XCUIElement {
            app.buttons["debug"].firstMatch
        }
    }

    enum Alert {
        enum Debug {
            // Add member
            static var alert: XCUIElement { app.alerts["Select an action"] }
            static var addMember: XCUIElement { alert.buttons["Add member"] }
            static var addMemberTextField: XCUIElement {app.textFields["debug_alert_textfield"] }
            static var addMemberOKButton: XCUIElement {app.alerts["Enter user id"].buttons["OK"] }

            // Remove member
            static var removeMember: XCUIElement { alert.buttons["Remove a member"] }
            static func selectMember(withUserId userId: String) -> XCUIElement {
                app.alerts["Select a member"].buttons[userId]
            }

            // Show member info
            static var showMemberInfo: XCUIElement { alert.buttons["Show Members"] }
            static var dismissMemberInfo: XCUIElement { app.alerts["Members"].buttons["Cancel"] }

            // Truncate channel
            static var truncateWithMessage: XCUIElement { alert.buttons["Truncate channel with message"] }
            static var truncateWithoutMessage: XCUIElement { alert.buttons["Truncate channel w/o message"] }
        }
    }

    enum Composer {
        static var sendButton: XCUIElement { app.buttons["SendButton"] }
        static var confirmButton: XCUIElement { app.buttons["ConfirmButton"] }
        static var attachmentButton: XCUIElement { app.buttons["AttachmentButton"] }
        static var commandButton: XCUIElement { app.buttons["CommandButton"] }
        static var inputField: XCUIElement { app.otherElements["inputTextContainer"] }
        static var textView: XCUIElement { inputField.textViews.firstMatch }
        static var cooldown: XCUIElement { app.staticTexts["cooldownLabel"] }
        static var placeholder: XCUIElement { textView.staticTexts.firstMatch }
        static var selectAllButton: XCUIElement { app.menuItems.matching(NSPredicate(format: "label LIKE 'Select All'")).firstMatch }
    }

    enum Reactions {
        static var lol: XCUIElement { reaction(label: "reaction lol big") }
        static var like: XCUIElement { reaction(label: "reaction thumbsup big") }
        static var love: XCUIElement { reaction(label: "reaction love big") }
        static var sad: XCUIElement { reaction(label: "reaction thumbsdown big") }
        static var wow: XCUIElement { reaction(label: "reaction wut big") }

        private static var id = "ChatMessageReactionItemView"

        private static func reaction(label: String) -> XCUIElement {
            let predicate = NSPredicate(
                format: "identifier LIKE '\(id)' AND label LIKE '\(label)'"
            )
            return app.buttons.matching(predicate).firstMatch
        }
    }

    enum ContextMenu {
        case reactions
        case reply
        case threadReply
        case copy
        case flag
        case mute
        case edit
        case delete
        case hardDelete
        case resend
        case block
        case unblock

        var element: XCUIElement {
            switch self {
            case .reactions:
                return Element.reactionsView
            case .reply:
                return Element.reply
            case .threadReply:
                return Element.threadReply
            case .copy:
                return Element.copy
            case .flag:
                return Element.flag
            case .mute:
                return Element.mute
            case .edit:
                return Element.edit
            case .delete:
                return Element.delete
            case .hardDelete:
                return Element.hardDelete
            case .resend:
                return Element.resend
            case .block:
                return Element.block
            case .unblock:
                return Element.unblock
            }
        }

        struct Element {
            static var reactionsView: XCUIElement { app.otherElements["ChatReactionPickerReactionsView"] }
            static var reply: XCUIElement { app.otherElements["InlineReplyActionItem"] }
            static var threadReply: XCUIElement { app.otherElements["ThreadReplyActionItem"] }
            static var copy: XCUIElement { app.otherElements["CopyActionItem"] }
            static var flag: XCUIElement { app.otherElements["FlagActionItem"] }
            static var mute: XCUIElement { app.otherElements["MuteUserActionItem"] }
            static var unmute: XCUIElement { app.otherElements["UnmuteUserActionItem"] }
            static var edit: XCUIElement { app.otherElements["EditActionItem"] }
            static var delete: XCUIElement { app.otherElements["DeleteActionItem"] }
            static var hardDelete: XCUIElement { app.otherElements["HardDeleteActionItem"] }
            static var resend: XCUIElement { app.otherElements["ResendActionItem"] }
            static var block: XCUIElement { app.otherElements["BlockUserActionItem"] }
            static var unblock: XCUIElement { app.otherElements["UnblockUserActionItem"] }
        }
    }

    enum Attributes {
        static func reactionButton(in messageCell: XCUIElement) -> XCUIElement {
            messageCell.buttons["ChatMessageReactionItemView"]
        }

        static func threadReplyCountButton(in messageCell: XCUIElement) -> XCUIElement {
            messageCell.buttons["threadReplyCountButton"]
        }

        static func time(in messageCell: XCUIElement) -> XCUIElement {
            messageCell.staticTexts["timestampLabel"]
        }

        static func author(messageCell: XCUIElement) -> XCUIElement {
            messageCell.staticTexts["authorNameLabel"]
        }

        static func text(in messageCell: XCUIElement) -> XCUIElement {
            messageCell.textViews["textView"].firstMatch
        }

        static func quotedText(_ text: String, in messageCell: XCUIElement) -> XCUIElement {
            messageCell.textViews.matching(NSPredicate(format: "value LIKE '\(text)'")).firstMatch
        }

        static func text(_ text: String, in messageCell: XCUIElement) -> XCUIElement {
            messageCell.textViews.matching(NSPredicate(format: "value LIKE '\(text)'")).firstMatch
        }

        static func deletedIcon(in messageCell: XCUIElement) -> XCUIElement {
            messageCell.images["onlyVisibleToYouImageView"]
        }

        static func deletedLabel(in messageCell: XCUIElement) -> XCUIElement {
            messageCell.staticTexts["onlyVisibleToYouLabel"]
        }

        static func errorButton(in messageCell: XCUIElement) -> XCUIElement {
            messageCell.buttons["error indicator"]
        }

        static func readCount(in messageCell: XCUIElement) -> XCUIElement {
            messageCell.staticTexts["messageReadСountsLabel"]
        }

        static func statusCheckmark(for status: MessageDeliveryStatus?, in messageCell: XCUIElement) -> XCUIElement {
            var identifier = "There is no status checkmark"
            if let status = status {
                identifier = "imageView_\(status.rawValue)"
            }
            return messageCell.images[identifier]
        }

        static func giphyButtons(in messageCell: XCUIElement) -> XCUIElementQuery {
            messageCell.buttons.matching(NSPredicate(format: "identifier LIKE 'ActionButton'"))
        }

        static func giphySendButton(in messageCell: XCUIElement) -> XCUIElementQuery {
            attachmentActionButton(in: messageCell, label: "Send")
        }

        static func giphyShuffleButton(in messageCell: XCUIElement) -> XCUIElementQuery {
            attachmentActionButton(in: messageCell, label: "Shuffle")
        }

        static func giphyCancelButton(in messageCell: XCUIElement) -> XCUIElementQuery {
            attachmentActionButton(in: messageCell, label: "Cancel")
        }

        static func giphyLabel(in messageCell: XCUIElement) -> XCUIElement {
            messageCell.staticTexts["GIPHY"]
        }

        private static func attachmentActionButton(in messageCell: XCUIElement, label: String) -> XCUIElementQuery {
            giphyButtons(in: messageCell).matching(NSPredicate(format: "label LIKE '\(label)'"))
        }

        static var deletedMessagePlaceholder: String {
            L10n.Message.deletedMessagePlaceholder
        }

        static func images(in messageCell: XCUIElement) -> XCUIElementQuery {
            messageCell.images.matching(NSPredicate(format: "identifier LIKE 'imageView'"))
        }

        static func fullscreenImage() -> XCUIElement {
            app.cells["ImageAttachmentGalleryCell"].images.firstMatch
        }

        static func fileNames(in messageCell: XCUIElement) -> XCUIElementQuery {
            messageCell.staticTexts.matching(NSPredicate(format: "identifier LIKE 'fileNameLabel'"))
        }

        static func videoPlayer() -> XCUIElement {
            app.otherElements["PlayerView"]
        }
        
        static func restartAttachmentUploadIcon(in messageCell: XCUIElement) -> XCUIElement {
            messageCell.buttons["AttachmentActionButton"]
        }
        
        static func uploadingProgressLabel(in messageCell: XCUIElement) -> XCUIElement {
            messageCell.staticTexts["uploadingProgressLabel"]
        }

        enum LinkPreview {
            static func link(in messageCell: XCUIElement) -> XCUIElement {
                messageCell.links.firstMatch
            }

            static func image(in messageCell: XCUIElement) -> XCUIElement {
                messageCell.images["imagePreview"]
            }

            static func serviceName(in messageCell: XCUIElement) -> XCUIElement {
                messageCell.staticTexts["authorLabel"]
            }

            static func title(in messageCell: XCUIElement) -> XCUIElement {
                messageCell.staticTexts["titleLabel"]
            }

            static func description(in messageCell: XCUIElement) -> XCUIElement {
                messageCell.textViews["bodyTextView"]
            }
        }
    }

    enum PopUpButtons {
        static var cancel: XCUIElement {
            app.buttons.matching(NSPredicate(format: "label LIKE 'Cancel'")).firstMatch
        }

        static var delete: XCUIElement {
            app.buttons.matching(NSPredicate(format: "label LIKE 'Delete'")).firstMatch
        }
    }

    enum AttachmentMenu {
        static var fileButton: XCUIElement {
            app.buttons.matching(NSPredicate(format: "label LIKE 'File'")).firstMatch
        }

        static var photoOrVideoButton: XCUIElement {
            app.buttons.matching(NSPredicate(format: "label LIKE 'Photo or Video'")).firstMatch
        }

        static var cancelButton: XCUIElement {
            app.buttons.matching(NSPredicate(format: "label LIKE 'Cancel'")).firstMatch
        }

        static var images: XCUIElementQuery {
            if ProcessInfo().operatingSystemVersion.majorVersion > 13 {
                return app.scrollViews.images
            } else {
                return app.collectionViews.cells
            }
        }
    }

    enum ComposerCommands {
        static var cells: XCUIElementQuery {
            app.cells.matching(NSPredicate(format: "identifier LIKE 'ChatCommandSuggestionCollectionViewCell'"))
        }

        static var headerTitle: XCUIElement {
            app.otherElements["ChatSuggestionsHeaderView"].staticTexts.firstMatch
        }

        static var headerImage: XCUIElement {
            app.otherElements["ChatSuggestionsHeaderView"].images.firstMatch
        }

        static var giphyImage: XCUIElement {
            app.images["command_giphy"]
        }
    }

    enum ComposerMentions {
        static var cells: XCUIElementQuery {
            app.cells.matching(NSPredicate(format: "identifier LIKE 'ChatMentionSuggestionCollectionViewCell'"))
        }
    }
}

// swiftlint:enable convenience_type
