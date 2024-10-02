// Generated using SwiftGen — https://github.com/SwiftGen/SwiftGen

import Foundation


// MARK: - Strings

internal enum L10n {
  /// %d of %d
  internal static func currentSelection(_ p1: Int, _ p2: Int) -> String {
    return L10n.tr("Localizable", "current-selection", p1, p2)
  }
  /// You
  internal static var you: String { L10n.tr("Localizable", "you") }

  internal enum Alert {
    internal enum Actions {
      /// Cancel
      internal static var cancel: String { L10n.tr("Localizable", "alert.actions.cancel") }
      /// Delete
      internal static var delete: String { L10n.tr("Localizable", "alert.actions.delete") }
      /// Flag
      internal static var flag: String { L10n.tr("Localizable", "alert.actions.flag") }
      /// Ok
      internal static var ok: String { L10n.tr("Localizable", "alert.actions.ok") }
    }
    internal enum Poll {
      /// Add a comment.
      internal static var addComment: String { L10n.tr("Localizable", "alert.poll.add-comment") }
      /// It was not possible to create the poll.
      internal static var createErrorMessage: String { L10n.tr("Localizable", "alert.poll.create-error-message") }
      /// Discard Changes
      internal static var discardChanges: String { L10n.tr("Localizable", "alert.poll.discard-changes") }
      /// Are you sure you want to discard your poll?
      internal static var discardChangesMessage: String { L10n.tr("Localizable", "alert.poll.discard-changes-message") }
      /// End
      internal static var end: String { L10n.tr("Localizable", "alert.poll.end") }
      /// Nobody will be able to vote in this poll anymore.
      internal static var endTitle: String { L10n.tr("Localizable", "alert.poll.end-title") }
      /// Something went wrong!
      internal static var genericErrorTitle: String { L10n.tr("Localizable", "alert.poll.generic-error-title") }
      /// Keep Editing
      internal static var keepEditing: String { L10n.tr("Localizable", "alert.poll.keep-editing") }
      /// Send
      internal static var send: String { L10n.tr("Localizable", "alert.poll.send") }
      /// Suggest an option.
      internal static var suggestOption: String { L10n.tr("Localizable", "alert.poll.suggest-option") }
      /// Update your comment.
      internal static var updateComment: String { L10n.tr("Localizable", "alert.poll.update-comment") }
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

  internal enum Audio {
    internal enum Player {
      /// x%@
      internal static func rate(_ p1: Any) -> String {
        return L10n.tr("Localizable", "audio.player.rate", String(describing: p1))
      }
    }
  }

  internal enum Channel {
    internal enum Item {
      /// Audio
      internal static var audio: String { L10n.tr("Localizable", "channel.item.audio") }
      /// No messages
      internal static var emptyMessages: String { L10n.tr("Localizable", "channel.item.empty-messages") }
      /// Photo
      internal static var photo: String { L10n.tr("Localizable", "channel.item.photo") }
      /// are typing ...
      internal static var typingPlural: String { L10n.tr("Localizable", "channel.item.typing-plural") }
      /// is typing ...
      internal static var typingSingular: String { L10n.tr("Localizable", "channel.item.typing-singular") }
      /// Video
      internal static var video: String { L10n.tr("Localizable", "channel.item.video") }
      internal enum Search {
        ///  in %@
        internal static func `in`(_ p1: Any) -> String {
          return L10n.tr("Localizable", "channel.item.search.in", String(describing: p1))
        }
      }
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

  internal enum ChannelList {
    /// Search
    internal static var search: String { L10n.tr("Localizable", "channelList.search") }
    internal enum Empty {
      /// Start a chat
      internal static var button: String { L10n.tr("Localizable", "channelList.empty.button") }
      /// How about sending your first message to a friend?
      internal static var subtitle: String { L10n.tr("Localizable", "channelList.empty.subtitle") }
      /// Let's start chatting!
      internal static var title: String { L10n.tr("Localizable", "channelList.empty.title") }
    }
    internal enum Error {
      /// Error loading channels
      internal static var message: String { L10n.tr("Localizable", "channelList.error.message") }
    }
    internal enum Preview {
      internal enum Voice {
        /// Voice message
        internal static var recording: String { L10n.tr("Localizable", "channelList.preview.voice.recording") }
      }
    }
    internal enum Search {
      internal enum Empty {
        /// No results for %@
        internal static func subtitle(_ p1: Any) -> String {
          return L10n.tr("Localizable", "channelList.search.empty.subtitle", String(describing: p1))
        }
      }
    }
  }

  internal enum Composer {
    internal enum Checkmark {
      /// Also send in channel
      internal static var channelReply: String { L10n.tr("Localizable", "composer.checkmark.channel-reply") }
      /// Also send as direct message
      internal static var directMessageReply: String { L10n.tr("Localizable", "composer.checkmark.direct-message-reply") }
    }
    internal enum LinksDisabled {
      /// Sending links is not allowed in this conversation.
      internal static var subtitle: String { L10n.tr("Localizable", "composer.links-disabled.subtitle") }
      /// Links are disabled
      internal static var title: String { L10n.tr("Localizable", "composer.links-disabled.title") }
    }
    internal enum Picker {
      /// Camera
      internal static var camera: String { L10n.tr("Localizable", "composer.picker.camera") }
      /// Cancel
      internal static var cancel: String { L10n.tr("Localizable", "composer.picker.cancel") }
      /// File
      internal static var file: String { L10n.tr("Localizable", "composer.picker.file") }
      /// Photo or Video
      internal static var media: String { L10n.tr("Localizable", "composer.picker.media") }
      /// Create Poll
      internal static var poll: String { L10n.tr("Localizable", "composer.picker.poll") }
      /// Choose attachment type: 
      internal static var title: String { L10n.tr("Localizable", "composer.picker.title") }
    }
    internal enum Placeholder {
      /// Search GIFs
      internal static var giphy: String { L10n.tr("Localizable", "composer.placeholder.giphy") }
      /// Send a message
      internal static var message: String { L10n.tr("Localizable", "composer.placeholder.message") }
      /// You can't send messages in this channel
      internal static var messageDisabled: String { L10n.tr("Localizable", "composer.placeholder.messageDisabled") }
      /// Slow mode ON
      internal static var slowMode: String { L10n.tr("Localizable", "composer.placeholder.slowMode") }
    }
    internal enum QuotedMessage {
      /// Giphy
      internal static var giphy: String { L10n.tr("Localizable", "composer.quoted-message.giphy") }
      /// Photo
      internal static var photo: String { L10n.tr("Localizable", "composer.quoted-message.photo") }
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
    /// Edited
    internal static var edited: String { L10n.tr("Localizable", "message.edited") }
    /// Only visible to you
    internal static var onlyVisibleToYou: String { L10n.tr("Localizable", "message.only-visible-to-you") }
    /// Translated to %@
    internal static func translatedTo(_ p1: Any) -> String {
      return L10n.tr("Localizable", "message.translatedTo", String(describing: p1))
    }
    /// Unsupported Attachment
    internal static var unsupportedAttachment: String { L10n.tr("Localizable", "message.unsupported-attachment") }
    internal enum Actions {
      /// Copy Message
      internal static var copy: String { L10n.tr("Localizable", "message.actions.copy") }
      /// Delete Message
      internal static var delete: String { L10n.tr("Localizable", "message.actions.delete") }
      /// Edit Message
      internal static var edit: String { L10n.tr("Localizable", "message.actions.edit") }
      /// Flag Message
      internal static var flag: String { L10n.tr("Localizable", "message.actions.flag") }
      /// Reply
      internal static var inlineReply: String { L10n.tr("Localizable", "message.actions.inline-reply") }
      /// Mark as unread
      internal static var markUnread: String { L10n.tr("Localizable", "message.actions.mark-unread") }
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
      internal enum Flag {
        /// Do you want to send a copy of this message to a moderator for further investigation?
        internal static var confirmationMessage: String { L10n.tr("Localizable", "message.actions.flag.confirmation-message") }
        /// Flag Message
        internal static var confirmationTitle: String { L10n.tr("Localizable", "message.actions.flag.confirmation-title") }
      }
    }
    internal enum Item {
      /// This message was deleted.
      internal static var deleted: String { L10n.tr("Localizable", "message.item.deleted") }
    }
    internal enum Moderation {
      /// Delete Message
      internal static var delete: String { L10n.tr("Localizable", "message.moderation.delete") }
      /// Edit Message
      internal static var edit: String { L10n.tr("Localizable", "message.moderation.edit") }
      /// Consider how your comment might make others feel and be sure to follow our Community Guidelines.
      internal static var message: String { L10n.tr("Localizable", "message.moderation.message") }
      /// Send Anyway
      internal static var resend: String { L10n.tr("Localizable", "message.moderation.resend") }
      /// Are you sure?
      internal static var title: String { L10n.tr("Localizable", "message.moderation.title") }
    }
    internal enum Preview {
      /// %@ created:
      internal static func pollSomeoneCreated(_ p1: Any) -> String {
        return L10n.tr("Localizable", "message.preview.poll-someone-created", String(describing: p1))
      }
      /// %@ voted:
      internal static func pollSomeoneVoted(_ p1: Any) -> String {
        return L10n.tr("Localizable", "message.preview.poll-someone-voted", String(describing: p1))
      }
      /// You created:
      internal static var pollYouCreated: String { L10n.tr("Localizable", "message.preview.poll-you-created") }
      /// You voted:
      internal static var pollYouVoted: String { L10n.tr("Localizable", "message.preview.poll-you-voted") }
    }
    internal enum Sending {
      /// UPLOADING FAILED
      internal static var attachmentUploadingFailed: String { L10n.tr("Localizable", "message.sending.attachment-uploading-failed") }
    }
    internal enum Thread {
      internal enum Replies {
        /// Plural format key: "%#@replies@"
        internal static func count(_ p1: Int) -> String {
          return L10n.tr("Localizable", "message.thread.replies.count", p1)
        }
      }
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
    internal enum Unread {
      /// Plural format key: "%#@unread@"
      internal static func count(_ p1: Int) -> String {
        return L10n.tr("Localizable", "message.unread.count", p1)
      }
    }
  }

  internal enum MessageList {
    /// Plural format key: "%#@unreads@"
    internal static func jumpToUnreadButton(_ p1: Int) -> String {
      return L10n.tr("Localizable", "messageList.jump-to-unread-button", p1)
    }
    internal enum TypingIndicator {
      /// Someone is typing
      internal static var typingUnknown: String { L10n.tr("Localizable", "messageList.typingIndicator.typing-unknown") }
      /// Plural format key: "%1$@%2$#@typing@"
      internal static func users(_ p1: Any, _ p2: Int) -> String {
        return L10n.tr("Localizable", "messageList.typingIndicator.users", String(describing: p1), p2)
      }
    }
  }

  internal enum Polls {
    /// Add a Comment
    internal static var addComment: String { L10n.tr("Localizable", "polls.add-comment") }
    /// Poll Options
    internal static var allOptionsTitle: String { L10n.tr("Localizable", "polls.all-options-title") }
    /// Anonymous
    internal static var anonymousAuthor: String { L10n.tr("Localizable", "polls.anonymous-author") }
    /// Poll Comments
    internal static var commentsTitle: String { L10n.tr("Localizable", "polls.comments-title") }
    /// Poll Results
    internal static var resultsTitle: String { L10n.tr("Localizable", "polls.results-title") }
    /// Update your Comment
    internal static var updateComment: String { L10n.tr("Localizable", "polls.update-comment") }
    /// %d votes
    internal static func votes(_ p1: Int) -> String {
      return L10n.tr("Localizable", "polls.votes", p1)
    }
    internal enum Button {
      /// Add Comment
      internal static var addComment: String { L10n.tr("Localizable", "polls.button.add-comment") }
      /// See %d More Options
      internal static func allOptions(_ p1: Int) -> String {
        return L10n.tr("Localizable", "polls.button.all-options", p1)
      }
      /// End Vote
      internal static var endVote: String { L10n.tr("Localizable", "polls.button.endVote") }
      /// Show all
      internal static var showAll: String { L10n.tr("Localizable", "polls.button.show-all") }
      /// Suggest an Option
      internal static var suggestOption: String { L10n.tr("Localizable", "polls.button.suggest-option") }
      /// View %d Comments
      internal static func viewComments(_ p1: Int) -> String {
        return L10n.tr("Localizable", "polls.button.view-comments", p1)
      }
      /// View Results
      internal static var viewResults: String { L10n.tr("Localizable", "polls.button.viewResults") }
    }
    internal enum Creation {
      /// Add a comment
      internal static var addAComment: String { L10n.tr("Localizable", "polls.creation.add-a-comment") }
      /// Add an option
      internal static var addAnOptionPlaceholder: String { L10n.tr("Localizable", "polls.creation.add-an-option-placeholder") }
      /// This is already an option
      internal static var alreadyAnOptionError: String { L10n.tr("Localizable", "polls.creation.already-an-option-error") }
      /// Anonymous poll
      internal static var anonymousPoll: String { L10n.tr("Localizable", "polls.creation.anonymous-poll") }
      /// Ask a question
      internal static var askAQuestionPlaceholder: String { L10n.tr("Localizable", "polls.creation.ask-a-question-placeholder") }
      /// Cancel
      internal static var cancel: String { L10n.tr("Localizable", "polls.creation.cancel") }
      /// Type a number from 2 and 10
      internal static var maximumVotesError: String { L10n.tr("Localizable", "polls.creation.maximum-votes-error") }
      /// Maximum votes per person
      internal static var maximumVotesPlaceholder: String { L10n.tr("Localizable", "polls.creation.maximum-votes-placeholder") }
      /// Multiple votes
      internal static var multipleVotes: String { L10n.tr("Localizable", "polls.creation.multiple-votes") }
      /// Options
      internal static var optionsTitle: String { L10n.tr("Localizable", "polls.creation.options-title") }
      /// Question
      internal static var questionTitle: String { L10n.tr("Localizable", "polls.creation.question-title") }
      /// Suggest an option
      internal static var suggestAnOption: String { L10n.tr("Localizable", "polls.creation.suggest-an-option") }
      /// Create Poll
      internal static var title: String { L10n.tr("Localizable", "polls.creation.title") }
    }
    internal enum Subtitle {
      /// Select one
      internal static var selectOne: String { L10n.tr("Localizable", "polls.subtitle.selectOne") }
      /// Select one or more
      internal static var selectOneOrMore: String { L10n.tr("Localizable", "polls.subtitle.selectOneOrMore") }
      /// Select up to %d
      internal static func selectUpTo(_ p1: Int) -> String {
        return L10n.tr("Localizable", "polls.subtitle.selectUpTo", p1)
      }
      /// Vote ended
      internal static var voteEnded: String { L10n.tr("Localizable", "polls.subtitle.voteEnded") }
    }
  }

  internal enum Reaction {
    internal enum Authors {
      /// Plural format key: "%#@reactions@"
      internal static func numberOfReactions(_ p1: Int) -> String {
        return L10n.tr("Localizable", "reaction.authors.number-of-reactions", p1)
      }
    }
  }

  internal enum Recording {
    /// Slide to cancel
    internal static var slideToCancel: String { L10n.tr("Localizable", "recording.slideToCancel") }
    /// Hold to record, release to send
    internal static var tip: String { L10n.tr("Localizable", "recording.tip") }
    internal enum Presentation {
      /// Plural format key: "%#@recording@"
      internal static func name(_ p1: Int) -> String {
        return L10n.tr("Localizable", "recording.presentation.name", p1)
      }
    }
  }

  internal enum ThreadList {
    /// %d new threads
    internal static func newThreads(_ p1: Int) -> String {
      return L10n.tr("Localizable", "threadList.new-threads", p1)
    }
    internal enum Empty {
      /// No threads here yet...
      internal static var description: String { L10n.tr("Localizable", "threadList.empty.description") }
    }
    internal enum Error {
      /// Error loading threads
      internal static var message: String { L10n.tr("Localizable", "threadList.error.message") }
    }
  }

  internal enum ThreadListItem {
    /// replied to: %@
    internal static func repliedTo(_ p1: Any) -> String {
      return L10n.tr("Localizable", "threadListItem.replied-to", String(describing: p1))
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

