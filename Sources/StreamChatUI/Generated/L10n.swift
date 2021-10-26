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
      internal static var cancel: String { L10n.tr("Localizable", "alert.actions.cancel") }
      /// Delete
      internal static var delete: String { L10n.tr("Localizable", "alert.actions.delete") }
      /// Ok
      internal static var ok: String { L10n.tr("Localizable", "alert.actions.ok") }
    }
  }

  internal enum Attachment {
    /// The max number of attachments per message is %d.
    internal static func maxCountExceeded(_ p1: Int) -> String {
      return L10n.tr("Localizable", "attachment.max-count-exceeded", p1)
    }
    /// Attachment size exceed the limit.
    internal static var maxSizeExceeded: String { L10n.tr("Localizable", "attachment.max-size-exceeded") }
  }

  internal enum Channel {
    internal enum Item {
      /// No messages
      internal static var emptyMessages: String { L10n.tr("Localizable", "channel.item.empty-messages") }
      /// are typing ...
      internal static var typingPlural: String { L10n.tr("Localizable", "channel.item.typing-plural") }
      /// is typing ...
      internal static var typingSingular: String { L10n.tr("Localizable", "channel.item.typing-singular") }
    }
    internal enum Name {
      /// and
      internal static var and: String { L10n.tr("Localizable", "channel.name.and") }
      /// and %@ more
      internal static func andXMore(_ p1: Any) -> String {
        return L10n.tr("Localizable", "channel.name.andXMore", String(describing: p1))
      }
      /// NoChannel
      internal static var missing: String { L10n.tr("Localizable", "channel.name.missing") }
    }
  }

  internal enum Composer {
    internal enum Checkmark {
      /// Also send in channel
      internal static var channelReply: String { L10n.tr("Localizable", "composer.checkmark.channel-reply") }
      /// Also send as direct message
      internal static var directMessageReply: String { L10n.tr("Localizable", "composer.checkmark.direct-message-reply") }
    }
    internal enum Picker {
      /// Cancel
      internal static var cancel: String { L10n.tr("Localizable", "composer.picker.cancel") }
      /// File
      internal static var file: String { L10n.tr("Localizable", "composer.picker.file") }
      /// Photo or Video
      internal static var media: String { L10n.tr("Localizable", "composer.picker.media") }
      /// Choose attachment type: 
      internal static var title: String { L10n.tr("Localizable", "composer.picker.title") }
    }
    internal enum Placeholder {
      /// Search GIFs
      internal static var giphy: String { L10n.tr("Localizable", "composer.placeholder.giphy") }
      /// Send a message
      internal static var message: String { L10n.tr("Localizable", "composer.placeholder.message") }
    }
    internal enum Suggestions {
      internal enum Commands {
        /// Instant Commands
        internal static var header: String { L10n.tr("Localizable", "composer.suggestions.commands.header") }
      }
    }
    internal enum Title {
      /// Edit Message
      internal static var edit: String { L10n.tr("Localizable", "composer.title.edit") }
      /// Reply to Message
      internal static var reply: String { L10n.tr("Localizable", "composer.title.reply") }
    }
  }

  internal enum Dates {
    /// last seen %d days ago
    internal static func timeAgoDaysPlural(_ p1: Int) -> String {
      return L10n.tr("Localizable", "dates.time-ago-days-plural", p1)
    }
    /// last seen one day ago
    internal static var timeAgoDaysSingular: String { L10n.tr("Localizable", "dates.time-ago-days-singular") }
    /// last seen %d hours ago
    internal static func timeAgoHoursPlural(_ p1: Int) -> String {
      return L10n.tr("Localizable", "dates.time-ago-hours-plural", p1)
    }
    /// last seen one hour ago
    internal static var timeAgoHoursSingular: String { L10n.tr("Localizable", "dates.time-ago-hours-singular") }
    /// last seen %d minutes ago
    internal static func timeAgoMinutesPlural(_ p1: Int) -> String {
      return L10n.tr("Localizable", "dates.time-ago-minutes-plural", p1)
    }
    /// last seen one minute ago
    internal static var timeAgoMinutesSingular: String { L10n.tr("Localizable", "dates.time-ago-minutes-singular") }
    /// last seen %d months ago
    internal static func timeAgoMonthsPlural(_ p1: Int) -> String {
      return L10n.tr("Localizable", "dates.time-ago-months-plural", p1)
    }
    /// last seen one month ago
    internal static var timeAgoMonthsSingular: String { L10n.tr("Localizable", "dates.time-ago-months-singular") }
    /// last seen %d seconds ago
    internal static func timeAgoSecondsPlural(_ p1: Int) -> String {
      return L10n.tr("Localizable", "dates.time-ago-seconds-plural", p1)
    }
    /// last seen just one second ago
    internal static var timeAgoSecondsSingular: String { L10n.tr("Localizable", "dates.time-ago-seconds-singular") }
    /// last seen %d weeks ago
    internal static func timeAgoWeeksPlural(_ p1: Int) -> String {
      return L10n.tr("Localizable", "dates.time-ago-weeks-plural", p1)
    }
    /// last seen one week ago
    internal static var timeAgoWeeksSingular: String { L10n.tr("Localizable", "dates.time-ago-weeks-singular") }
  }

  internal enum Message {
    /// Message deleted
    internal static var deletedMessagePlaceholder: String { L10n.tr("Localizable", "message.deleted-message-placeholder") }
    /// Only visible to you
    internal static var onlyVisibleToYou: String { L10n.tr("Localizable", "message.only-visible-to-you") }
    internal enum Actions {
      /// Copy Message
      internal static var copy: String { L10n.tr("Localizable", "message.actions.copy") }
      /// Delete Message
      internal static var delete: String { L10n.tr("Localizable", "message.actions.delete") }
      /// Edit Message
      internal static var edit: String { L10n.tr("Localizable", "message.actions.edit") }
      /// Reply
      internal static var inlineReply: String { L10n.tr("Localizable", "message.actions.inline-reply") }
      /// Resend
      internal static var resend: String { L10n.tr("Localizable", "message.actions.resend") }
      /// Thread Reply
      internal static var threadReply: String { L10n.tr("Localizable", "message.actions.thread-reply") }
      /// Block User
      internal static var userBlock: String { L10n.tr("Localizable", "message.actions.user-block") }
      /// Mute User
      internal static var userMute: String { L10n.tr("Localizable", "message.actions.user-mute") }
      /// Unblock User
      internal static var userUnblock: String { L10n.tr("Localizable", "message.actions.user-unblock") }
      /// Unmute User
      internal static var userUnmute: String { L10n.tr("Localizable", "message.actions.user-unmute") }
      internal enum Delete {
        /// Are you sure you want to permanently delete this message?
        internal static var confirmationMessage: String { L10n.tr("Localizable", "message.actions.delete.confirmation-message") }
        /// Delete Message
        internal static var confirmationTitle: String { L10n.tr("Localizable", "message.actions.delete.confirmation-title") }
      }
    }
    internal enum Sending {
      /// UPLOADING FAILED
      internal static var attachmentUploadingFailed: String { L10n.tr("Localizable", "message.sending.attachment-uploading-failed") }
    }
    internal enum Threads {
      /// Plural format key: "%#@replies@"
      internal static func count(_ p1: Int) -> String {
        return L10n.tr("Localizable", "message.threads.count", p1)
      }
      /// Thread Reply
      internal static var reply: String { L10n.tr("Localizable", "message.threads.reply") }
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
      internal static var offline: String { L10n.tr("Localizable", "message.title.offline") }
      /// Online
      internal static var online: String { L10n.tr("Localizable", "message.title.online") }
    }
  }

  internal enum MessageList {
    internal enum TypingIndicator {
      /// Someone is typing
      internal static var typingUnknown: String { L10n.tr("Localizable", "messageList.typingIndicator.typing-unknown") }
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
     // TODO: Using using Appearance.default prohibits using Appearance injection
     let format = Appearance.default.localizationProvider(key, table)
     return String(format: format, locale: Locale.current, arguments: args)
  }
}

private final class BundleToken {
  static let bundle: Bundle = .streamChatUI
}

