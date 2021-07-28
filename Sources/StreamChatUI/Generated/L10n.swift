// Generated using SwiftGen — https://github.com/SwiftGen/SwiftGen

import Foundation


// MARK: - Strings

internal enum L10n {
  /// %d of %d
  internal static func currentSelection(_ p1: Int, _ p2: Int) -> String {
    return L10n.tr("Localizable", "current-selection", p1, p2)
  }

  internal enum Alert {
    internal enum Actions {
      /// Cancel
      internal static let cancel = L10n.tr("Localizable", "alert.actions.cancel")
      /// Delete
      internal static let delete = L10n.tr("Localizable", "alert.actions.delete")
      /// Ok
      internal static let ok = L10n.tr("Localizable", "alert.actions.ok")
    }
  }

  internal enum Attachment {
    /// Attachment size exceed the limit.
    internal static let maxSizeExceeded = L10n.tr("Localizable", "attachment.max-size-exceeded")
  }

  internal enum Channel {
    internal enum Item {
      /// No messages
      internal static let emptyMessages = L10n.tr("Localizable", "channel.item.empty-messages")
      /// are typing ...
      internal static let typingPlural = L10n.tr("Localizable", "channel.item.typing-plural")
      /// is typing ...
      internal static let typingSingular = L10n.tr("Localizable", "channel.item.typing-singular")
    }
    internal enum Name {
      /// and
      internal static let and = L10n.tr("Localizable", "channel.name.and")
      /// and %@ more
      internal static func andXMore(_ p1: Any) -> String {
        return L10n.tr("Localizable", "channel.name.andXMore", String(describing: p1))
      }
      /// NoChannel
      internal static let missing = L10n.tr("Localizable", "channel.name.missing")
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
      /// Photo or Video
      internal static let media = L10n.tr("Localizable", "composer.picker.media")
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
        return L10n.tr("Localizable", "message.threads.count", p1)
      }
      /// Thread Reply
      internal static let reply = L10n.tr("Localizable", "message.threads.reply")
      /// with %@
      internal static func replyWith(_ p1: Any) -> String {
        return L10n.tr("Localizable", "message.threads.replyWith", String(describing: p1))
      }
    }
    internal enum Title {
      /// %d members, %d online
      internal static func group(_ p1: Int, _ p2: Int) -> String {
        return L10n.tr("Localizable", "message.title.group", p1, p2)
      }
      /// Offline
      internal static let offline = L10n.tr("Localizable", "message.title.offline")
      /// Online
      internal static let online = L10n.tr("Localizable", "message.title.online")
      /// Seen %@ ago
      internal static func seeMinutesAgo(_ p1: Any) -> String {
        return L10n.tr("Localizable", "message.title.see-minutes-ago", String(describing: p1))
      }
    }
  }

  internal enum MessageList {
    internal enum TypingIndicator {
      /// Someone is typing
      internal static let typingUnknown = L10n.tr("Localizable", "messageList.typingIndicator.typing-unknown")
      /// Plural format key: "%1$@%2$#@typing@"
      internal static func users(_ p1: Any, _ p2: Int) -> String {
        return L10n.tr("Localizable", "messageList.typingIndicator.users", String(describing: p1), p2)
      }
    }
  }
}

// MARK: - Implementation Details

extension L10n {
  private static func tr(_ table: String, _ key: String, _ args: CVarArg...) -> String {
     let format = Appearance.default.localizationProvider(key, table)
     return String(format: format, locale: Locale.current, arguments: args)
  }
}

private final class BundleToken {
  static let bundle: Bundle = .streamChatUI
}

