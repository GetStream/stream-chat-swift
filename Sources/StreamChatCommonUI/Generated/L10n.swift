// Generated using SwiftGen — https://github.com/SwiftGen/SwiftGen

import Foundation
import StreamCore


// MARK: - Strings

public enum L10n {
  /// %d of %d
  public static func currentSelection(_ p1: Int, _ p2: Int) -> String {
    return L10n.tr("Localizable", "current-selection", p1, p2)
  }

  public enum Alert {
    public enum Actions {
      /// Archive Channel
      public static var archiveChannel: String { L10n.tr("Localizable", "alert.actions.archive-channel") }
      /// Archive Conversation
      public static var archiveConversation: String { L10n.tr("Localizable", "alert.actions.archive-conversation") }
      /// Block User
      public static var blockUser: String { L10n.tr("Localizable", "alert.actions.block-user") }
      /// Cancel
      public static var cancel: String { L10n.tr("Localizable", "alert.actions.cancel") }
      /// Delete
      public static var delete: String { L10n.tr("Localizable", "alert.actions.delete") }
      /// Are you sure you want to delete this conversation?
      public static var deleteChannelMessage: String { L10n.tr("Localizable", "alert.actions.delete-channel-message") }
      /// Delete conversation
      public static var deleteChannelTitle: String { L10n.tr("Localizable", "alert.actions.delete-channel-title") }
      /// Discard Changes
      public static var discardChanges: String { L10n.tr("Localizable", "alert.actions.discard-changes") }
      /// End Poll
      public static var endPoll: String { L10n.tr("Localizable", "alert.actions.endPoll") }
      /// Flag
      public static var flag: String { L10n.tr("Localizable", "alert.actions.flag") }
      /// Keep Editing
      public static var keepEditing: String { L10n.tr("Localizable", "alert.actions.keep-editing") }
      /// Leave Conversation
      public static var leaveConversation: String { L10n.tr("Localizable", "alert.actions.leave-conversation") }
      /// Leave
      public static var leaveGroupButton: String { L10n.tr("Localizable", "alert.actions.leave-group-button") }
      /// Are you sure you want to leave this group?
      public static var leaveGroupMessage: String { L10n.tr("Localizable", "alert.actions.leave-group-message") }
      /// Leave group
      public static var leaveGroupTitle: String { L10n.tr("Localizable", "alert.actions.leave-group-title") }
      /// Mute Channel
      public static var muteChannel: String { L10n.tr("Localizable", "alert.actions.mute-channel") }
      /// Are you sure you want to mute this
      public static var muteChannelTitle: String { L10n.tr("Localizable", "alert.actions.mute-channel-title") }
      /// Mute User
      public static var muteUser: String { L10n.tr("Localizable", "alert.actions.mute-user") }
      /// OK
      public static var ok: String { L10n.tr("Localizable", "alert.actions.ok") }
      /// Send
      public static var send: String { L10n.tr("Localizable", "alert.actions.send") }
      /// Unarchive Channel
      public static var unarchiveChannel: String { L10n.tr("Localizable", "alert.actions.unarchive-channel") }
      /// Unarchive Conversation
      public static var unarchiveConversation: String { L10n.tr("Localizable", "alert.actions.unarchive-conversation") }
      /// Unblock User
      public static var unblockUser: String { L10n.tr("Localizable", "alert.actions.unblock-user") }
      /// Unmute Channel
      public static var unmuteChannel: String { L10n.tr("Localizable", "alert.actions.unmute-channel") }
      /// Are you sure you want to unmute this
      public static var unmuteChannelTitle: String { L10n.tr("Localizable", "alert.actions.unmute-channel-title") }
      /// Unmute User
      public static var unmuteUser: String { L10n.tr("Localizable", "alert.actions.unmute-user") }
      /// Update
      public static var update: String { L10n.tr("Localizable", "alert.actions.update") }
      /// View info
      public static var viewInfoTitle: String { L10n.tr("Localizable", "alert.actions.view-info-title") }
    }
    public enum Error {
      /// The operation couldn't be completed.
      public static var message: String { L10n.tr("Localizable", "alert.error.message") }
      /// Something went wrong.
      public static var title: String { L10n.tr("Localizable", "alert.error.title") }
    }
    public enum Message {
      /// Do you want to end this poll now? Nobody will be able to vote in this poll anymore.
      public static var endPoll: String { L10n.tr("Localizable", "alert.message.end-poll") }
    }
    public enum Poll {
      /// It was not possible to create the poll.
      public static var createErrorMessage: String { L10n.tr("Localizable", "alert.poll.create-error-message") }
    }
    public enum TextField {
      /// Your comment
      public static var pollAddComment: String { L10n.tr("Localizable", "alert.text-field.poll-add-comment") }
      /// Enter a new option
      public static var pollsNewOption: String { L10n.tr("Localizable", "alert.text-field.polls-new-option") }
    }
    public enum Title {
      /// Add a Comment
      public static var addComment: String { L10n.tr("Localizable", "alert.title.add-comment") }
      /// End this poll?
      public static var endPoll: String { L10n.tr("Localizable", "alert.title.end-poll") }
      /// Suggest an option
      public static var suggestAnOption: String { L10n.tr("Localizable", "alert.title.suggest-an-option") }
    }
  }

  public enum Attachment {
    /// The max number of attachments per message is %d.
    public static func maxCountExceeded(_ p1: Int) -> String {
      return L10n.tr("Localizable", "attachment.max-count-exceeded", p1)
    }
    /// Attachment size exceed the limit.
    public static var maxSizeExceeded: String { L10n.tr("Localizable", "attachment.max-size-exceeded") }
    public enum MaxSize {
      /// Please select a smaller attachment.
      public static var message: String { L10n.tr("Localizable", "attachment.max-size.message") }
      /// Attachment size exceed the limit
      public static var title: String { L10n.tr("Localizable", "attachment.max-size.title") }
    }
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
    public enum Header {
      public enum Info {
        /// Channel info
        public static var title: String { L10n.tr("Localizable", "channel.header.info.title") }
      }
    }
    public enum Item {
      /// Audio
      public static var audio: String { L10n.tr("Localizable", "channel.item.audio") }
      /// No messages yet
      public static var emptyMessages: String { L10n.tr("Localizable", "channel.item.empty-messages") }
      /// Giphy
      public static var giphy: String { L10n.tr("Localizable", "channel.item.giphy") }
      /// Message failed to send
      public static var messageFailedToSend: String { L10n.tr("Localizable", "channel.item.message-failed-to-send") }
      /// Mute
      public static var mute: String { L10n.tr("Localizable", "channel.item.mute") }
      /// Channel is muted
      public static var muted: String { L10n.tr("Localizable", "channel.item.muted") }
      /// Photo
      public static var photo: String { L10n.tr("Localizable", "channel.item.photo") }
      /// Poll
      public static var poll: String { L10n.tr("Localizable", "channel.item.poll") }
      /// %@ created:
      public static func pollSomeoneCreated(_ p1: Any) -> String {
        return L10n.tr("Localizable", "channel.item.poll-someone-created", String(describing: p1))
      }
      /// %@ voted:
      public static func pollSomeoneVoted(_ p1: Any) -> String {
        return L10n.tr("Localizable", "channel.item.poll-someone-voted", String(describing: p1))
      }
      /// You created:
      public static var pollYouCreated: String { L10n.tr("Localizable", "channel.item.poll-you-created") }
      /// You voted:
      public static var pollYouVoted: String { L10n.tr("Localizable", "channel.item.poll-you-voted") }
      /// Remove User
      public static var removeUser: String { L10n.tr("Localizable", "channel.item.remove-user") }
      /// Are you sure you want to remove %@ from %@?
      public static func removeUserConfirmationMessage(_ p1: Any, _ p2: Any) -> String {
        return L10n.tr("Localizable", "channel.item.remove-user-confirmation-message", String(describing: p1), String(describing: p2))
      }
      /// Remove User
      public static var removeUserConfirmationTitle: String { L10n.tr("Localizable", "channel.item.remove-user-confirmation-title") }
      /// Send Direct Message
      public static var sendDirectMessage: String { L10n.tr("Localizable", "channel.item.send-direct-message") }
      /// Typing
      public static var typing: String { L10n.tr("Localizable", "channel.item.typing") }
      /// are typing ...
      public static var typingPlural: String { L10n.tr("Localizable", "channel.item.typing-plural") }
      /// is typing ...
      public static var typingSingular: String { L10n.tr("Localizable", "channel.item.typing-singular") }
      /// Unmute
      public static var unmute: String { L10n.tr("Localizable", "channel.item.unmute") }
      /// Video
      public static var video: String { L10n.tr("Localizable", "channel.item.video") }
      /// Voice Message
      public static var voiceMessage: String { L10n.tr("Localizable", "channel.item.voice-message") }
      /// You
      public static var you: String { L10n.tr("Localizable", "channel.item.you") }
      public enum Search {
        ///  in %@
        public static func `in`(_ p1: Any) -> String {
          return L10n.tr("Localizable", "channel.item.search.in", String(describing: p1))
        }
      }
    }
    public enum List {
      public enum ScrollToBottom {
        /// Scroll to bottom
        public static var title: String { L10n.tr("Localizable", "channel.list.scroll-to-bottom.title") }
      }
    }
    public enum Name {
      /// and
      public static var and: String { L10n.tr("Localizable", "channel.name.and") }
      /// and %@ more
      public static func andXMore(_ p1: Any) -> String {
        return L10n.tr("Localizable", "channel.name.andXMore", String(describing: p1))
      }
      /// user
      public static var directMessage: String { L10n.tr("Localizable", "channel.name.direct-message") }
      /// group
      public static var group: String { L10n.tr("Localizable", "channel.name.group") }
      /// NoChannel
      public static var missing: String { L10n.tr("Localizable", "channel.name.missing") }
    }
    public enum NoContent {
      /// How about sending your first message to a friend?
      public static var message: String { L10n.tr("Localizable", "channel.no-content.message") }
      /// Start a chat
      public static var start: String { L10n.tr("Localizable", "channel.no-content.start") }
      /// Let's start chatting
      public static var title: String { L10n.tr("Localizable", "channel.no-content.title") }
    }
  }

  public enum ChannelList {
    /// Search
    public static var search: String { L10n.tr("Localizable", "channelList.search") }
    public enum Error {
      /// Error loading channels
      public static var message: String { L10n.tr("Localizable", "channelList.error.message") }
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

  public enum ChatInfo {
    /// Edit
    public static var edit: String { L10n.tr("Localizable", "chat-info.edit") }
    public enum Contact {
      /// Contact Info
      public static var title: String { L10n.tr("Localizable", "chat-info.contact.title") }
    }
    public enum Edit {
      /// Group name
      public static var groupName: String { L10n.tr("Localizable", "chat-info.edit.group-name") }
      /// Save
      public static var save: String { L10n.tr("Localizable", "chat-info.edit.save") }
      /// Upload
      public static var upload: String { L10n.tr("Localizable", "chat-info.edit.upload") }
      public enum Picture {
        /// Take Photo
        public static var camera: String { L10n.tr("Localizable", "chat-info.edit.picture.camera") }
        /// Choose Image
        public static var library: String { L10n.tr("Localizable", "chat-info.edit.picture.library") }
        /// Reset Picture
        public static var reset: String { L10n.tr("Localizable", "chat-info.edit.picture.reset") }
        /// Edit Group Picture
        public static var title: String { L10n.tr("Localizable", "chat-info.edit.picture.title") }
      }
    }
    public enum Files {
      /// Files sent in this chat will appear here.
      public static var emptyDesc: String { L10n.tr("Localizable", "chat-info.files.empty-desc") }
      /// No files
      public static var emptyTitle: String { L10n.tr("Localizable", "chat-info.files.empty-title") }
      /// Files
      public static var title: String { L10n.tr("Localizable", "chat-info.files.title") }
    }
    public enum Group {
      /// Group Info
      public static var title: String { L10n.tr("Localizable", "chat-info.group.title") }
    }
    public enum Media {
      /// Photos or videos sent in this chat will appear here.
      public static var emptyDesc: String { L10n.tr("Localizable", "chat-info.media.empty-desc") }
      /// No media
      public static var emptyTitle: String { L10n.tr("Localizable", "chat-info.media.empty-title") }
      /// Photos & Videos
      public static var title: String { L10n.tr("Localizable", "chat-info.media.title") }
    }
    public enum Member {
      /// Admin
      public static var admin: String { L10n.tr("Localizable", "chat-info.member.admin") }
    }
    public enum Members {
      /// Add
      public static var add: String { L10n.tr("Localizable", "chat-info.members.add") }
      /// Add Members
      public static var addMembersTitle: String { L10n.tr("Localizable", "chat-info.members.add-members-title") }
      /// Already a member
      public static var alreadyMember: String { L10n.tr("Localizable", "chat-info.members.already-member") }
      /// Plural format key: "%#@members@"
      public static func count(_ p1: Int) -> String {
        return L10n.tr("Localizable", "chat-info.members.count", p1)
      }
      /// Members
      public static var title: String { L10n.tr("Localizable", "chat-info.members.title") }
    }
    public enum Mute {
      /// Mute Group
      public static var group: String { L10n.tr("Localizable", "chat-info.mute.group") }
      /// Mute User
      public static var user: String { L10n.tr("Localizable", "chat-info.mute.user") }
    }
    public enum PinnedMessages {
      /// Long-press an important message and choose Pin to conversation.
      public static var emptyDesc: String { L10n.tr("Localizable", "chat-info.pinned-messages.empty-desc") }
      /// No pinned messages
      public static var emptyTitle: String { L10n.tr("Localizable", "chat-info.pinned-messages.empty-title") }
      /// Pinned Messages
      public static var title: String { L10n.tr("Localizable", "chat-info.pinned-messages.title") }
    }
    public enum Rename {
      /// NAME
      public static var name: String { L10n.tr("Localizable", "chat-info.rename.name") }
      /// Add a group name
      public static var placeholder: String { L10n.tr("Localizable", "chat-info.rename.placeholder") }
    }
    public enum Users {
      /// %@ more
      public static func loadMore(_ p1: Any) -> String {
        return L10n.tr("Localizable", "chat-info.users.loadMore", String(describing: p1))
      }
      /// View all
      public static var viewAll: String { L10n.tr("Localizable", "chat-info.users.view-all") }
    }
  }

  public enum Composer {
    public enum AudioRecording {
      /// Start recording audio message
      public static var start: String { L10n.tr("Localizable", "composer.audio-recording.start") }
      /// Stop recording audio message
      public static var stop: String { L10n.tr("Localizable", "composer.audio-recording.stop") }
    }
    public enum Camera {
      /// Change in Settings
      public static var accessSettings: String { L10n.tr("Localizable", "composer.camera.access-settings") }
      /// You have not granted access to your camera
      public static var noAccess: String { L10n.tr("Localizable", "composer.camera.no-access") }
      /// Open Camera
      public static var openCamera: String { L10n.tr("Localizable", "composer.camera.open-camera") }
      /// Take a photo and share
      public static var takePhoto: String { L10n.tr("Localizable", "composer.camera.take-photo") }
    }
    public enum Checkmark {
      /// Also send in channel
      public static var channelReply: String { L10n.tr("Localizable", "composer.checkmark.channel-reply") }
      /// Also send as direct message
      public static var directMessageReply: String { L10n.tr("Localizable", "composer.checkmark.direct-message-reply") }
    }
    public enum Commands {
      /// Giphy
      public static var giphy: String { L10n.tr("Localizable", "composer.commands.giphy") }
      /// Mute
      public static var mute: String { L10n.tr("Localizable", "composer.commands.mute") }
      /// Unmute
      public static var unmute: String { L10n.tr("Localizable", "composer.commands.unmute") }
      public enum Format {
        /// text
        public static var text: String { L10n.tr("Localizable", "composer.commands.format.text") }
        /// @username
        public static var username: String { L10n.tr("Localizable", "composer.commands.format.username") }
      }
      public enum Giphy {
        /// Post a random gif to the channel
        public static var description: String { L10n.tr("Localizable", "composer.commands.giphy.description") }
      }
      public enum Mute {
        /// Muted %@
        public static func confirmation(_ p1: Any) -> String {
          return L10n.tr("Localizable", "composer.commands.mute.confirmation", String(describing: p1))
        }
        /// Mute a user
        public static var description: String { L10n.tr("Localizable", "composer.commands.mute.description") }
      }
      public enum Unmute {
        /// Unmuted %@
        public static func confirmation(_ p1: Any) -> String {
          return L10n.tr("Localizable", "composer.commands.unmute.confirmation", String(describing: p1))
        }
        /// Unmute a user
        public static var description: String { L10n.tr("Localizable", "composer.commands.unmute.description") }
      }
    }
    public enum Files {
      /// Add more files
      public static var addMore: String { L10n.tr("Localizable", "composer.files.add-more") }
      /// Open Files
      public static var openFiles: String { L10n.tr("Localizable", "composer.files.open-files") }
      /// Select files to share
      public static var selectFiles: String { L10n.tr("Localizable", "composer.files.select-files") }
    }
    public enum Images {
      /// Change in Settings
      public static var accessSettings: String { L10n.tr("Localizable", "composer.images.access-settings") }
      /// You have not granted access to the photo library.
      public static var noAccessLibrary: String { L10n.tr("Localizable", "composer.images.no-access-library") }
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
      /// Attachment pickers
      public static var showAll: String { L10n.tr("Localizable", "composer.picker.show-all") }
      /// Choose attachment type: 
      public static var title: String { L10n.tr("Localizable", "composer.picker.title") }
    }
    public enum Placeholder {
      /// Search GIFs
      public static var giphy: String { L10n.tr("Localizable", "composer.placeholder.giphy") }
      /// Message
      public static var message: String { L10n.tr("Localizable", "composer.placeholder.message") }
      /// You can't send messages in this channel
      public static var messageDisabled: String { L10n.tr("Localizable", "composer.placeholder.messageDisabled") }
      /// Slow mode, wait %ds...
      public static func slowMode(_ p1: Int) -> String {
        return L10n.tr("Localizable", "composer.placeholder.slow-mode", p1)
      }
    }
    public enum Polls {
      /// Are you sure you want to discard your poll?
      public static var actionSheetDiscardTitle: String { L10n.tr("Localizable", "composer.polls.action-sheet-discard-title") }
      /// Add a comment
      public static var addComment: String { L10n.tr("Localizable", "composer.polls.add-comment") }
      /// Add an option
      public static var addOption: String { L10n.tr("Localizable", "composer.polls.add-option") }
      /// Allow others to add comments
      public static var allowOthersToAddComments: String { L10n.tr("Localizable", "composer.polls.allow-others-to-add-comments") }
      /// Anonymous poll
      public static var anonymousPoll: String { L10n.tr("Localizable", "composer.polls.anonymous-poll") }
      /// Ask a question
      public static var askQuestion: String { L10n.tr("Localizable", "composer.polls.askQuestion") }
      /// Create Poll
      public static var createPoll: String { L10n.tr("Localizable", "composer.polls.create-poll") }
      /// Create a poll and share
      public static var createPollDescription: String { L10n.tr("Localizable", "composer.polls.create-poll-description") }
      /// Option already exists
      public static var duplicateOption: String { L10n.tr("Localizable", "composer.polls.duplicate-option") }
      /// Hide who voted
      public static var hideWhoVoted: String { L10n.tr("Localizable", "composer.polls.hide-who-voted") }
      /// Let others add options
      public static var letOthersAddOptions: String { L10n.tr("Localizable", "composer.polls.let-others-add-options") }
      /// Limit votes per person
      public static var maximumVotesPerPerson: String { L10n.tr("Localizable", "composer.polls.maximum-votes-per-person") }
      /// Multiple votes
      public static var multipleAnswers: String { L10n.tr("Localizable", "composer.polls.multiple-answers") }
      /// Options
      public static var options: String { L10n.tr("Localizable", "composer.polls.options") }
      /// Question
      public static var question: String { L10n.tr("Localizable", "composer.polls.question") }
      /// Select more than one option
      public static var selectMoreThanOneOption: String { L10n.tr("Localizable", "composer.polls.select-more-than-one-option") }
      /// Suggest an option
      public static var suggestOption: String { L10n.tr("Localizable", "composer.polls.suggest-option") }
      /// Choose between 2–10 options
      public static var typeNumberMinMaxRange: String { L10n.tr("Localizable", "composer.polls.type-number-min-max-range") }
    }
    public enum Quoted {
      /// Audio
      public static var audio: String { L10n.tr("Localizable", "composer.quoted.audio") }
      /// Dismiss quote
      public static var dismiss: String { L10n.tr("Localizable", "composer.quoted.dismiss") }
      /// File
      public static var file: String { L10n.tr("Localizable", "composer.quoted.file") }
      /// %d files
      public static func files(_ p1: Int) -> String {
        return L10n.tr("Localizable", "composer.quoted.files", p1)
      }
      /// Giphy
      public static var giphy: String { L10n.tr("Localizable", "composer.quoted.giphy") }
      /// Photo
      public static var photo: String { L10n.tr("Localizable", "composer.quoted.photo") }
      /// %d photos
      public static func photos(_ p1: Int) -> String {
        return L10n.tr("Localizable", "composer.quoted.photos", p1)
      }
      /// Reply to %@
      public static func replyTo(_ p1: Any) -> String {
        return L10n.tr("Localizable", "composer.quoted.replyTo", String(describing: p1))
      }
      /// Video
      public static var video: String { L10n.tr("Localizable", "composer.quoted.video") }
      /// %d videos
      public static func videos(_ p1: Int) -> String {
        return L10n.tr("Localizable", "composer.quoted.videos", p1)
      }
      /// Voice message
      public static var voiceMessage: String { L10n.tr("Localizable", "composer.quoted.voiceMessage") }
      /// Voice message (%@)
      public static func voiceMessageWithDuration(_ p1: Any) -> String {
        return L10n.tr("Localizable", "composer.quoted.voiceMessageWithDuration", String(describing: p1))
      }
    }
    public enum Recording {
      /// Recording stopped
      public static var recordingStopped: String { L10n.tr("Localizable", "composer.recording.recordingStopped") }
      /// Slide to cancel
      public static var slideToCancel: String { L10n.tr("Localizable", "composer.recording.slide-to-cancel") }
      /// Hold to record. Release to send.
      public static var tip: String { L10n.tr("Localizable", "composer.recording.tip") }
      /// Hold to record. Release to save.
      public static var tipSave: String { L10n.tr("Localizable", "composer.recording.tipSave") }
      /// Voice message deleted
      public static var voiceMessageDeleted: String { L10n.tr("Localizable", "composer.recording.voiceMessageDeleted") }
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
    /// Today
    public static var today: String { L10n.tr("Localizable", "dates.today") }
  }

  public enum Message {
    /// Message deleted
    public static var deletedMessagePlaceholder: String { L10n.tr("Localizable", "message.deleted-message-placeholder") }
    /// Only visible to you
    public static var onlyVisibleToYou: String { L10n.tr("Localizable", "message.only-visible-to-you") }
    /// Show Original
    public static var showOriginal: String { L10n.tr("Localizable", "message.showOriginal") }
    /// Show Translation
    public static var showTranslation: String { L10n.tr("Localizable", "message.showTranslation") }
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
      /// Mark Unread
      public static var markUnread: String { L10n.tr("Localizable", "message.actions.mark-unread") }
      /// Pin to conversation
      public static var pin: String { L10n.tr("Localizable", "message.actions.pin") }
      /// Resend
      public static var resend: String { L10n.tr("Localizable", "message.actions.resend") }
      /// Thread Reply
      public static var threadReply: String { L10n.tr("Localizable", "message.actions.thread-reply") }
      /// Unpin from conversation
      public static var unpin: String { L10n.tr("Localizable", "message.actions.unpin") }
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
      public enum UserBlock {
        /// Are you sure you want to block this user?
        public static var confirmationMessage: String { L10n.tr("Localizable", "message.actions.user-block.confirmation-message") }
      }
      public enum UserUnblock {
        /// Are you sure you want to unblock this user?
        public static var confirmationMessage: String { L10n.tr("Localizable", "message.actions.user-unblock.confirmation-message") }
      }
    }
    public enum Annotation {
      /// Reminder set
      public static var reminderSet: String { L10n.tr("Localizable", "message.annotation.reminderSet") }
      /// Replied to a thread
      public static var repliedToThread: String { L10n.tr("Localizable", "message.annotation.repliedToThread") }
      /// Also sent in channel
      public static var sentInChannel: String { L10n.tr("Localizable", "message.annotation.sentInChannel") }
      /// Translated
      public static var translated: String { L10n.tr("Localizable", "message.annotation.translated") }
      /// View
      public static var view: String { L10n.tr("Localizable", "message.annotation.view") }
    }
    public enum Attachment {
      /// Attachment %d
      public static func accessibilityLabel(_ p1: Int) -> String {
        return L10n.tr("Localizable", "message.attachment.accessibility-label", p1)
      }
    }
    public enum Bounce {
      /// Message was bounced
      public static var title: String { L10n.tr("Localizable", "message.bounce.title") }
    }
    public enum Cell {
      /// Edited
      public static var edited: String { L10n.tr("Localizable", "message.cell.edited") }
      /// Pinned by
      public static var pinnedBy: String { L10n.tr("Localizable", "message.cell.pinnedBy") }
      /// Pinned by you
      public static var pinnedByYou: String { L10n.tr("Localizable", "message.cell.pinnedByYou") }
      /// Sent at %@
      public static func sentAt(_ p1: Any) -> String {
        return L10n.tr("Localizable", "message.cell.sent-at", String(describing: p1))
      }
      /// unknown
      public static var unknownPin: String { L10n.tr("Localizable", "message.cell.unknownPin") }
    }
    public enum FileAttachment {
      /// Error occured while previewing the file.
      public static var errorPreview: String { L10n.tr("Localizable", "message.file-attachment.error-preview") }
    }
    public enum Gallery {
      /// %d of %d
      public static func pageCount(_ p1: Int, _ p2: Int) -> String {
        return L10n.tr("Localizable", "message.gallery.pageCount", p1, p2)
      }
      /// Photos
      public static var photos: String { L10n.tr("Localizable", "message.gallery.photos") }
    }
    public enum GiphyAttachment {
      /// GIPHY
      public static var title: String { L10n.tr("Localizable", "message.giphy-attachment.title") }
    }
    public enum Item {
      /// This message was deleted.
      public static var deleted: String { L10n.tr("Localizable", "message.item.deleted") }
    }
    public enum Moderation {
      public enum Alert {
        /// Cancel
        public static var cancel: String { L10n.tr("Localizable", "message.moderation.alert.cancel") }
        /// Delete Message
        public static var delete: String { L10n.tr("Localizable", "message.moderation.alert.delete") }
        /// Edit Message
        public static var edit: String { L10n.tr("Localizable", "message.moderation.alert.edit") }
        /// Consider how your comment might make others feel and be sure to follow our Community Guidelines.
        public static var message: String { L10n.tr("Localizable", "message.moderation.alert.message") }
        /// Send Anyway
        public static var resend: String { L10n.tr("Localizable", "message.moderation.alert.resend") }
        /// Are you sure?
        public static var title: String { L10n.tr("Localizable", "message.moderation.alert.title") }
      }
    }
    public enum Polls {
      /// Option %d
      public static func option(_ p1: Int) -> String {
        return L10n.tr("Localizable", "message.polls.option", p1)
      }
      /// Question
      public static var question: String { L10n.tr("Localizable", "message.polls.question") }
      /// Anonymous
      public static var unknownVoteAuthor: String { L10n.tr("Localizable", "message.polls.unknown-vote-author") }
      /// %d vote
      public static func voteSingular(_ p1: Int) -> String {
        return L10n.tr("Localizable", "message.polls.vote-singular", p1)
      }
      /// %d votes
      public static func votes(_ p1: Int) -> String {
        return L10n.tr("Localizable", "message.polls.votes", p1)
      }
      /// %d votes total
      public static func votesTotal(_ p1: Int) -> String {
        return L10n.tr("Localizable", "message.polls.votes-total", p1)
      }
      public enum Button {
        /// Add a Comment
        public static var addComment: String { L10n.tr("Localizable", "message.polls.button.addComment") }
        /// End Poll
        public static var endVote: String { L10n.tr("Localizable", "message.polls.button.endVote") }
        /// See %d More Options
        public static func seeMoreOptions(_ p1: Int) -> String {
          return L10n.tr("Localizable", "message.polls.button.seeMoreOptions", p1)
        }
        /// View all
        public static var showAll: String { L10n.tr("Localizable", "message.polls.button.show-all") }
        /// Suggest an Option
        public static var suggestAnOption: String { L10n.tr("Localizable", "message.polls.button.suggestAnOption") }
        /// Update Your Comment
        public static var updateComment: String { L10n.tr("Localizable", "message.polls.button.updateComment") }
        /// Plural format key: "%#@comments@"
        public static func viewNumberOfComments(_ p1: Int) -> String {
          return L10n.tr("Localizable", "message.polls.button.view-number-of-comments", p1)
        }
        /// View Results
        public static var viewResults: String { L10n.tr("Localizable", "message.polls.button.viewResults") }
      }
      public enum Date {
        /// %@ at %@
        public static func dayAtTime(_ p1: Any, _ p2: Any) -> String {
          return L10n.tr("Localizable", "message.polls.date.day-at-time", String(describing: p1), String(describing: p2))
        }
        /// %dd ago
        public static func daysAgo(_ p1: Int) -> String {
          return L10n.tr("Localizable", "message.polls.date.days-ago", p1)
        }
        /// %dw ago
        public static func weeksAgo(_ p1: Int) -> String {
          return L10n.tr("Localizable", "message.polls.date.weeks-ago", p1)
        }
      }
      public enum Snackbar {
        /// Poll ended
        public static var pollEnded: String { L10n.tr("Localizable", "message.polls.snackbar.poll-ended") }
      }
      public enum Subtitle {
        /// Select one
        public static var selectOne: String { L10n.tr("Localizable", "message.polls.subtitle.selectOne") }
        /// Select one or more
        public static var selectOneOrMore: String { L10n.tr("Localizable", "message.polls.subtitle.selectOneOrMore") }
        /// Select up to %d
        public static func selectUpTo(_ p1: Int) -> String {
          return L10n.tr("Localizable", "message.polls.subtitle.selectUpTo", p1)
        }
        /// Vote ended
        public static var voteEnded: String { L10n.tr("Localizable", "message.polls.subtitle.voteEnded") }
      }
      public enum Toolbar {
        /// Poll Comments
        public static var commentsTitle: String { L10n.tr("Localizable", "message.polls.toolbar.comments-title") }
        /// Poll Options
        public static var optionsTitle: String { L10n.tr("Localizable", "message.polls.toolbar.options-title") }
        /// Poll Results
        public static var resultsTitle: String { L10n.tr("Localizable", "message.polls.toolbar.results-title") }
      }
    }
    public enum Preview {
      /// Draft
      public static var draft: String { L10n.tr("Localizable", "message.preview.draft") }
    }
    public enum Reactions {
      /// You
      public static var currentUser: String { L10n.tr("Localizable", "message.reactions.currentUser") }
      /// Tap to remove
      public static var tapToRemove: String { L10n.tr("Localizable", "message.reactions.tap-to-remove") }
    }
    public enum ReadStatus {
      /// Seen by no one
      public static var seenByNoOne: String { L10n.tr("Localizable", "message.read-status.seen-by-no-one") }
      /// Seen by others
      public static var seenByOthers: String { L10n.tr("Localizable", "message.read-status.seen-by-others") }
    }
    public enum Search {
      /// Cancel
      public static var cancel: String { L10n.tr("Localizable", "message.search.cancel") }
      /// Plural format key: "%#@results@"
      public static func numberOfResults(_ p1: Int) -> String {
        return L10n.tr("Localizable", "message.search.number-of-results", p1)
      }
      /// Search
      public static var title: String { L10n.tr("Localizable", "message.search.title") }
    }
    public enum Sending {
      /// Retry upload
      public static var attachmentRetryUpload: String { L10n.tr("Localizable", "message.sending.attachment-retry-upload") }
      /// Upload failed
      public static var attachmentUploadFailed: String { L10n.tr("Localizable", "message.sending.attachment-upload-failed") }
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
      /// Thread Replies
      public static var replies: String { L10n.tr("Localizable", "message.threads.replies") }
      /// Thread Reply
      public static var reply: String { L10n.tr("Localizable", "message.threads.reply") }
      /// with %@
      public static func replyWith(_ p1: Any) -> String {
        return L10n.tr("Localizable", "message.threads.replyWith", String(describing: p1))
      }
      /// with messages
      public static var subtitle: String { L10n.tr("Localizable", "message.threads.subtitle") }
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
    /// Plural format key: "%#@messages@"
    public static func newMessages(_ p1: Int) -> String {
      return L10n.tr("Localizable", "messageList.newMessages", p1)
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
    /// Anonymous
    public static var anonymousAuthor: String { L10n.tr("Localizable", "polls.anonymous-author") }
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
    public enum Presentation {
      /// Plural format key: "%#@recording@"
      public static func name(_ p1: Int) -> String {
        return L10n.tr("Localizable", "recording.presentation.name", p1)
      }
    }
  }

  public enum Thread {
    /// %d new threads
    public static func newThreads(_ p1: Int) -> String {
      return L10n.tr("Localizable", "thread.new-threads", p1)
    }
    /// Threads
    public static var title: String { L10n.tr("Localizable", "thread.title") }
    public enum Error {
      /// Couldn't load new threads. Tap to retry.
      public static var message: String { L10n.tr("Localizable", "thread.error.message") }
    }
    public enum Item {
      /// replied to: %@
      public static func repliedTo(_ p1: Any) -> String {
        return L10n.tr("Localizable", "thread.item.replied-to", String(describing: p1))
      }
      /// replies
      public static var replies: String { L10n.tr("Localizable", "thread.item.replies") }
      /// reply
      public static var reply: String { L10n.tr("Localizable", "thread.item.reply") }
    }
    public enum NoContent {
      /// No threads here yet...
      public static var message: String { L10n.tr("Localizable", "thread.no-content.message") }
    }
  }
}

// MARK: - Implementation Details

extension L10n {
  private static func tr(_ table: String, _ key: String, _ args: CVarArg...) -> String {
     // TODO: Using using Appearance.default prohibits using Appearance injection
     let format = StreamConcurrency.onMain {
       Appearance.default.localizationProvider(key, table)
     }
     return String(format: format, locale: Locale.current, arguments: args)
  }
}

private final class BundleToken {
  static let bundle: Bundle = .streamChatCommonUI
}

