//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

// swiftlint:disable all
// Generated using SwiftGen — https://github.com/SwiftGen/SwiftGen

import Foundation

// swiftlint:disable superfluous_disable_command file_length implicit_return

// MARK: - Strings

// swiftlint:disable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:disable nesting type_body_length type_name vertical_whitespace_opening_braces
internal enum L10n {
    internal enum Alert {
        internal enum Actions {
            /// Cancel
            internal static let cancel = L10n.tr("Localizable", "alert.actions.cancel")
            /// Delete
            internal static let delete = L10n.tr("Localizable", "alert.actions.delete")
        }
    }

    internal enum Channel {
        internal enum Name {
            /// and
            internal static let and = L10n.tr("Localizable", "channel.name.and")
            /// NoChannel
            internal static let missing = L10n.tr("Localizable", "channel.name.missing")
            /// more
            internal static let more = L10n.tr("Localizable", "channel.name.more")
        }
    }

    internal enum Composer {
        internal enum Checkmark {
            /// Also send in channel
            internal static let channelReply = L10n.tr("Localizable", "composer.checkmark.channel-reply")
            /// Also send as direct message
            internal static let directMessageReply = L10n.tr("Localizable", "composer.checkmark.direct-message-reply")
        }

        internal enum Picker {
            /// Cancel
            internal static let cancel = L10n.tr("Localizable", "composer.picker.cancel")
            /// File
            internal static let file = L10n.tr("Localizable", "composer.picker.file")
            /// Photo
            internal static let image = L10n.tr("Localizable", "composer.picker.image")
            /// Choose attachment type:
            internal static let title = L10n.tr("Localizable", "composer.picker.title")
        }

        internal enum Placeholder {
            /// Search GIFs
            internal static let giphy = L10n.tr("Localizable", "composer.placeholder.giphy")
            /// Send a message
            internal static let message = L10n.tr("Localizable", "composer.placeholder.message")
        }

        internal enum Suggestions {
            internal enum Commands {
                /// Instant Commands
                internal static let header = L10n.tr("Localizable", "composer.suggestions.commands.header")
            }
        }

        internal enum Title {
            /// Edit Message
            internal static let edit = L10n.tr("Localizable", "composer.title.edit")
            /// Reply to Message
            internal static let reply = L10n.tr("Localizable", "composer.title.reply")
        }
    }

    internal enum Message {
        /// Message deleted
        internal static let deletedMessagePlaceholder = L10n.tr("Localizable", "message.deleted-message-placeholder")
        /// Only visible to you
        internal static let onlyVisibleToYou = L10n.tr("Localizable", "message.only-visible-to-you")
        internal enum Actions {
            /// Copy Message
            internal static let copy = L10n.tr("Localizable", "message.actions.copy")
            /// Delete Message
            internal static let delete = L10n.tr("Localizable", "message.actions.delete")
            /// Edit Message
            internal static let edit = L10n.tr("Localizable", "message.actions.edit")
            /// Reply
            internal static let inlineReply = L10n.tr("Localizable", "message.actions.inline-reply")
            /// Resend
            internal static let resend = L10n.tr("Localizable", "message.actions.resend")
            /// Thread Reply
            internal static let threadReply = L10n.tr("Localizable", "message.actions.thread-reply")
            /// Block User
            internal static let userBlock = L10n.tr("Localizable", "message.actions.user-block")
            /// Mute User
            internal static let userMute = L10n.tr("Localizable", "message.actions.user-mute")
            /// Unblock User
            internal static let userUnblock = L10n.tr("Localizable", "message.actions.user-unblock")
            /// Unmute User
            internal static let userUnmute = L10n.tr("Localizable", "message.actions.user-unmute")
            internal enum Delete {
                /// Are you sure you want to permanently delete this message?
                internal static let confirmationMessage = L10n.tr("Localizable", "message.actions.delete.confirmation-message")
                /// Delete Message
                internal static let confirmationTitle = L10n.tr("Localizable", "message.actions.delete.confirmation-title")
            }
        }

        internal enum Sending {
            /// UPLOADING FAILED
            internal static let attachmentUploadingFailed = L10n.tr("Localizable", "message.sending.attachment-uploading-failed")
        }

        internal enum Threads {
            /// Plural format key: "%#@replies@"
            internal static func count(_ p1: Int) -> String {
                L10n.tr("Localizable", "message.threads.count", p1)
            }

            /// Thread Reply
            internal static let reply = L10n.tr("Localizable", "message.threads.reply")
        }
    }
}

// swiftlint:enable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:enable nesting type_body_length type_name vertical_whitespace_opening_braces

// MARK: - Implementation Details

extension L10n {
    private static func tr(_ table: String, _ key: String, _ args: CVarArg...) -> String {
        let format = BundleToken.bundle.localizedString(forKey: key, value: nil, table: table)
        return String(format: format, locale: Locale.current, arguments: args)
    }
}

// swiftlint:disable convenience_type
private final class BundleToken {
    static let bundle: Bundle = {
        #if SWIFT_PACKAGE
        return Bundle.module
        #else
        return Bundle(for: BundleToken.self)
        #endif
    }()
}

// swiftlint:enable convenience_type
