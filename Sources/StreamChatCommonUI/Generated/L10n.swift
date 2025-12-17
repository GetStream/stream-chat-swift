// Generated using SwiftGen — https://github.com/SwiftGen/SwiftGen

import Foundation

// MARK: - Strings

public enum L10n {
  /// %d of %d
  public static func currentSelection(_ p1: Int, _ p2: Int) -> String {
    return L10n.tr("Localizable", "current-selection", p1, p2)
  }
  /// You
  public static var you: String { L10n.tr("Localizable", "you") }

  public enum Alert {
    public enum Actions {
      /// Cancel
      public static var cancel: String { L10n.tr("Localizable", "alert.actions.cancel") }
      /// Delete
      public static var delete: String { L10n.tr("Localizable", "alert.actions.delete") }
      /// Flag
      public static var flag: String { L10n.tr("Localizable", "alert.actions.flag") }
      /// Ok
      public static var ok: String { L10n.tr("Localizable", "alert.actions.ok") }
    }
    public enum Poll {
      /// Add a comment.
      public static var addComment: String { L10n.tr("Localizable", "alert.poll.add-comment") }
      /// It was not possible to create the poll.
      public static var createErrorMessage: String { L10n.tr("Localizable", "alert.poll.create-error-message") }
      /// Discard Changes
      public static var discardChanges: String { L10n.tr("Localizable", "alert.poll.discard-changes") }
      /// Are you sure you want to discard your poll?
      public static var discardChangesMessage: String { L10n.tr("Localizable", "alert.poll.discard-changes-message") }
      /// End
      public static var end: String { L10n.tr("Localizable", "alert.poll.end") }
      /// Nobody will be able to vote in this poll anymore.
      public static var endTitle: String { L10n.tr("Localizable", "alert.poll.end-title") }
      /// Something went wrong!
      public static var genericErrorTitle: String { L10n.tr("Localizable", "alert.poll.generic-error-title") }
      /// Keep Editing
      public static var keepEditing: String { L10n.tr("Localizable", "alert.poll.keep-editing") }
      /// Send
      public static var send: String { L10n.tr("Localizable", "alert.poll.send") }
      /// Suggest an option.
      public static var suggestOption: String { L10n.tr("Localizable", "alert.poll.suggest-option") }
      /// Update your comment.
      public static var updateComment: String { L10n.tr("Localizable", "alert.poll.update-comment") }
    }
  }

  public enum Attachment {
    /// The max number of attachments per message is %d.
    public static func maxCountExceeded(_ p1: Int) -> String {
      return L10n.tr("Localizable", "attachment.max-count-exceeded", p1)
    }
    /// Attachment size exceed the limit.
    public static var maxSizeExceeded: String { L10n.tr("Localizable", "attachment.max-size-exceeded") }
  }

  public enum Audio {
    public enum Player {
      /// x%@
      public static func rate(_ p1: Any) -> String {
        return L10n.tr("Localizable", "audio.player.rate", String(describing: p1))
      }
    }
  }

  public enum Channel {
    public enum Item {
      /// Audio
      public static var audio: String { L10n.tr("Localizable", "channel.item.audio") }
      /// No messages
      public static var emptyMessages: String { L10n.tr("Localizable", "channel.item.empty-messages") }
      /// Photo
      public static var photo: String { L10n.tr("Localizable", "channel.item.photo") }
      /// are typing ...
      public static var typingPlural: String { L10n.tr("Localizable", "channel.item.typing-plural") }
      /// is typing ...
      public static var typingSingular: String { L10n.tr("Localizable", "channel.item.typing-singular") }
      /// Video
      public static var video: String { L10n.tr("Localizable", "channel.item.video") }
      public enum Search {
        ///  in %@
        public static func `in`(_ p1: Any) -> String {
          return L10n.tr("Localizable", "channel.item.search.in", String(describing: p1))
        }
      }
    }
    public enum Name {
      /// and
      public static var and: String { L10n.tr("Localizable", "channel.name.and") }
      /// and %@ more
      public static func andXMore(_ p1: Any) -> String {
        return L10n.tr("Localizable", "channel.name.andXMore", String(describing: p1))
      }
      /// NoChannel
      public static var missing: String { L10n.tr("Localizable", "channel.name.missing") }
    }
  }

  public enum ChannelList {
    /// Search
    public static var search: String { L10n.tr("Localizable", "channelList.search") }
    public enum Empty {
      /// Start a chat
      public static var button: String { L10n.tr("Localizable", "channelList.empty.button") }
      /// How about sending your first message to a friend?
      public static var subtitle: String { L10n.tr("Localizable", "channelList.empty.subtitle") }
      /// Let's start chatting!
      public static var title: String { L10n.tr("Localizable", "channelList.empty.title") }
    }
    public enum Error {
      /// Error loading channels
      public static var message: String { L10n.tr("Localizable", "channelList.error.message") }
    }
    public enum Preview {
      public enum Voice {
        /// Voice message
        public static var recording: String { L10n.tr("Localizable", "channelList.preview.voice.recording") }
      }
    }
    public enum Search {
      public enum Empty {
        /// No results for %@
        public static func subtitle(_ p1: Any) -> String {
          return L10n.tr("Localizable", "channelList.search.empty.subtitle", String(describing: p1))
        }
      }
    }
  }

  public enum Composer {
    public enum Checkmark {
      /// Also send in channel
      public static var channelReply: String { L10n.tr("Localizable", "composer.checkmark.channel-reply") }
      /// Also send as direct message
      public static var directMessageReply: String { L10n.tr("Localizable", "composer.checkmark.direct-message-reply") }
    }
    public enum LinksDisabled {
      /// Sending links is not allowed in this conversation.
      public static var subtitle: String { L10n.tr("Localizable", "composer.links-disabled.subtitle") }
      /// Links are disabled
      public static var title: String { L10n.tr("Localizable", "composer.links-disabled.title") }
    }
    public enum Picker {
      /// Camera
      public static var camera: String { L10n.tr("Localizable", "composer.picker.camera") }
      /// Cancel
      public static var cancel: String { L10n.tr("Localizable", "composer.picker.cancel") }
      /// File
      public static var file: String { L10n.tr("Localizable", "composer.picker.file") }
      /// Photo or Video
      public static var media: String { L10n.tr("Localizable", "composer.picker.media") }
      /// Create Poll
      public static var poll: String { L10n.tr("Localizable", "composer.picker.poll") }
      /// Choose attachment type: 
      public static var title: String { L10n.tr("Localizable", "composer.picker.title") }
    }
    public enum Placeholder {
      /// Search GIFs
      public static var giphy: String { L10n.tr("Localizable", "composer.placeholder.giphy") }
      /// Send a message
      public static var message: String { L10n.tr("Localizable", "composer.placeholder.message") }
      /// You can't send messages in this channel
      public static var messageDisabled: String { L10n.tr("Localizable", "composer.placeholder.messageDisabled") }
      /// Slow mode ON
      public static var slowMode: String { L10n.tr("Localizable", "composer.placeholder.slowMode") }
    }
    public enum QuotedMessage {
      /// Giphy
      public static var giphy: String { L10n.tr("Localizable", "composer.quoted-message.giphy") }
      /// Photo
      public static var photo: String { L10n.tr("Localizable", "composer.quoted-message.photo") }
    }
    public enum Suggestions {
      public enum Commands {
        /// Instant Commands
        public static var header: String { L10n.tr("Localizable", "composer.suggestions.commands.header") }
      }
    }
    public enum Title {
      /// Edit Message
      public static var edit: String { L10n.tr("Localizable", "composer.title.edit") }
      /// Reply to Message
      public static var reply: String { L10n.tr("Localizable", "composer.title.reply") }
    }
  }

  public enum Dates {
    /// last seen %d days ago
    public static func timeAgoDaysPlural(_ p1: Int) -> String {
      return L10n.tr("Localizable", "dates.time-ago-days-plural", p1)
    }
    /// last seen one day ago
    public static var timeAgoDaysSingular: String { L10n.tr("Localizable", "dates.time-ago-days-singular") }
    /// last seen %d hours ago
    public static func timeAgoHoursPlural(_ p1: Int) -> String {
      return L10n.tr("Localizable", "dates.time-ago-hours-plural", p1)
    }
    /// last seen one hour ago
    public static var timeAgoHoursSingular: String { L10n.tr("Localizable", "dates.time-ago-hours-singular") }
    /// last seen %d minutes ago
    public static func timeAgoMinutesPlural(_ p1: Int) -> String {
      return L10n.tr("Localizable", "dates.time-ago-minutes-plural", p1)
    }
    /// last seen one minute ago
    public static var timeAgoMinutesSingular: String { L10n.tr("Localizable", "dates.time-ago-minutes-singular") }
    /// last seen %d months ago
    public static func timeAgoMonthsPlural(_ p1: Int) -> String {
      return L10n.tr("Localizable", "dates.time-ago-months-plural", p1)
    }
    /// last seen one month ago
    public static var timeAgoMonthsSingular: String { L10n.tr("Localizable", "dates.time-ago-months-singular") }
    /// last seen %d seconds ago
    public static func timeAgoSecondsPlural(_ p1: Int) -> String {
      return L10n.tr("Localizable", "dates.time-ago-seconds-plural", p1)
    }
    /// last seen just one second ago
    public static var timeAgoSecondsSingular: String { L10n.tr("Localizable", "dates.time-ago-seconds-singular") }
    /// last seen %d weeks ago
    public static func timeAgoWeeksPlural(_ p1: Int) -> String {
      return L10n.tr("Localizable", "dates.time-ago-weeks-plural", p1)
    }
    /// last seen one week ago
    public static var timeAgoWeeksSingular: String { L10n.tr("Localizable", "dates.time-ago-weeks-singular") }
  }

  public enum Message {
    /// Message deleted
    public static var deletedMessagePlaceholder: String { L10n.tr("Localizable", "message.deleted-message-placeholder") }
    /// Edited
    public static var edited: String { L10n.tr("Localizable", "message.edited") }
    /// Only visible to you
    public static var onlyVisibleToYou: String { L10n.tr("Localizable", "message.only-visible-to-you") }
    /// Translated to %@
    public static func translatedTo(_ p1: Any) -> String {
      return L10n.tr("Localizable", "message.translatedTo", String(describing: p1))
    }
    /// Unsupported Attachment
    public static var unsupportedAttachment: String { L10n.tr("Localizable", "message.unsupported-attachment") }
    public enum Actions {
      /// Copy Message
      public static var copy: String { L10n.tr("Localizable", "message.actions.copy") }
      /// Delete Message
      public static var delete: String { L10n.tr("Localizable", "message.actions.delete") }
      /// Edit Message
      public static var edit: String { L10n.tr("Localizable", "message.actions.edit") }
      /// Flag Message
      public static var flag: String { L10n.tr("Localizable", "message.actions.flag") }
      /// Reply
      public static var inlineReply: String { L10n.tr("Localizable", "message.actions.inline-reply") }
      /// Mark as unread
      public static var markUnread: String { L10n.tr("Localizable", "message.actions.mark-unread") }
      /// Resend
      public static var resend: String { L10n.tr("Localizable", "message.actions.resend") }
      /// Thread Reply
      public static var threadReply: String { L10n.tr("Localizable", "message.actions.thread-reply") }
      /// Block User
      public static var userBlock: String { L10n.tr("Localizable", "message.actions.user-block") }
      /// Mute User
      public static var userMute: String { L10n.tr("Localizable", "message.actions.user-mute") }
      /// Unblock User
      public static var userUnblock: String { L10n.tr("Localizable", "message.actions.user-unblock") }
      /// Unmute User
      public static var userUnmute: String { L10n.tr("Localizable", "message.actions.user-unmute") }
      public enum Delete {
        /// Are you sure you want to permanently delete this message?
        public static var confirmationMessage: String { L10n.tr("Localizable", "message.actions.delete.confirmation-message") }
        /// Delete Message
        public static var confirmationTitle: String { L10n.tr("Localizable", "message.actions.delete.confirmation-title") }
      }
      public enum Flag {
        /// Do you want to send a copy of this message to a moderator for further investigation?
        public static var confirmationMessage: String { L10n.tr("Localizable", "message.actions.flag.confirmation-message") }
        /// Flag Message
        public static var confirmationTitle: String { L10n.tr("Localizable", "message.actions.flag.confirmation-title") }
      }
    }
    public enum Item {
      /// This message was deleted.
      public static var deleted: String { L10n.tr("Localizable", "message.item.deleted") }
    }
    public enum Moderation {
      /// Delete Message
      public static var delete: String { L10n.tr("Localizable", "message.moderation.delete") }
      /// Edit Message
      public static var edit: String { L10n.tr("Localizable", "message.moderation.edit") }
      /// Consider how your comment might make others feel and be sure to follow our Community Guidelines.
      public static var message: String { L10n.tr("Localizable", "message.moderation.message") }
      /// Send Anyway
      public static var resend: String { L10n.tr("Localizable", "message.moderation.resend") }
      /// Are you sure?
      public static var title: String { L10n.tr("Localizable", "message.moderation.title") }
    }
    public enum Preview {
      /// Draft
      public static var draft: String { L10n.tr("Localizable", "message.preview.draft") }
      /// %@ created:
      public static func pollSomeoneCreated(_ p1: Any) -> String {
        return L10n.tr("Localizable", "message.preview.poll-someone-created", String(describing: p1))
      }
      /// %@ voted:
      public static func pollSomeoneVoted(_ p1: Any) -> String {
        return L10n.tr("Localizable", "message.preview.poll-someone-voted", String(describing: p1))
      }
      /// You created:
      public static var pollYouCreated: String { L10n.tr("Localizable", "message.preview.poll-you-created") }
      /// You voted:
      public static var pollYouVoted: String { L10n.tr("Localizable", "message.preview.poll-you-voted") }
    }
    public enum Sending {
      /// UPLOADING FAILED
      public static var attachmentUploadingFailed: String { L10n.tr("Localizable", "message.sending.attachment-uploading-failed") }
    }
    public enum Thread {
      public enum Replies {
        /// Plural format key: "%#@replies@"
        public static func count(_ p1: Int) -> String {
          return L10n.tr("Localizable", "message.thread.replies.count", p1)
        }
      }
    }
    public enum Threads {
      /// Plural format key: "%#@replies@"
      public static func count(_ p1: Int) -> String {
        return L10n.tr("Localizable", "message.threads.count", p1)
      }
      /// Thread Reply
      public static var reply: String { L10n.tr("Localizable", "message.threads.reply") }
      /// with %@
      public static func replyWith(_ p1: Any) -> String {
        return L10n.tr("Localizable", "message.threads.replyWith", String(describing: p1))
      }
    }
    public enum Title {
      /// %d members, %d online
      public static func group(_ p1: Int, _ p2: Int) -> String {
        return L10n.tr("Localizable", "message.title.group", p1, p2)
      }
      /// Offline
      public static var offline: String { L10n.tr("Localizable", "message.title.offline") }
      /// Online
      public static var online: String { L10n.tr("Localizable", "message.title.online") }
    }
    public enum Unread {
      /// Plural format key: "%#@unread@"
      public static func count(_ p1: Int) -> String {
        return L10n.tr("Localizable", "message.unread.count", p1)
      }
    }
  }

  public enum MessageList {
    /// Plural format key: "%#@unreads@"
    public static func jumpToUnreadButton(_ p1: Int) -> String {
      return L10n.tr("Localizable", "messageList.jump-to-unread-button", p1)
    }
    public enum TypingIndicator {
      /// Someone is typing
      public static var typingUnknown: String { L10n.tr("Localizable", "messageList.typingIndicator.typing-unknown") }
      /// Plural format key: "%1$@%2$#@typing@"
      public static func users(_ p1: Any, _ p2: Int) -> String {
        return L10n.tr("Localizable", "messageList.typingIndicator.users", String(describing: p1), p2)
      }
    }
  }

  public enum Polls {
    /// Add a Comment
    public static var addComment: String { L10n.tr("Localizable", "polls.add-comment") }
    /// Poll Options
    public static var allOptionsTitle: String { L10n.tr("Localizable", "polls.all-options-title") }
    /// Anonymous
    public static var anonymousAuthor: String { L10n.tr("Localizable", "polls.anonymous-author") }
    /// Poll Comments
    public static var commentsTitle: String { L10n.tr("Localizable", "polls.comments-title") }
    /// Poll Results
    public static var resultsTitle: String { L10n.tr("Localizable", "polls.results-title") }
    /// Update your Comment
    public static var updateComment: String { L10n.tr("Localizable", "polls.update-comment") }
    /// %d votes
    public static func votes(_ p1: Int) -> String {
      return L10n.tr("Localizable", "polls.votes", p1)
    }
    public enum Button {
      /// Add Comment
      public static var addComment: String { L10n.tr("Localizable", "polls.button.add-comment") }
      /// See %d More Options
      public static func allOptions(_ p1: Int) -> String {
        return L10n.tr("Localizable", "polls.button.all-options", p1)
      }
      /// End Vote
      public static var endVote: String { L10n.tr("Localizable", "polls.button.endVote") }
      /// Show all
      public static var showAll: String { L10n.tr("Localizable", "polls.button.show-all") }
      /// Suggest an Option
      public static var suggestOption: String { L10n.tr("Localizable", "polls.button.suggest-option") }
      /// View %d Comments
      public static func viewComments(_ p1: Int) -> String {
        return L10n.tr("Localizable", "polls.button.view-comments", p1)
      }
      /// View Results
      public static var viewResults: String { L10n.tr("Localizable", "polls.button.viewResults") }
    }
    public enum Creation {
      /// Add a comment
      public static var addAComment: String { L10n.tr("Localizable", "polls.creation.add-a-comment") }
      /// Add an option
      public static var addAnOptionPlaceholder: String { L10n.tr("Localizable", "polls.creation.add-an-option-placeholder") }
      /// This is already an option
      public static var alreadyAnOptionError: String { L10n.tr("Localizable", "polls.creation.already-an-option-error") }
      /// Anonymous poll
      public static var anonymousPoll: String { L10n.tr("Localizable", "polls.creation.anonymous-poll") }
      /// Ask a question
      public static var askAQuestionPlaceholder: String { L10n.tr("Localizable", "polls.creation.ask-a-question-placeholder") }
      /// Cancel
      public static var cancel: String { L10n.tr("Localizable", "polls.creation.cancel") }
      /// Type a number from 2 and 10
      public static var maximumVotesError: String { L10n.tr("Localizable", "polls.creation.maximum-votes-error") }
      /// Maximum votes per person
      public static var maximumVotesPlaceholder: String { L10n.tr("Localizable", "polls.creation.maximum-votes-placeholder") }
      /// Multiple votes
      public static var multipleVotes: String { L10n.tr("Localizable", "polls.creation.multiple-votes") }
      /// Options
      public static var optionsTitle: String { L10n.tr("Localizable", "polls.creation.options-title") }
      /// Question
      public static var questionTitle: String { L10n.tr("Localizable", "polls.creation.question-title") }
      /// Suggest an option
      public static var suggestAnOption: String { L10n.tr("Localizable", "polls.creation.suggest-an-option") }
      /// Create Poll
      public static var title: String { L10n.tr("Localizable", "polls.creation.title") }
    }
    public enum Subtitle {
      /// Select one
      public static var selectOne: String { L10n.tr("Localizable", "polls.subtitle.selectOne") }
      /// Select one or more
      public static var selectOneOrMore: String { L10n.tr("Localizable", "polls.subtitle.selectOneOrMore") }
      /// Select up to %d
      public static func selectUpTo(_ p1: Int) -> String {
        return L10n.tr("Localizable", "polls.subtitle.selectUpTo", p1)
      }
      /// Vote ended
      public static var voteEnded: String { L10n.tr("Localizable", "polls.subtitle.voteEnded") }
    }
  }

  public enum Reaction {
    public enum Authors {
      /// Plural format key: "%#@reactions@"
      public static func numberOfReactions(_ p1: Int) -> String {
        return L10n.tr("Localizable", "reaction.authors.number-of-reactions", p1)
      }
    }
  }

  public enum Recording {
    /// Slide to cancel
    public static var slideToCancel: String { L10n.tr("Localizable", "recording.slideToCancel") }
    /// Hold to record, release to send
    public static var tip: String { L10n.tr("Localizable", "recording.tip") }
    public enum Presentation {
      /// Plural format key: "%#@recording@"
      public static func name(_ p1: Int) -> String {
        return L10n.tr("Localizable", "recording.presentation.name", p1)
      }
    }
  }

  public enum ThreadList {
    /// %d new threads
    public static func newThreads(_ p1: Int) -> String {
      return L10n.tr("Localizable", "threadList.new-threads", p1)
    }
    public enum Empty {
      /// No threads here yet...
      public static var description: String { L10n.tr("Localizable", "threadList.empty.description") }
    }
    public enum Error {
      /// Error loading threads
      public static var message: String { L10n.tr("Localizable", "threadList.error.message") }
    }
  }

  public enum ThreadListItem {
    /// replied to: %@
    public static func repliedTo(_ p1: Any) -> String {
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
  static let bundle: Bundle = .streamChatCommonUI
}
