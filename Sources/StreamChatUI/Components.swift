//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// An object containing types of UI Components that are used through the UI SDK.
public struct Components {
    /// A view that displays a title label and subtitle in a container stack view.
    public var titleContainerView: TitleContainerView.Type = TitleContainerView.self

    /// A view used as an online activity indicator (online/offline).
    public var onlineIndicatorView: (UIView & MaskProviding).Type = OnlineIndicatorView.self

    /// The default avatar thumbnail size.
    public var avatarThumbnailSize: CGSize = .init(width: 40, height: 40)

    /// A view that displays the avatar image. By default a circular image.
    public var avatarView: ChatAvatarView.Type = ChatAvatarView.self

    /// An avatar view with an online indicator.
    public var presenceAvatarView: ChatPresenceAvatarView.Type = ChatPresenceAvatarView.self

    /// A `UIView` subclass which serves as container for `typingIndicator` and `UILabel` describing who is currently typing
    public var typingIndicatorView: TypingIndicatorView.Type = TypingIndicatorView.self

    /// A `UIView` subclass with animated 3 dots for indicating that user is typing.
    public var typingAnimationView: TypingAnimationView.Type = TypingAnimationView.self

    /// A view for inputting text with placeholder support.
    public var inputTextView: InputTextView.Type = InputTextView.self

    /// A view that displays the command name and icon.
    public var commandLabelView: CommandLabelView.Type = CommandLabelView.self

    /// A view to input content of a message.
    public var inputMessageView: InputChatMessageView.Type = InputChatMessageView.self

    /// A view that displays a quoted message.
    public var quotedMessageView: QuotedChatMessageView.Type = QuotedChatMessageView.self

    /// A button used for sending a message, or any type of content.
    public var sendButton: UIButton.Type = SendButton.self

    /// A button used for recording a voice message,
    public var recordButton: RecordButton.Type = RecordButton.self

    /// A view for showing a cooldown when Slow Mode is active.
    public var cooldownView: CooldownView.Type = CooldownView.self

    /// A button for confirming actions.
    public var confirmButton: UIButton.Type = ConfirmButton.self

    /// A button for opening attachments.
    public var attachmentButton: UIButton.Type = AttachmentButton.self

    /// A view used as a fallback preview view for attachments that don't confirm to `AttachmentPreviewProvider`
    public var attachmentPreviewViewPlaceholder: UIView.Type = AttachmentPlaceholderView.self

    /// A button for opening commands.
    public var commandsButton: UIButton.Type = CommandButton.self

    /// A button for shrinking the input view to allow more space for other actions.
    public var shrinkInputButton: UIButton.Type = ShrinkInputButton.self

    /// A button for closing, dismissing or clearing information.
    public var closeButton: UIButton.Type = CloseButton.self

    /// A button for sharing an information.
    public var shareButton: UIButton.Type = ShareButton.self

    /// A view to check/uncheck an option.
    public var checkmarkControl: CheckboxControl.Type = CheckboxControl.self

    /// An object responsible for message layout options calculations in `ChatMessageListVC/ChatThreadVC`.
    public var messageLayoutOptionsResolver: ChatMessageLayoutOptionsResolver = .init()

    /// The view that shows a loading indicator.
    public var loadingIndicator: ChatLoadingIndicator.Type = ChatLoadingIndicator.self

    /// Object with set of function for handling images from CDN
    public var imageCDN: ImageCDN = StreamImageCDN()

    /// Object which is responsible for loading images
    public var imageLoader: ImageLoading = NukeImageLoader()

    /// Object responsible for providing resizing operations for `UIImage`
    public var imageProcessor: ImageProcessor = NukeImageProcessor()

    /// The object responsible for loading video attachments.
    public var videoLoader: VideoLoading = StreamVideoLoader()

    /// The view that shows a gradient.
    public var gradientView: GradientView.Type = GradientView.self

    /// The view that shows a playing video.
    public var playerView: PlayerView.Type = PlayerView.self

    // The view that displays a banner to show the count of messages
    public var messagesCountDecorationView: ChatMessagesCountDecorationView.Type = ChatMessagesCountDecorationView.self

    // MARK: - Message List components

    /// The view controller responsible for rendering a list of messages.
    /// Used in both the Channel and Thread view controllers.
    @available(iOSApplicationExtension, unavailable)
    public var messageListVC: ChatMessageListVC.Type = ChatMessageListVC.self

    /// The controller that handles `ChatMessageListVC <-> ChatMessagePopUp` transition.
    public var messageActionsTransitionController: ChatMessageActionsTransitionController.Type =
        ChatMessageActionsTransitionController.self

    /// The foundation view for the message list view controller.
    public var messageListView: ChatMessageListView.Type = ChatMessageListView.self

    /// A boolean value that determines whether the messages should start at the top
    /// of the list  when there are few messages. By default it is `false`.
    public var shouldMessagesStartAtTheTop: Bool = false

    /// Whether it should animate when opening the channel with a given message around id.
    /// Ex: When opening a channel from a push notification with a given message id.
    public var shouldAnimateJumpToMessageWhenOpeningChannel: Bool = true

    /// Whether it should jump to the unread message when the channel is initially opened.
    /// By default it is disabled.
    public var shouldJumpToUnreadWhenOpeningChannel: Bool = false

    /// The view that shows the date for currently visible messages on top of message list.
    public var messageListScrollOverlayView: ChatMessageListScrollOverlayView.Type =
        ChatMessageListScrollOverlayView.self

    /// The date separator view that groups messages from the same day.
    public var messageListDateSeparatorView: ChatMessageListDateSeparatorView.Type = ChatMessageListDateSeparatorView.self

    /// A boolean value that determines whether the date overlay should be displayed while scrolling.
    public var messageListDateOverlayEnabled = true

    /// A boolean value that determines whether date separators should be shown between each message.
    public var messageListDateSeparatorEnabled = false

    /// A boolean value that determines whether swiping to quote reply is available.
    public var messageSwipeToReplyEnabled = false

    /// A boolean value that determines whether automatic translation is enabled.
    public var messageAutoTranslationEnabled = false

    /// The view controller used to perform message actions.
    public var messageActionsVC: ChatMessageActionsVC.Type = ChatMessageActionsVC.self

    /// The view controller that is presented when long-pressing a message.
    public var messagePopupVC: ChatMessagePopupVC.Type = ChatMessagePopupVC.self

    /// The view controller used for showing the detail of a file message attachment.
    public var filePreviewVC: ChatMessageAttachmentPreviewVC.Type = ChatMessageAttachmentPreviewVC.self

    /// The view controller responsible to render image and video attachments.
    public var galleryVC: GalleryVC.Type = GalleryVC.self

    /// The view used to control the player for currently visible vide attachment.
    public var videoPlaybackControlView: VideoPlaybackControlView.Type =
        VideoPlaybackControlView.self

    /// The view used to display content of the message, i.e. in the channel detail message list.
    public var messageContentView: ChatMessageContentView.Type = ChatMessageContentView.self

    /// The view used to display a bubble around a message.
    public var messageBubbleView: ChatMessageBubbleView.Type = ChatMessageBubbleView.self

    /// The maximum image resolution in pixels when loading image attachments in the Message List.
    ///
    /// By default it is 2MP, 2 Million Pixels. Keep in mind that
    /// increasing this value will increase the memory footprint.
    public var imageAttachmentMaxPixels: Double = 2_000_000

    /// The class responsible for returning the correct attachment view injector from a message
    @available(iOSApplicationExtension, unavailable)
    public var attachmentViewCatalog: AttachmentViewCatalog.Type = AttachmentViewCatalog.self

    /// The injector used to inject gallery attachment views.
    public var galleryAttachmentInjector: AttachmentViewInjector.Type = GalleryAttachmentViewInjector.self

    /// The injector used to inject link attachment views.
    @available(iOSApplicationExtension, unavailable)
    public var linkAttachmentInjector: AttachmentViewInjector.Type = LinkAttachmentViewInjector.self

    /// The injector used for injecting giphy attachment views.
    public var giphyAttachmentInjector: AttachmentViewInjector.Type = GiphyAttachmentViewInjector.self

    /// The injector used for injecting file attachment views.
    public var filesAttachmentInjector: AttachmentViewInjector.Type = FilesAttachmentViewInjector.self

    /// The injector used for injecting unsupported attachment views.
    public var unsupportedAttachmentInjector: AttachmentViewInjector.Type = UnsupportedAttachmentViewInjector.self

    /// The injector used for injecting voice recording attachment views.
    public var voiceRecordingAttachmentInjector: AttachmentViewInjector.Type = VoiceRecordingAttachmentViewInjector.self

    /// The injector used to combine multiple types of attachment views.
    /// By default, it is a combination of a file injector and a gallery injector.
    public var mixedAttachmentInjector: MixedAttachmentViewInjector.Type = MixedAttachmentViewInjector.self

    /// The button for taking an action on attachment being uploaded.
    public var attachmentActionButton: AttachmentActionButton.Type = AttachmentActionButton.self

    /// The view that shows error indicator in `messageContentView`.
    public var messageErrorIndicator: ChatMessageErrorIndicator.Type = ChatMessageErrorIndicator.self

    /// The view that shows message's file attachments.
    public var fileAttachmentListView: ChatMessageFileAttachmentListView
        .Type = ChatMessageFileAttachmentListView.self

    /// The view that shows message's voiceRecording attachments.
    public var voiceRecordingAttachmentListView: ChatMessageVoiceRecordingAttachmentListView
        .Type = ChatMessageVoiceRecordingAttachmentListView.self

    /// The view that shows a single file attachment.
    public var fileAttachmentView: ChatMessageFileAttachmentListView.ItemView.Type =
        ChatMessageFileAttachmentListView.ItemView.self

    /// The view that shows a single voiceRecording attachment.
    public var voiceRecordingAttachmentView: ChatMessageVoiceRecordingAttachmentListView.ItemView.Type =
        ChatMessageVoiceRecordingAttachmentListView.ItemView.self

    /// The view that shows a link preview in message cell.
    public var linkPreviewView: ChatMessageLinkPreviewView.Type =
        ChatMessageLinkPreviewView.self

    /// The view that shows message's image and video attachments.
    public var galleryView: ChatMessageGalleryView.Type = ChatMessageGalleryView.self

    /// The view that shows an image attachment preview inside message cell.
    public var imageAttachmentGalleryPreview: ChatMessageGalleryView.ImagePreview.Type = ChatMessageGalleryView.ImagePreview.self

    /// The view that shows an image attachment in full-screen gallery.
    public var imageAttachmentGalleryCell: ImageAttachmentGalleryCell.Type = ImageAttachmentGalleryCell.self

    /// The view that shows a video attachment in full-screen gallery.
    public var videoAttachmentGalleryCell: VideoAttachmentGalleryCell.Type = VideoAttachmentGalleryCell.self

    /// The view that shows a video attachment preview inside a message.
    public var videoAttachmentGalleryPreview: VideoAttachmentGalleryPreview.Type = VideoAttachmentGalleryPreview.self

    /// A view that displays the voiceRecording attachment preview in composer.
    public var voiceRecordingAttachmentComposerPreview: VoiceRecordingAttachmentComposerPreview
        .Type = VoiceRecordingAttachmentComposerPreview.self

    /// A view that displays the voiceRecording attachment as a quoted preview in composer.
    public var voiceRecordingAttachmentQuotedPreview: VoiceRecordingAttachmentQuotedPreview
        .Type = VoiceRecordingAttachmentQuotedPreview.self

    /// The view that shows an overlay with uploading progress for image attachment that is being uploaded.
    public var uploadingOverlayView: UploadingOverlayView.Type = UploadingOverlayView.self

    /// The view that shows giphy attachment with actions.
    public var giphyAttachmentView: ChatMessageInteractiveAttachmentView.Type = ChatMessageInteractiveAttachmentView.self

    /// The button that shows the attachment action.
    public var giphyActionButton: ChatMessageInteractiveAttachmentView.ActionButton.Type =
        ChatMessageInteractiveAttachmentView.ActionButton.self

    /// The view that shows a content for `.giphy` attachment.
    public var giphyView: ChatMessageGiphyView.Type = ChatMessageGiphyView.self

    /// The view that shows a badge on `giphyAttachmentView`.
    public var giphyBadgeView: ChatMessageGiphyView.GiphyBadge.Type = ChatMessageGiphyView.GiphyBadge.self

    /// The button that indicates unread messages at the bottom of the message list and scroll to the bottom on tap.
    public var scrollToBottomButton: ScrollToBottomButton.Type = ScrollToBottomButton.self

    /// A flag which determines if `Jump to unread` feature will be enabled.
    public var isJumpToUnreadEnabled = false

    /// The button that shows when there are unread messages outside the bounds of the screen. Can be tapped to scroll to them, or can be discarded.
    public var jumpToUnreadMessagesButton: JumpToUnreadMessagesButton.Type = JumpToUnreadMessagesButton.self

    /// The view that shows a number of unread messages on the Scroll-To-Latest-Message button in the Message List.
    public var messageListUnreadCountView: ChatMessageListUnreadCountView.Type =
        ChatMessageListUnreadCountView.self

    /// The view that shows messages delivery status.
    public var messageDeliveryStatusView: ChatMessageDeliveryStatusView.Type =
        ChatMessageDeliveryStatusView.self

    /// The view that shows messages delivery status checkmark in channel preview and in message view.
    public var messageDeliveryStatusCheckmarkView: ChatMessageDeliveryStatusCheckmarkView.Type =
        ChatMessageDeliveryStatusCheckmarkView.self

    /// A flag which determines if an unread messages separator should be displayed when there are new messages.
    public var isUnreadMessagesSeparatorEnabled = true

    /// The view that displays the number of unread messages in the chat.
    public var unreadMessagesCounterDecorationView: ChatUnreadMessagesCountDecorationView.Type = ChatUnreadMessagesCountDecorationView.self

    /// The view that displays the number of unread messages in the chat.
    public var messageHeaderDecorationView: ChatChannelMessageHeaderDecoratorView.Type = ChatChannelMessageHeaderDecoratorView.self

    // MARK: - Reactions

    /// The Reaction picker VC.
    public var reactionPickerVC: ChatMessageReactionsPickerVC.Type = ChatMessageReactionsPickerVC.self

    /// The view that shows reactions bubble.
    public var reactionPickerBubbleView: ChatReactionPickerBubbleView.Type = DefaultChatReactionPickerBubbleView.self

    /// The view that shows the list of reaction toggles/buttons.
    public var reactionPickerReactionsView: ChatMessageReactionsView.Type = ChatReactionPickerReactionsView.self

    /// The view that renders a single reaction view button.
    public var reactionPickerReactionItemView: ChatMessageReactionItemView.Type = ChatMessageReactionItemView.self

    /// The view that shows reactions of a message. This is used by the message component.
    public var messageReactionsBubbleView: ChatReactionBubbleBaseView.Type = ChatReactionsBubbleView.self

    /// The view that shows the list of reactions attached to the message.
    public var messageReactionsView: ChatMessageReactionsView.Type = ChatMessageReactionsView.self

    /// The view that renders a single reaction attached to the message.
    public var messageReactionItemView: ChatMessageReactionItemView.Type = ChatMessageReactionItemView.self

    /// A view controller that renders the reaction and it's author avatar for all the reactions of a message.
    public var reactionAuthorsVC: ChatMessageReactionAuthorsVC.Type = ChatMessageReactionAuthorsVC.self

    /// A view cell that displays an individual reaction author of a message.
    public var reactionAuthorCell: ChatMessageReactionAuthorViewCell.Type = ChatMessageReactionAuthorViewCell.self

    /// The sorting order of how the reactions data will be displayed.
    public var reactionsSorting: ((ChatMessageReactionData, ChatMessageReactionData) -> Bool) = {
        $0.type.rawValue < $1.type.rawValue
    }

    /// A boolean value that determines whether if the reaction types are unique per user.
    /// By default it is false, so each user can have multiple reaction types.
    public var isUniqueReactionsEnabled: Bool = false

    // MARK: - Thread components

    /// The view controller used to display the detail of a message thread.
    public var threadVC: ChatThreadVC.Type = ChatThreadVC.self

    /// The view that displays channel information on the thread header.
    public var threadHeaderView: ChatThreadHeaderView.Type = ChatThreadHeaderView.self

    /// The view that displays the number of replies in the current thread.
    public var threadRepliesCounterDecorationView: ChatThreadRepliesCountDecorationView.Type = ChatThreadRepliesCountDecorationView.self

    /// A boolean value that determines whether thread replies counter decoration should be shown below the source message of a thread.
    public var threadRepliesCounterEnabled = true

    /// A boolean value that determines whether the thread view renders the parent message at the top.
    public var threadRendersParentMessageEnabled = true

    /// A boolean value that determines if thread replies start from the oldest replies.
    /// By default it is false, and newest replies are rendered in the first page.
    public var threadRepliesStartFromOldest = false

    // MARK: - Channel components

    /// The view controller that contains the channel messages and represents the chat view.
    public var channelVC: ChatChannelVC.Type = ChatChannelVC.self

    /// The view that displays channel information on the channel header.
    public var channelHeaderView: ChatChannelHeaderView.Type = ChatChannelHeaderView.self

    /// The collection view layout of the channel list.
    public var channelListLayout: UICollectionViewLayout.Type = ListCollectionViewLayout.self

    /// The `UICollectionViewCell` subclass that shows channel information.
    public var channelCell: ChatChannelListCollectionViewCell.Type = ChatChannelListCollectionViewCell.self

    /// The channel cell separator in the channel list.
    public var channelCellSeparator: UICollectionReusableView.Type = CellSeparatorReusableView.self

    /// The view in the channel cell that shows channel actions on swipe.
    public var channelActionsView: SwipeableView.Type = SwipeableView.self

    /// The view that shows channel information.
    public var channelContentView: ChatChannelListItemView.Type = ChatChannelListItemView.self

    /// The view that shows the channel avatar including an indicator of the user presence (online/offline).
    public var channelAvatarView: ChatChannelAvatarView.Type = ChatChannelAvatarView.self

    /// The view that shows a number of unread messages in channel.
    public var channelUnreadCountView: ChatChannelUnreadCountView.Type = ChatChannelUnreadCountView.self

    /// The view that is displayed when there are no channels on the list, i.e. when is on empty state.
    public var channelListEmptyView: ChatChannelListEmptyView.Type = ChatChannelListEmptyView.self

    /// View that shows that some error occurred on ChatChannelList.
    public var channelListErrorView: ChatChannelListErrorView.Type = ChatChannelListErrorView.self

    /// View that shows when loading the Channel list.
    public var channelListLoadingView: ChatChannelListLoadingView.Type = ChatChannelListLoadingView.self

    /// The `UITableViewCell` responsible to display a skeleton loading view.
    public var channelListLoadingViewCell: ChatChannelListLoadingViewCell.Type = ChatChannelListLoadingViewCell.self

    /// The content view inside the `UITableViewCell` responsible to display a skeleton loading view.
    public var channelListLoadingContentViewCell: ChatChannelListLoadingViewCellContentView.Type = ChatChannelListLoadingViewCellContentView.self

    /// A boolean value that determines whether the Channel list default loading states (empty, error and loading views) are handled by the Stream SDK. It is false by default.
    /// If it is false, it does not show empty or error views and just shows a spinner indicator for the loading state. If set to true, the empty, error and shimmer loading views are shown instead.
    public var isChatChannelListStatesEnabled = false

    // MARK: - Channel Search

    /// The channel list search strategy. By default, search is disabled so it is `nil`.
    ///
    /// To enable searching by messages you can provide the following strategy:
    /// ```
    /// // With default UI Component
    /// Components.default.channelListSearchStrategy = .messages
    /// // With custom UI Component
    /// Components.default.channelListSearchStrategy = .messages(CustomChatMessageSearchVC.self)
    /// ```
    ///
    /// To enable searching by channels you can provide the following strategy:
    /// ```
    /// // With default UI Component
    /// Components.default.channelListSearchStrategy = .channels
    /// // With custom UI Component
    /// Components.default.channelListSearchStrategy = .channels(CustomChatChannelSearchVC.self)
    /// ```
    public var channelListSearchStrategy: ChannelListSearchStrategy?

    // MARK: - Composer components

    /// The view controller used to compose a message.
    public var messageComposerVC: ComposerVC.Type = ComposerVC.self

    /// The view that shows the message when it's being composed.
    public var messageComposerView: ComposerView.Type = ComposerView.self

    /// A view controller that handles the attachments.
    public var messageComposerAttachmentsVC: AttachmentsPreviewVC.Type = AttachmentsPreviewVC.self

    /// A view that holds the attachment views and provide extra functionality over them.
    public var messageComposerAttachmentCell: AttachmentPreviewContainer.Type = AttachmentPreviewContainer.self

    /// A view that displays the document attachment.
    public var messageComposerFileAttachmentView: FileAttachmentView.Type = FileAttachmentView.self

    /// A view that displays image attachment preview in composer.
    public var imageAttachmentComposerPreview: ImageAttachmentComposerPreview
        .Type = ImageAttachmentComposerPreview.self

    /// A view that displays the video attachment preview in composer.
    public var videoAttachmentComposerPreview: VideoAttachmentComposerPreview
        .Type = VideoAttachmentComposerPreview.self

    // MARK: - Composer suggestion components

    /// A view controller that shows suggestions of commands or mentions.
    public var suggestionsVC: ChatSuggestionsVC.Type = ChatSuggestionsVC.self

    /// When true the suggestionsVC will search users from the entire application instead of limit search to the current channel.
    public var mentionAllAppUsers: Bool = false

    /// The collection view of the suggestions view controller.
    public var suggestionsCollectionView: ChatSuggestionsCollectionView.Type = ChatSuggestionsCollectionView.self

    /// A view cell that displays the the suggested mention.
    public var suggestionsMentionCollectionViewCell: ChatMentionSuggestionCollectionViewCell.Type =
        ChatMentionSuggestionCollectionViewCell.self

    /// A view cell that displays the suggested command.
    public var suggestionsCommandCollectionViewCell: ChatCommandSuggestionCollectionViewCell
        .Type = ChatCommandSuggestionCollectionViewCell.self

    /// A type for view embed in cell while tagging users with @ symbol in composer.
    public var suggestionsMentionView: ChatMentionSuggestionView.Type = ChatMentionSuggestionView.self

    /// A view that displays the command name, image and arguments.
    public var suggestionsCommandView: ChatCommandSuggestionView.Type =
        ChatCommandSuggestionView.self

    /// The collection view layout of the suggestions collection view.
    public var suggestionsCollectionViewLayout: UICollectionViewLayout.Type =
        ChatSuggestionsCollectionViewLayout.self

    /// The header reusable view of the suggestion collection view.
    public var suggestionsHeaderReusableView: UICollectionReusableView.Type = ChatSuggestionsCollectionReusableView.self

    /// The header view of the suggestion collection view.
    public var suggestionsHeaderView: ChatSuggestionsHeaderView.Type =
        ChatSuggestionsHeaderView.self

    /// The view that shows a user avatar including an indicator of the user presence (online/offline).
    public var userAvatarView: ChatUserAvatarView.Type = ChatUserAvatarView.self

    // MARK: - Composer VoiceRecording components

    /// A flag which determines if `VoiceRecording` feature will be enabled.
    public var isVoiceRecordingEnabled = false

    /// When set to `true` recorded messages can be grouped together and send as part of one message.
    /// When set to `false`, recorded messages will be sent instantly.
    public var isVoiceRecordingConfirmationRequiredEnabled = true

    /// The ViewController that handles the recording flow.
    public var voiceRecordingViewController: VoiceRecordingVC.Type = VoiceRecordingVC.self

    /// The AudioPlayer that will be used for the voiceRecording playback.
    public var audioPlayer: AudioPlaying.Type = StreamAudioQueuePlayer.self

    /// The AudioRecorder that will be used to record new voiceRecordings.
    public var audioRecorder: AudioRecording.Type = StreamAudioRecorder.self

    /// A feedbackGenerator that will be used to provide haptic feedback during the recording flow.
    public var audioSessionFeedbackGenerator: AudioSessionFeedbackGenerator.Type = StreamAudioSessionFeedbackGenerator.self

    /// If the AudioPlayer supports queuing, this object will be asked to provide the VoiceRecording to
    /// play automatically, once the current one completes.
    public var audioQueuePlayerNextItemProvider: AudioQueuePlayerNextItemProvider.Type = AudioQueuePlayerNextItemProvider.self

    // MARK: - Current user components

    /// The view that shows current user avatar.
    public var currentUserAvatarView: CurrentChatUserAvatarView.Type = CurrentChatUserAvatarView.self

    // MARK: - Navigation

    /// The navigation controller.
    public var navigationVC: NavigationVC.Type = NavigationVC.self

    /// The router responsible for navigation on channel list screen.
    @available(iOSApplicationExtension, unavailable)
    public var channelListRouter: ChatChannelListRouter.Type = ChatChannelListRouter.self

    /// The router responsible for navigation on message list screen.
    public var messageListRouter: ChatMessageListRouter.Type = ChatMessageListRouter.self

    /// The router responsible for presenting alerts.
    public var alertsRouter: AlertsRouter.Type = AlertsRouter.self

    public init() {}
    
    public static var `default` = Self()

    // MARK: Deprecations

    /// The view that shows an overlay with uploading progress for image attachment that is being uploaded.
    @available(*, deprecated, renamed: "uploadingOverlayView")
    public var imageUploadingOverlay: UploadingOverlayView.Type = UploadingOverlayView.self
}

// MARK: Deprecations

public extension Components {
    /// The logic to generate a name for the given channel.
    @available(
        *,
        deprecated,
        message: "Please use `Appearance.default.formatters.channelName` instead"
    )
    var channelNamer: ChatChannelNamer {
        get {
            DefaultChannelNameFormatter.channelNamer
        }
        set {
            DefaultChannelNameFormatter.channelNamer = newValue
        }
    }

    /// The button that indicates unread messages at the bottom of the message list and scroll to the latest message on tap.
    @available(*, deprecated, renamed: "scrollToBottomButton")
    var scrollToLatestMessageButton: ScrollToBottomButton.Type {
        get {
            scrollToBottomButton
        }
        set {
            scrollToBottomButton = newValue
        }
    }

    @available(*, deprecated, renamed: "userAvatarView")
    var mentionAvatarView: ChatUserAvatarView.Type {
        get {
            userAvatarView
        }
        set {
            userAvatarView = newValue
        }
    }

    @available(*, deprecated, renamed: "channelListLoadingView")
    var chatChannelListLoadingView: ChatChannelListLoadingView.Type {
        get {
            channelListLoadingView
        }
        set {
            channelListLoadingView = newValue
        }
    }
}
