//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChat
import UIKit

/// The possible errors that can occur in attachment validation
public enum AttachmentValidationError: Error {
    /// The size of the attachment exceeds the max file size
    case maxFileSizeExceeded

    /// The number of attachments reached the limit.
    case maxAttachmentsCountPerMessageExceeded(limit: Int)

    internal static var fileSizeMaxLimitFallback: Int64 = 100 * 1024 * 1024
}

public struct LocalAttachmentInfoKey: Hashable, Equatable, RawRepresentable {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public static let originalImage: Self = .init(rawValue: "originalImage")
    public static let duration: Self = .init(rawValue: "duration")
    public static let waveformData: Self = .init(rawValue: "waveformData")
}

/// The possible composer states. An Enum is not used so it does not cause
/// future breaking changes and is possible to extend with new cases.
public struct ComposerState: RawRepresentable, Equatable {
    public let rawValue: String
    public var description: String { rawValue.uppercased() }

    public init(rawValue: RawValue) {
        self.rawValue = rawValue
    }

    public static var new = ComposerState(rawValue: "new")
    public static var edit = ComposerState(rawValue: "edit")
    public static var quote = ComposerState(rawValue: "quote")
    public static var recording = ComposerState(rawValue: "recording")
    public static var recordingLocked = ComposerState(rawValue: "recordingLocked")
}

/// A view controller that manages the composer view.
open class ComposerVC: _ViewController,
    ThemeProvider,
    UITextViewDelegate,
    UIImagePickerControllerDelegate,
    UIDocumentPickerDelegate,
    UINavigationControllerDelegate,
    InputTextViewClipboardAttachmentDelegate,
    VoiceRecordingDelegate {
    /// The content of the composer.
    public struct Content {
        /// The text of the input text view.
        public var text: String
        /// The state of the composer.
        public let state: ComposerState
        /// The editing message if the composer is currently editing a message.
        public let editingMessage: ChatMessage?
        /// The quoting message if the composer is currently quoting a message.
        public let quotingMessage: ChatMessage?
        /// The thread parent message if the composer is currently replying in a thread.
        public var threadMessage: ChatMessage?
        /// The attachments of the message.
        public var attachments: [AnyAttachmentPayload]
        /// The mentioned users in the message.
        public var mentionedUsers: Set<ChatUser>
        /// The command of the message.
        public let command: Command?
        /// The extra data assigned to message.
        public var extraData: [String: RawJSON]
        /// The current cooldown time for the Slow mode active on channel.
        public var cooldownTime: Int
        /// A boolean value indicating if the message url enrichment should be skipped.
        public var skipEnrichUrl: Bool

        /// A boolean that checks if the message contains any content.
        public var isEmpty: Bool {
            // If there is a command and it doesn't require an arg, content is not empty
            if let command = command, command.args.isEmpty {
                return false
            }
            // All other cases
            return text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && attachments.isEmpty
        }

        /// A boolean that checks if the composer is replying in a thread
        public var isInsideThread: Bool { threadMessage != nil }
        /// A boolean that checks if the composer recognised already a command.
        public var hasCommand: Bool { command != nil }

        /// A boolean that checks if slow mode is on.
        public var isSlowModeOn: Bool {
            cooldownTime > 0
        }

        /// A boolean that checks if the composer is in voice recording mode.
        public var isVoiceRecording: Bool {
            state == .recording || state == .recordingLocked
        }

        /// A boolean that checks if the message only contains link attachments.
        public var hasOnlyLinkAttachments: Bool {
            let linkAttachmentsCount = attachments.filter { $0.type == .linkPreview }.count
            let onlyContainsLinkAttachments = attachments.count == linkAttachmentsCount
            return onlyContainsLinkAttachments
        }

        public init(
            text: String,
            state: ComposerState,
            editingMessage: ChatMessage?,
            quotingMessage: ChatMessage?,
            threadMessage: ChatMessage?,
            attachments: [AnyAttachmentPayload],
            mentionedUsers: Set<ChatUser>,
            command: Command?,
            extraData: [String: RawJSON] = [:],
            cooldownTime: Int = 0,
            skipEnrichUrl: Bool = false
        ) {
            self.text = text
            self.state = state
            self.editingMessage = editingMessage
            self.quotingMessage = quotingMessage
            self.threadMessage = threadMessage
            self.attachments = attachments
            self.mentionedUsers = mentionedUsers
            self.command = command
            self.extraData = extraData
            self.cooldownTime = cooldownTime
            self.skipEnrichUrl = skipEnrichUrl
        }

        /// Creates a new content struct with all empty data.
        static func initial() -> Content {
            .init(
                text: "",
                state: .new,
                editingMessage: nil,
                quotingMessage: nil,
                threadMessage: nil,
                attachments: [],
                mentionedUsers: [],
                command: nil,
                extraData: [:],
                cooldownTime: 0,
                skipEnrichUrl: false
            )
        }

        /// Resets the current content state and clears the content.
        public mutating func clear() {
            self = .init(
                text: "",
                state: .new,
                editingMessage: nil,
                quotingMessage: nil,
                threadMessage: threadMessage,
                attachments: [],
                mentionedUsers: [],
                command: nil,
                extraData: [:],
                cooldownTime: cooldownTime,
                skipEnrichUrl: false
            )
        }

        /// Sets the content state to editing a message.
        ///
        /// - Parameter message: The message that the composer will edit.
        public mutating func editMessage(_ message: ChatMessage) {
            self = .init(
                text: message.text,
                state: .edit,
                editingMessage: message,
                quotingMessage: nil,
                threadMessage: threadMessage,
                attachments: message.allAttachments.toAnyAttachmentPayload(),
                mentionedUsers: message.mentionedUsers,
                command: command,
                extraData: message.extraData,
                cooldownTime: cooldownTime,
                skipEnrichUrl: skipEnrichUrl
            )
        }

        /// Sets the content state to quoting a message.
        ///
        /// - Parameter message: The message that the composer will quote.
        public mutating func quoteMessage(_ message: ChatMessage) {
            self = .init(
                text: text,
                state: .quote,
                editingMessage: nil,
                quotingMessage: message,
                threadMessage: threadMessage,
                attachments: attachments,
                mentionedUsers: mentionedUsers,
                command: command,
                extraData: extraData,
                cooldownTime: cooldownTime,
                skipEnrichUrl: skipEnrichUrl
            )
        }

        public mutating func addCommand(_ command: Command) {
            self = .init(
                text: "",
                state: state,
                editingMessage: editingMessage,
                quotingMessage: quotingMessage,
                threadMessage: threadMessage,
                attachments: [],
                mentionedUsers: mentionedUsers,
                command: command,
                extraData: extraData,
                cooldownTime: cooldownTime,
                skipEnrichUrl: skipEnrichUrl
            )
        }

        public mutating func slowMode(cooldown: Int) {
            self = .init(
                text: text,
                state: state,
                editingMessage: editingMessage,
                quotingMessage: quotingMessage,
                threadMessage: threadMessage,
                attachments: attachments,
                mentionedUsers: mentionedUsers,
                command: command,
                extraData: extraData,
                cooldownTime: cooldown,
                skipEnrichUrl: skipEnrichUrl
            )
        }

        public mutating func resetSlowMode() {
            self = .init(
                text: text,
                state: state,
                editingMessage: editingMessage,
                quotingMessage: quotingMessage,
                threadMessage: threadMessage,
                attachments: attachments,
                mentionedUsers: mentionedUsers,
                command: command,
                extraData: extraData,
                cooldownTime: 0,
                skipEnrichUrl: skipEnrichUrl
            )
        }

        public mutating func recording() {
            self = .init(
                text: text,
                state: .recording,
                editingMessage: editingMessage,
                quotingMessage: quotingMessage,
                threadMessage: threadMessage,
                attachments: attachments,
                mentionedUsers: mentionedUsers,
                command: command,
                skipEnrichUrl: skipEnrichUrl
            )
        }

        public mutating func recordingLocked() {
            self = .init(
                text: text,
                state: .recordingLocked,
                editingMessage: editingMessage,
                quotingMessage: quotingMessage,
                threadMessage: threadMessage,
                attachments: attachments,
                mentionedUsers: mentionedUsers,
                command: command,
                skipEnrichUrl: skipEnrichUrl
            )
        }
    }

    /// The content of the composer.
    public var content: Content = .initial() {
        didSet {
            updateContentIfNeeded()
        }
    }

    /// The component responsible for tracking cooldown timing when slow mode is enabled.
    open var cooldownTracker: CooldownTracker = CooldownTracker(timer: ScheduledStreamTimer(interval: 1))

    /// The debouncer to control requests when enriching urls.
    public var enrichUrlDebouncer = Debouncer(0.4, queue: .main)

    /// The debouncer to control user searching requests when mentioning users.
    public var userMentionsDebouncer = Debouncer(0.25, queue: .main)

    lazy var linkDetector = TextLinkDetector()

    /// A symbol that is used to recognise when the user is mentioning a user.
    open var mentionSymbol = "@"

    /// A symbol that is used to recognise when the user is typing a command.
    open var commandSymbol = "/"

    /// A Boolean value indicating whether the commands are enabled.
    open var isCommandsEnabled: Bool {
        channelConfig?.commands.isEmpty == false
    }

    /// A Boolean value indicating whether the user mentions are enabled.
    open var isMentionsEnabled: Bool {
        true
    }

    /// A Boolean value indicating whether the attachments are enabled.
    open var isAttachmentsEnabled: Bool {
        channelController?.channel?.canUploadFile ?? true
    }

    /// A Boolean value indicating whether sending message is enabled.
    open var isSendMessageEnabled: Bool {
        channelController?.channel?.canSendMessage ?? true
    }

    /// A Boolean value indicating whether if the message being sent can contain links.
    open var canSendLinks: Bool {
        channelController?.channel?.canSendLinks ?? true
    }

    /// A Boolean value indicating whether the current input text contains links.
    open var inputContainsLinks: Bool {
        linkDetector.hasLinks(in: content.text)
    }

    /// When enabled mentions search users across the entire app instead of searching
    open private(set) lazy var mentionAllAppUsers: Bool = components.mentionAllAppUsers

    /// A controller to search users and that is used to populate the mention suggestions.
    open var userSearchController: ChatUserSearchController!

    /// A controller to search members in a channel and that is used to populate the mention suggestions.
    open var memberListController: ChatChannelMemberListController?

    /// A controller that manages the channel that the composer is creating content for.
    open var channelController: ChatChannelController?

    /// The channel config. If it's a new channel, an empty config should be created. (Not yet supported right now)
    public var channelConfig: ChannelConfig? {
        channelController?.channel?.config
    }

    /// The component responsible for mention suggestions.
    open lazy var mentionSuggester = TypingSuggester(
        options: TypingSuggestionOptions(
            symbol: mentionSymbol
        )
    )

    /// The component responsible for autocomplete command suggestions.
    open lazy var commandSuggester = TypingSuggester(
        options: TypingSuggestionOptions(
            symbol: commandSymbol,
            shouldTriggerOnlyAtStart: true
        )
    )

    /// The view controller responsible to managing the VoiceRecording flow.
    open internal(set) lazy var voiceRecordingVC = components
        .voiceRecordingViewController
        .init(composerView: composerView)

    /// The audioPlayer that will be used for the VoiceRecording's playback.
    open var audioPlayer: AudioPlaying? {
        didSet {
            // When the audioPlayer changes to a new instance, forward it to
            // the attachmentsVC and voiceRecordingVC to ensure that all are using
            // the same one.
            attachmentsVC.audioPlayer = audioPlayer
            voiceRecordingVC.audioPlayer = audioPlayer
        }
    }

    open private(set) lazy var composerView: ComposerView = components
        .messageComposerView.init()
        .withoutAutoresizingMaskConstraints

    /// The view controller that shows the suggestions when the user is typing.
    open private(set) lazy var suggestionsVC: ChatSuggestionsVC = components
        .suggestionsVC
        .init()

    /// The view controller that shows the suggestions when the user is typing.
    open private(set) lazy var attachmentsVC: AttachmentsPreviewVC = components
        .messageComposerAttachmentsVC
        .init()

    /// The view controller for selecting image attachments.
    open private(set) lazy var mediaPickerVC: UIViewController = {
        let picker = UIImagePickerController()
        picker.mediaTypes = UIImagePickerController.availableMediaTypes(for: .savedPhotosAlbum) ?? ["public.image"]
        picker.sourceType = .savedPhotosAlbum
        picker.delegate = self
        return picker
    }()

    /// The View Controller for taking a picture.
    open private(set) lazy var cameraVC: UIViewController = {
        let camera = UIImagePickerController()
        camera.sourceType = .camera
        camera.modalPresentationStyle = .overFullScreen
        camera.mediaTypes = UIImagePickerController.availableMediaTypes(for: .camera) ?? ["public.image"]
        camera.delegate = self
        return camera
    }()

    /// The view controller for selecting file attachments.
    open private(set) lazy var filePickerVC: UIViewController = {
        let picker = UIDocumentPickerViewController(documentTypes: ["public.item"], in: .import)
        picker.delegate = self
        picker.allowsMultipleSelection = true
        return picker
    }()

    override open func setUp() {
        super.setUp()

        composerView.inputMessageView.textView.delegate = self

        // Set the delegate for handling the pasting of UIImages in the text view
        composerView.inputMessageView.textView.clipboardAttachmentDelegate = self

        composerView.attachmentButton.addTarget(self, action: #selector(showAttachmentsPicker), for: .touchUpInside)
        composerView.sendButton.addTarget(self, action: #selector(publishMessage), for: .touchUpInside)
        composerView.confirmButton.addTarget(self, action: #selector(publishMessage), for: .touchUpInside)
        composerView.shrinkInputButton.addTarget(self, action: #selector(shrinkInput), for: .touchUpInside)
        composerView.commandsButton.addTarget(self, action: #selector(showAvailableCommands), for: .touchUpInside)
        composerView.dismissButton.addTarget(self, action: #selector(clearContent(sender:)), for: .touchUpInside)
        composerView.inputMessageView.clearButton.addTarget(
            self,
            action: #selector(clearContent(sender:)),
            for: .touchUpInside
        )

        channelController?.delegate = self

        setupAttachmentsView()
        setupVoiceRecordingView()

        cooldownTracker.onChange = { [weak self] currentTime in
            guard currentTime != 0 && self?.content.state != .edit else {
                self?.content.resetSlowMode()
                return
            }

            self?.content.slowMode(cooldown: currentTime)
        }

        composerView.inputMessageView.textView.onLinksChanged = { [weak self] links in
            self?.didChangeLinks(links)
        }
        composerView.linkPreviewView.onClose = { [weak self] in
            self?.dismissLinkPreview()
        }
    }

    override open func setUpLayout() {
        super.setUpLayout()

        view.addSubview(composerView)
        composerView.pin(to: view)
    }

    open func setupAttachmentsView() {
        addChildViewController(attachmentsVC, embedIn: composerView.inputMessageView.attachmentsViewContainer)
        attachmentsVC.didTapRemoveItemButton = { [weak self] index in
            self?.content.attachments.remove(at: index)
        }
    }

    open func setupVoiceRecordingView() {
        voiceRecordingVC.delegate = self
        addChild(voiceRecordingVC)
        voiceRecordingVC.didMove(toParent: self)
        voiceRecordingVC.setUp()
    }

    override open func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        resumeCurrentCooldown()
    }

    override open func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        dismissSuggestions()
    }

    // MARK: Update Content

    override open func updateContent() {
        super.updateContent()
        // Note: The order of the calls is important.
        updateText()
        updateKeystrokeEvents()
        updateTitleLabel()
        updateCommandsButtonVisibility()
        updateConfirmButtonVisibility()
        updateSendButtonVisibility()
        updateAttachmentButtonVisibility()
        updateHeaderViewVisibility()
        updateRecordButtonVisibility()
        updateCooldownView()
        updateCooldownViewVisibility()
        updateSendButtonEnabled()
        updateConfirmButtonEnabled()
        updateInputMessageView()
        updateInputMessageViewVisibility()
        updateInputAttachmentsView()
        updateLinkPreview()
        updateCheckbox()
        updateBottomContainerVisibility()
        updateLeadingContainerVisibility()
        updateSuggestions()
        updatePlaceholderLabel()
    }

    open func updateText() {
        if composerView.inputMessageView.textView.text != content.text {
            // Updating the text unnecessarily makes the caret jump to the end of input
            composerView.inputMessageView.textView.text = content.text
        }
    }

    open func updateKeystrokeEvents() {
        if !content.isEmpty && channelConfig?.typingEventsEnabled == true {
            channelController?.sendKeystrokeEvent(parentMessageId: content.threadMessage?.id)
        }
    }

    open func updateRecordButtonVisibility() {
        guard isSendMessageEnabled else {
            composerView.recordButton.isHidden = true
            return
        }

        let isSendButtonHidden = composerView.sendButton.isHidden
        let isConfirmButtonHidden = composerView.confirmButton.isHidden
        let isVoiceRecordingEnabled = components.isVoiceRecordingEnabled
        Animate {
            switch self.content.state {
            case .new:
                self.composerView.recordButton.isHidden = isSendButtonHidden || !isVoiceRecordingEnabled || !self.isAttachmentsEnabled
            case .recording:
                self.composerView.recordButton.isHidden = false
            case .recordingLocked:
                self.composerView.recordButton.isHidden = true
            case .quote:
                self.composerView.recordButton.isHidden = isSendButtonHidden || !isVoiceRecordingEnabled || !self.isAttachmentsEnabled
            case .edit:
                self.composerView.recordButton.isHidden = isConfirmButtonHidden || !self.isAttachmentsEnabled
            default:
                break
            }
        }
    }

    open func updateTitleLabel() {
        switch content.state {
        case .edit:
            composerView.titleLabel.text = L10n.Composer.Title.edit
        case .quote:
            composerView.titleLabel.text = L10n.Composer.Title.reply
        default:
            break
        }
    }

    open func updateCooldownView() {
        composerView.cooldownView.content = .init(cooldown: content.cooldownTime)
    }

    open func updateCooldownViewVisibility() {
        Animate {
            switch self.content.state {
            case .new, .quote:
                self.composerView.cooldownView.isHidden = !self.content.isSlowModeOn
            case .edit, .recording, .recordingLocked:
                self.composerView.cooldownView.isHidden = true
            default:
                break
            }
        }
    }

    open func updateSendButtonEnabled() {
        composerView.sendButton.isEnabled = !content.isEmpty
    }

    open func updateConfirmButtonEnabled() {
        composerView.confirmButton.isEnabled = !content.isEmpty
    }

    open func updateAttachmentButtonVisibility() {
        guard isSendMessageEnabled else {
            composerView.attachmentButton.isHidden = true
            return
        }

        let isAttachmentButtonHidden = !isAttachmentsEnabled || content.hasCommand || !composerView.shrinkInputButton.isHidden
        Animate {
            self.composerView.attachmentButton.isHidden = isAttachmentButtonHidden
        }
    }

    open func updateCommandsButtonVisibility() {
        guard isSendMessageEnabled else {
            composerView.commandsButton.isHidden = true
            return
        }

        let isCommandsButtonHidden = !isCommandsEnabled || content.hasCommand || !composerView.shrinkInputButton.isHidden
        Animate {
            self.composerView.commandsButton.isHidden = isCommandsButtonHidden
        }
    }

    open func updateInputMessageView() {
        composerView.inputMessageView.content = .init(
            quotingMessage: content.quotingMessage,
            command: content.command,
            channel: channelController?.channel
        )
        composerView.inputMessageView.isUserInteractionEnabled = isSendMessageEnabled
    }

    open func updateInputMessageViewVisibility() {
        Animate {
            self.composerView.inputMessageView.isHidden = self.content.isVoiceRecording
        }
    }

    open func updateInputAttachmentsView() {
        attachmentsVC.content = content.attachments.map {
            if let provider = $0.payload as? AttachmentPreviewProvider {
                return provider
            } else {
                log.warning("""
                Attachment \($0) doesn't conform to the `AttachmentPreviewProvider` protocol. Add the conformance \
                to this protocol to avoid using the attachment preview placeholder in the composer.
                """)
                return DefaultAttachmentPreviewProvider()
            }
        }
        composerView.inputMessageView.attachmentsViewContainer.isHidden = content.attachments.isEmpty
    }

    open func updateLinkPreview() {
        // Since we don't want to show link previews with other attachment types, we dismiss the
        // link preview in case it is being shown and there are other types of attachments in the message.
        if content.hasOnlyLinkAttachments == false && content.skipEnrichUrl == false {
            dismissLinkPreview()
        }
    }

    open func updateCheckbox() {
        if content.isInsideThread {
            if channelController?.channel?.isDirectMessageChannel == true {
                composerView.checkboxControl.label.text = L10n.Composer.Checkmark.directMessageReply
            } else {
                composerView.checkboxControl.label.text = L10n.Composer.Checkmark.channelReply
            }
        }
    }

    open func updateBottomContainerVisibility() {
        Animate {
            self.composerView.bottomContainer.isHidden = !self.content.isInsideThread
        }
    }

    open func updateLeadingContainerVisibility() {
        Animate {
            self.composerView.leadingContainer.isHidden = self.content.isVoiceRecording
        }
    }

    /// Controls whether the suggestions view should be shown or not.
    /// By default there are 2 types of suggestions: Commands and Mentions.
    open func updateSuggestions() {
        if isCommandsEnabled, let typingCommand = typingCommand(in: composerView.inputMessageView.textView) {
            showCommandSuggestions(for: typingCommand)
            return
        }
        
        if isMentionsEnabled, let (typingMention, mentionRange) = typingMention(in: composerView.inputMessageView.textView) {
            userMentionsDebouncer.execute { [weak self] in
                self?.showMentionSuggestions(for: typingMention, mentionRange: mentionRange)
            }
            return
        }

        dismissSuggestions()
    }

    open func updatePlaceholderLabel() {
        guard isSendMessageEnabled else {
            composerView.inputMessageView.textView.placeholderLabel.text = L10n.Composer.Placeholder.messageDisabled
            return
        }

        composerView.inputMessageView.textView.placeholderLabel.text = content.isSlowModeOn
            ? L10n.Composer.Placeholder.slowMode
            : L10n.Composer.Placeholder.message
    }

    open func updateConfirmButtonVisibility() {
        guard isSendMessageEnabled else {
            composerView.confirmButton.isHidden = true
            return
        }
        
        Animate {
            self.composerView.confirmButton.isHidden = self.content.state != .edit
        }
    }

    open func updateSendButtonVisibility() {
        Animate {
            switch self.content.state {
            case .new, .quote:
                self.composerView.sendButton.isHidden = self.content.isSlowModeOn
            case .edit, .recording, .recordingLocked:
                self.composerView.sendButton.isHidden = true
            default:
                break
            }
        }
    }

    open func updateHeaderViewVisibility() {
        Animate {
            switch self.content.state {
            case .new, .recording:
                self.composerView.headerView.isHidden = true
            case .edit, .quote, .recordingLocked:
                self.composerView.headerView.isHidden = false
            default:
                break
            }
        }
    }

    // MARK: - Actions

    @objc open func publishMessage(sender: UIButton) {
        if !canSendLinks && inputContainsLinks {
            presentAlert(title: L10n.Composer.LinksDisabled.title, message: L10n.Composer.LinksDisabled.subtitle)
            return
        }

        let text: String
        if let command = content.command {
            text = "/\(command.name) " + content.text
        } else {
            text = content.text.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        if let editingMessage = content.editingMessage {
            editMessage(withId: editingMessage.id, newText: text)

            // This is just a temporary solution. This will be handled on the LLC level
            // in CIS-883
            channelController?.sendStopTypingEvent()
            content.clear()
        } else {
            createNewMessage(text: text)

            let channel = channelController?.channel
            let skipSlowMode = channel?.ownCapabilities.contains(.skipSlowMode) == true
            if !content.hasCommand, !skipSlowMode, let cooldownDuration = channel?.cooldownDuration {
                cooldownTracker.start(with: cooldownDuration)
            }

            content.clear()
        }
    }

    /// Shows a photo/media picker.
    open func showMediaPicker() {
        present(mediaPickerVC, animated: true)
    }

    /// Shows a document picker.
    open func showFilePicker() {
        present(filePickerVC, animated: true)
    }

    /// Shows the camera view.
    open func showCamera() {
        present(cameraVC, animated: true)
    }

    /// Shows the poll creation view.
    open func showPollCreation() {
        guard let channelId = channelController?.channel?.cid,
              let channelController = channelController?.client.channelController(for: channelId)
        else {
            return
        }
        let pollCreationVC = components.pollCreationVC.init(channelController: channelController)
        let navVC = UINavigationController(rootViewController: pollCreationVC)
        present(navVC, animated: true)
    }

    /// Returns actions for attachments picker.
    open var attachmentsPickerActions: [UIAlertAction] {
        let isCameraAvailable = UIImagePickerController.isSourceTypeAvailable(.camera)
        let isPollCreationEnabled = channelConfig?.pollsEnabled == true

        let showFilePickerAction = UIAlertAction(
            title: L10n.Composer.Picker.file,
            style: .default,
            handler: { [weak self] _ in self?.showFilePicker() }
        )

        let showMediaPickerAction = UIAlertAction(
            title: L10n.Composer.Picker.media,
            style: .default,
            handler: { [weak self] _ in self?.showMediaPicker() }
        )

        let showCameraAction = isCameraAvailable ? UIAlertAction(
            title: L10n.Composer.Picker.camera,
            style: .default,
            handler: { [weak self] _ in self?.showCamera() }
        ) : nil

        let showPollCreationAction = isPollCreationEnabled && !content.isInsideThread ? UIAlertAction(
            title: L10n.Composer.Picker.poll,
            style: .default,
            handler: { [weak self] _ in self?.showPollCreation() }
        ) : nil

        let cancelAction = UIAlertAction(
            title: L10n.Composer.Picker.cancel,
            style: .cancel
        )

        return [
            showCameraAction,
            showMediaPickerAction,
            showFilePickerAction,
            showPollCreationAction,
            cancelAction
        ].compactMap { $0 }
    }

    /// Action that handles tap on attachments button in composer.
    @objc open func showAttachmentsPicker(sender: UIButton) {
        presentAlert(
            message: L10n.Composer.Picker.title,
            preferredStyle: .actionSheet,
            actions: attachmentsPickerActions,
            sourceView: sender
        )
    }

    @objc open func shrinkInput(sender: UIButton) {
        Animate {
            self.composerView.shrinkInputButton.isHidden = true
            self.composerView.leadingContainer.subviews
                .filter { $0 !== self.composerView.shrinkInputButton }
                .forEach {
                    $0.isHidden = false
                }

            // If attachment uploads is disabled, don't ever show the attachments button
            if !self.isAttachmentsEnabled {
                self.composerView.attachmentButton.isHidden = true
            }
        }
    }

    @objc open func showAvailableCommands(sender: UIButton) {
        if suggestionsVC.isPresented {
            dismissSuggestions()
        } else {
            showCommandSuggestions(for: "")
        }
    }

    @objc open func clearContent(sender: UIButton) {
        content.clear()
    }

    /// Creates a new message and notifies the delegate that a new message was created.
    /// - Parameter text: The text content of the message.
    open func createNewMessage(text: String) {
        guard let cid = channelController?.cid else { return }

        // If the user included some mentions via suggestions,
        // but then removed them from text, we should remove them from
        // the content we'll send
        for user in content.mentionedUsers {
            if !text.contains(mentionText(for: user)) {
                content.mentionedUsers.remove(user)
            }
        }

        if let threadParentMessageId = content.threadMessage?.id {
            let messageController = channelController?.client.messageController(
                cid: cid,
                messageId: threadParentMessageId
            )

            messageController?.createNewReply(
                text: text,
                pinning: nil,
                attachments: content.attachments,
                mentionedUserIds: content.mentionedUsers.map(\.id),
                showReplyInChannel: composerView.checkboxControl.isSelected,
                quotedMessageId: content.quotingMessage?.id,
                skipEnrichUrl: content.skipEnrichUrl,
                extraData: content.extraData
            )
            return
        }

        channelController?.createNewMessage(
            text: text,
            pinning: nil,
            attachments: content.attachments,
            mentionedUserIds: content.mentionedUsers.map(\.id),
            quotedMessageId: content.quotingMessage?.id,
            skipEnrichUrl: content.skipEnrichUrl,
            extraData: content.extraData
        )
    }

    /// Updates an existing message.
    /// - Parameters:
    ///   - id: The id of the editing message.
    ///   - newText: The new text content of the message.
    open func editMessage(withId id: MessageId, newText: String) {
        guard let cid = channelController?.cid else { return }
        let messageController = channelController?.client.messageController(
            cid: cid,
            messageId: id
        )
        // TODO: Adjust LLC to edit mentions
        messageController?.editMessage(
            text: newText,
            skipEnrichUrl: content.skipEnrichUrl,
            attachments: content.attachments,
            extraData: content.extraData
        )
    }

    /// Returns a potential user mention in case the user is currently typing a username.
    /// - Parameter textView: The text view of the message input view where the user is typing.
    /// - Returns: A tuple with the potential user mention and the position of the mention so it can be autocompleted.
    open func typingMention(in textView: UITextView) -> (String, NSRange)? {
        guard let typingSuggestion = mentionSuggester.typingSuggestion(in: textView) else {
            return nil
        }

        return (typingSuggestion.text, typingSuggestion.locationRange)
    }

    /// Returns a potential command in case the user is currently typing a command.
    /// - Parameter textView: The text view of the message input view where the user is typing.
    /// - Returns: A string of the corresponding potential command.
    open func typingCommand(in textView: UITextView) -> String? {
        let typingSuggestion = commandSuggester.typingSuggestion(in: textView)
        return typingSuggestion?.text
    }

    /// Shows the command suggestions for the potential command the current user is typing.
    /// - Parameter typingCommand: The potential command that the current user is typing.
    open func showCommandSuggestions(for typingCommand: String) {
        let availableCommands = channelController?.channel?.config.commands ?? []

        // Don't show the commands suggestion VC if there are no commands
        guard availableCommands.isEmpty == false else { return }

        var commandHints: [Command] = availableCommands

        if !typingCommand.isEmpty {
            commandHints = availableCommands.filter {
                $0.name.range(of: typingCommand, options: .caseInsensitive) != nil
            }
        }

        let typingCommandMatches: ((Command) -> Bool) = { availableCommand in
            availableCommand.name.compare(typingCommand, options: .caseInsensitive) == .orderedSame
        }
        if let foundCommand = availableCommands.first(where: typingCommandMatches), !content.hasCommand {
            content.addCommand(foundCommand)

            dismissSuggestions()
            return
        }

        let dataSource = ChatMessageComposerSuggestionsCommandDataSource(
            with: commandHints,
            collectionView: suggestionsVC.collectionView
        )
        suggestionsVC.dataSource = dataSource
        suggestionsVC.didSelectItemAt = { [weak self] commandIndex in
            guard let hintCommand = commandHints[safe: commandIndex] else {
                indexNotFoundAssertion()
                return
            }

            self?.content.addCommand(hintCommand)

            self?.dismissSuggestions()
        }

        showSuggestions()
    }

    /// Returns the query to be used for searching users across the whole app.
    ///
    /// This function is called in `showMentionSuggestions` to retrieve the query
    /// that will be used to search the users. You should override this if you want to change the
    /// user searching logic.
    ///
    /// - Parameter typingMention: The potential user mention the current user is typing.
    /// - Returns: `UserListQuery` instance that will be used for searching users.
    open func queryForMentionSuggestionsSearch(typingMention term: String) -> UserListQuery {
        UserListQuery(
            filter: .or([
                .autocomplete(.name, text: term),
                .autocomplete(.id, text: term)
            ]),
            sort: [.init(key: .name, isAscending: true)]
        )
    }

    /// Returns the query to be used for searching members inside a channel.
    ///
    /// This function is called in `showMentionSuggestions` to retrieve the query
    /// that will be used to search for members. You should override this if you want to change the
    /// member searching logic.
    ///
    /// - Parameter typingMention: The potential user mention the current user is typing.
    /// - Returns: `ChannelMemberListQuery` instance that will be used for searching members in a channel.
    open func queryForChannelMentionSuggestionsSearch(typingMention term: String) -> ChannelMemberListQuery? {
        guard let cid = channelController?.cid else {
            return nil
        }
        return ChannelMemberListQuery(
            cid: cid,
            filter: .autocomplete(.name, text: term),
            sort: [.init(key: .name, isAscending: true)]
        )
    }

    /// Returns the member list controller to be used for searching members inside a channel.
    ///
    /// - Parameter term: The potential user mention the current user is typing.
    /// - Returns: `ChatChannelMemberListController` instance that will be used for searching members in a channel.
    open func makeMemberListControllerForMemberSuggestions(typingMention term: String) -> ChatChannelMemberListController? {
        guard let query = queryForChannelMentionSuggestionsSearch(typingMention: term) else { return nil }
        return userSearchController.client.memberListController(query: query)
    }

    /// Shows the mention suggestions for the potential mention the current user is typing.
    /// - Parameters:
    ///   - typingMention: The potential user mention the current user is typing.
    ///   - mentionRange: The position where the current user is typing a mention to it can be replaced with the suggestion.
    open func showMentionSuggestions(for typingMention: String, mentionRange: NSRange) {
        guard !content.text.isEmpty else {
            // Because we do not have cancellation, when a mention request is finished it can happen
            // that we already published the message, so we don't need to show the suggestions anymore.
            return
        }
        guard let dataSource = makeMentionSuggestionsDataSource(for: typingMention) else {
            return
        }
        suggestionsVC.dataSource = dataSource
        suggestionsVC.didSelectItemAt = { [weak self] userIndex in
            guard let self = self else { return }
            guard dataSource.users.count >= userIndex else {
                return
            }
            guard let user = dataSource.users[safe: userIndex] else {
                indexNotFoundAssertion()
                return
            }

            let textView = self.composerView.inputMessageView.textView
            let text = textView.text as NSString
            let mentionText = self.mentionText(for: user)
            guard mentionRange.length <= mentionText.count else {
                return self.dismissSuggestions()
            }

            let newText = text.replacingCharacters(in: mentionRange, with: mentionText)
            // Add additional spacing to help continue writing the message
            self.content.text = newText + " "
            self.content.mentionedUsers.insert(user)

            let caretLocation = textView.selectedRange.location
            let newCaretLocation = caretLocation + (mentionText.count - typingMention.count)
            textView.selectedRange = NSRange(location: newCaretLocation, length: 0)

            self.dismissSuggestions()
        }

        showSuggestions()
    }

    /// Creates a `ChatMessageComposerSuggestionsMentionDataSource` with data from local cache, user search or channel members.
    /// The source of the data will depend on `mentionAllAppUsers` flag and the amount of members in the channel.
    /// - Parameter typingMention: The potential user mention the current user is typing.
    /// - Returns: A `ChatMessageComposerSuggestionsMentionDataSource` instance.
    public func makeMentionSuggestionsDataSource(for typingMention: String) -> ChatMessageComposerSuggestionsMentionDataSource? {
        guard let channel = channelController?.channel else {
            return nil
        }

        guard let currentUserId = channelController?.client.currentUserId else {
            return nil
        }

        let trimmedTypingMention = typingMention.trimmingCharacters(in: .whitespacesAndNewlines)
        let mentionedUsersNames = content.mentionedUsers.map(\.name)
        let mentionedUsersIds = content.mentionedUsers.map(\.id)
        let mentionIsAlreadyPresent = mentionedUsersNames.contains(trimmedTypingMention) || mentionedUsersIds.contains(trimmedTypingMention)
        let shouldShowEmptyMentions = typingMention.isEmpty || mentionIsAlreadyPresent

        // Because we re-create the ChatMessageComposerSuggestionsMentionDataSource always from scratch
        // We lose the results of the previous search query, so we need to provide it manually.
        let initialUsers: (String, [ChatUser]) -> [ChatUser] = { previousQuery, previousResult in
            if typingMention.isEmpty {
                return []
            }
            if typingMention.hasPrefix(previousQuery) || previousQuery.hasPrefix(typingMention) {
                return previousResult
            }
            return []
        }

        if mentionAllAppUsers {
            var previousResult = userSearchController.userArray
            let previousQuery = (userSearchController?.query?.filter?.value as? String) ?? ""
            if shouldShowEmptyMentions {
                userSearchController.clearResults()
                previousResult = []
            } else {
                userSearchController.search(
                    query: queryForMentionSuggestionsSearch(typingMention: typingMention)
                )
            }
            return ChatMessageComposerSuggestionsMentionDataSource(
                collectionView: suggestionsVC.collectionView,
                searchController: userSearchController,
                memberListController: nil,
                initialUsers: initialUsers(previousQuery, previousResult)
            )
        }

        let memberCount = channel.memberCount
        if memberCount > channel.lastActiveMembers.count {
            var previousResult = Array(memberListController?.members ?? [])
            let previousQuery = (memberListController?.query.filter?.value as? String) ?? ""
            memberListController = makeMemberListControllerForMemberSuggestions(typingMention: typingMention)
            if shouldShowEmptyMentions {
                memberListController = nil
                previousResult = []
            } else {
                memberListController?.synchronize()
            }
            return ChatMessageComposerSuggestionsMentionDataSource(
                collectionView: suggestionsVC.collectionView,
                searchController: userSearchController,
                memberListController: memberListController,
                initialUsers: initialUsers(previousQuery, previousResult)
            )
        }

        let usersCache = searchUsers(
            channel.lastActiveMembers,
            by: typingMention,
            excludingId: currentUserId
        )
        return ChatMessageComposerSuggestionsMentionDataSource(
            collectionView: suggestionsVC.collectionView,
            searchController: userSearchController,
            memberListController: nil,
            initialUsers: usersCache
        )
    }

    /// Provides the mention text for composer text field, when the user selects a mention suggestion.
    open func mentionText(for user: ChatUser) -> String {
        if let name = user.name, !name.isEmpty {
            return name
        } else {
            return user.id
        }
    }

    /// Shows the suggestions view
    open func showSuggestions() {
        if !suggestionsVC.isPresented, let parent = parent {
            parent.addChildViewController(suggestionsVC, targetView: parent.view)

            let suggestionsView = suggestionsVC.view!
            suggestionsView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                suggestionsView.leadingAnchor.pin(equalTo: parent.view.leadingAnchor),
                suggestionsView.trailingAnchor.pin(equalTo: parent.view.trailingAnchor),
                composerView.topAnchor.pin(equalToSystemSpacingBelow: suggestionsView.bottomAnchor),
                suggestionsView.topAnchor.pin(greaterThanOrEqualTo: parent.view.safeAreaLayoutGuide.topAnchor)
            ])
        }
    }

    /// Dismisses the suggestions view.
    open func dismissSuggestions() {
        suggestionsVC.removeFromParent()
        suggestionsVC.view.removeFromSuperview()
    }

    /// The links in the current input text have changed
    /// - Parameter links: The new parsed links from the input text.
    open func didChangeLinks(_ links: [TextLink]) {
        guard channelConfig?.urlEnrichmentEnabled == true else {
            return
        }

        // We only show the link preview if there no other types of attachments.
        guard content.hasOnlyLinkAttachments else {
            dismissLinkPreview()
            return
        }

        /// We only try to display the link preview of the first link.
        guard let link = links.first else {
            dismissLinkPreview()
            return
        }

        enrichUrlDebouncer.execute { [weak self] in
            self?.channelController?.enrichUrl(link.url) { [weak self] result in
                let enrichedUrlText = link.url.absoluteString
                let currentLinks = self?.composerView.inputMessageView.textView.links ?? []
                guard let currentUrlText = currentLinks.first?.url.absoluteString else {
                    return
                }

                // Only show/dismiss enrichment if the current url is still the one
                // that should be shown. Since we currently do not support
                // cancelling previous requests, this is the current optimal solution.
                guard enrichedUrlText == currentUrlText else {
                    return
                }

                switch result {
                case let .success(linkPayload):
                    self?.showLinkPreview(for: linkPayload)
                case .failure:
                    self?.dismissLinkPreview()
                }
            }
        }
    }

    /// Shows the link preview view.
    open func showLinkPreview(for linkPayload: LinkAttachmentPayload) {
        content.skipEnrichUrl = false
        Animate {
            self.composerView.linkPreviewView.isHidden = false
            self.composerView.linkPreviewView.content = .init(linkAttachmentPayload: linkPayload)
        }
    }

    /// Dismisses the link preview view.
    open func dismissLinkPreview() {
        content.skipEnrichUrl = true
        Animate {
            self.composerView.linkPreviewView.isHidden = true
            self.composerView.linkPreviewView.content = nil
        }
    }

    /// Creates and adds an attachment from the given URL to the `content`
    /// - Parameters:
    ///   - url: The URL of the attachment
    ///   - type: The type of the attachment
    open func addAttachmentToContent(
        from url: URL,
        type: AttachmentType
    ) throws {
        try addAttachmentToContent(from: url, type: type, info: [:], extraData: nil)
    }

    /// /// Creates and adds an attachment from the given URL to the `content`
    /// - Parameters:
    ///   - url: The URL of the attachment
    ///   - type: The type of the attachment
    ///   - info: The metadata of the attachment
    open func addAttachmentToContent(
        from url: URL,
        type: AttachmentType,
        info: [LocalAttachmentInfoKey: Any]
    ) throws {
        try addAttachmentToContent(from: url, type: type, info: info, extraData: nil)
    }

    /// Creates and adds an attachment from the given URL to the `content`
    /// - Parameters:
    ///   - url: The URL of the attachment
    ///   - type: The type of the attachment
    ///   - info: The metadata of the attachment
    ///   - extraData: The attachment's extraData
    open func addAttachmentToContent(
        from url: URL,
        type: AttachmentType,
        info: [LocalAttachmentInfoKey: Any],
        extraData: Encodable?
    ) throws {
        guard let chatConfig = channelController?.client.config else {
            log.assertionFailure("Channel controller must be set at this point")
            return
        }

        let maxAttachmentsCount = chatConfig.maxAttachmentCountPerMessage
        guard content.attachments.count < maxAttachmentsCount else {
            throw AttachmentValidationError.maxAttachmentsCountPerMessageExceeded(
                limit: maxAttachmentsCount
            )
        }

        let fileSize = try AttachmentFile(url: url).size
        let maxAttachmentSize = maxAttachmentSize(for: type)
        guard fileSize <= maxAttachmentSize else {
            throw AttachmentValidationError.maxFileSizeExceeded
        }

        var localMetadata = AnyAttachmentLocalMetadata()
        if let image = info[.originalImage] as? UIImage {
            localMetadata.originalResolution = (
                width: Double(image.size.width),
                height: Double(image.size.height)
            )
        }

        switch type {
        case .voiceRecording:
            localMetadata.duration = info[.duration] as? TimeInterval
            localMetadata.waveformData = info[.waveformData] as? [Float]
        default:
            /* No-op */
            break
        }

        let attachment = try AnyAttachmentPayload(
            localFileURL: url,
            attachmentType: type,
            localMetadata: localMetadata,
            extraData: extraData
        )
        content.attachments.append(attachment)
    }

    /// The maximum upload file size depending on the attachment type.
    ///
    /// The max attachment size can be set from the Stream's Dashboard App Settings.
    /// If it is not set, it fallbacks to the deprecated `ChatClientConfig.maxAttachmentSize`.
    /// - Parameter attachmentType: The attachment type that is being uploaded.
    /// - Returns: The file size limit in bytes. The default value is 100MB.
    open func maxAttachmentSize(for attachmentType: AttachmentType) -> Int64 {
        guard let client = channelController?.client else {
            log.assertionFailure("Channel controller must be set at this point")
            return AttachmentValidationError.fileSizeMaxLimitFallback
        }

        let maxAttachmentSize: Int64?
        switch attachmentType {
        case .image:
            maxAttachmentSize = client.appSettings?.imageUploadConfig.sizeLimitInBytes
        default:
            maxAttachmentSize = client.appSettings?.fileUploadConfig.sizeLimitInBytes
        }

        // If no value is set in the dashboard, the size_limit will be nil or zero,
        // so in this case we fallback to the deprecated value.
        guard let maxSize = maxAttachmentSize, maxSize > 0 else {
            return client.config.maxAttachmentSize
        }

        return maxSize
    }

    /// Shows an alert for the error thrown when adding attachment to a composer.
    /// - Parameters:
    ///   - attachmentURL: The attachment's file URL.
    ///   - attachmentType: The type of attachment.
    ///   - error: The thrown error.
    open func handleAddAttachmentError(
        attachmentURL: URL,
        attachmentType: AttachmentType,
        error: Error
    ) {
        switch error {
        case AttachmentValidationError.maxFileSizeExceeded:
            showAttachmentExceedsMaxSizeAlert()
        case let AttachmentValidationError.maxAttachmentsCountPerMessageExceeded(limit):
            showAttachmentsCountExceedingLimitAlert(limit)
        default:
            log.assertionFailure(error.localizedDescription)
        }
    }

    /// Resumes the cooldown if the channel has currently an active cooldown.
    public func resumeCurrentCooldown() {
        if let currentCooldownTime = channelController?.currentCooldownTime() {
            cooldownTracker.start(with: currentCooldownTime)
        }
    }

    // MARK: - UITextViewDelegate

    open func textViewDidChange(_ textView: UITextView) {
        updateShrinkButtonVisibility()

        // This guard removes the possibility of having a loop when updating the `UITextView`.
        // The aim is that `UITextView.text` is always in sync with `Content.text`.
        // With this in place we have bidirectional binding since if we update `Content.text`
        // it will update `UITextView.text` and vice-versa.
        guard textView.text != content.text else { return }

        content.text = textView.text
    }

    open func textView(
        _ textView: UITextView,
        shouldChangeTextIn range: NSRange,
        replacementText text: String
    ) -> Bool {
        guard let maxMessageLength = channelConfig?.maxMessageLength else { return true }
        return textView.text.count + (text.count - range.length) <= maxMessageLength
    }

    open func updateShrinkButtonVisibility() {
        let textView = composerView.inputMessageView.textView
        Animate {
            let leadingViews = self.composerView.leadingContainer.subviews
            let isNotShrinkInputButton: (UIView) -> Bool = { $0 !== self.composerView.shrinkInputButton }
            let isLeadingActionsVisible = leadingViews
                .filter { isNotShrinkInputButton($0) && self.composerView.shrinkInputButton.isHidden }
                .filter(\.isHidden).isEmpty
            self.composerView.shrinkInputButton.isHidden = textView.text.isEmpty || self.content
                .hasCommand || !isLeadingActionsVisible
        }
    }

    // MARK: - UIImagePickerControllerDelegate

    open func imagePickerController(
        _ picker: UIImagePickerController,
        didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
    ) {
        picker.dismiss(animated: true) { [weak self] in
            let urlAndType: (URL, AttachmentType)
            if let imageURL = info[.imageURL] as? URL {
                urlAndType = (imageURL, .image)
            } else if let videoURL = info[.mediaURL] as? URL {
                urlAndType = (videoURL, .video)
            } else if let editedImage = info[.editedImage] as? UIImage,
                      let editedImageURL = try? editedImage.temporaryLocalFileUrl() {
                urlAndType = (editedImageURL, .image)
            } else if let originalImage = info[.originalImage] as? UIImage,
                      let originalImageURL = try? originalImage.temporaryLocalFileUrl() {
                urlAndType = (originalImageURL, .image)
            } else {
                log.error("Unexpected item selected in image picker")
                return
            }

            var localAttachmentInfo: [LocalAttachmentInfoKey: Any] = [:]
            if let originalImage = info[.originalImage] {
                localAttachmentInfo[.originalImage] = originalImage
            }

            do {
                try self?.addAttachmentToContent(
                    from: urlAndType.0,
                    type: urlAndType.1,
                    info: localAttachmentInfo
                )
            } catch {
                self?.handleAddAttachmentError(
                    attachmentURL: urlAndType.0,
                    attachmentType: urlAndType.1,
                    error: error
                )
            }
        }
    }

    // MARK: - UIDocumentPickerViewControllerDelegate

    open func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        for fileURL in urls {
            var attachmentType = AttachmentType(fileExtension: fileURL.pathExtension)
            // Remove this condition when doing: https://stream-io.atlassian.net/browse/CIS-1740
            // This is a fallback right now to treat audios as files until we actually support audios
            if attachmentType == .audio {
                attachmentType = .file
            }
            do {
                try addAttachmentToContent(from: fileURL, type: attachmentType, info: [:])
            } catch {
                handleAddAttachmentError(
                    attachmentURL: fileURL,
                    attachmentType: attachmentType,
                    error: error
                )
                break
            }
        }
    }

    /// Shows an alert saying that attachment's size exceeds the limit.
    open func showAttachmentExceedsMaxSizeAlert() {
        presentAlert(message: L10n.Attachment.maxSizeExceeded)
    }

    /// Shows an alert saying that the max # of attachments per message is exceeded.
    open func showAttachmentsCountExceedingLimitAlert(_ limit: Int) {
        presentAlert(message: L10n.Attachment.maxCountExceeded(limit))
    }

    // MARK: - InputTextViewClipboardAttachmentDelegate

    open func inputTextView(_ inputTextView: InputTextView, didPasteImage image: UIImage) {
        guard let imageUrl = try? image.temporaryLocalFileUrl() else {
            log.error("Could not create temporary local file from image")
            return
        }

        let type: AttachmentType = .image
        do {
            try addAttachmentToContent(
                from: imageUrl,
                type: type,
                info: [.originalImage: image]
            )
        } catch {
            handleAddAttachmentError(
                attachmentURL: imageUrl,
                attachmentType: type,
                error: error
            )
        }
    }

    // MARK: - VoiceRecordingDelegate

    public func voiceRecording(
        _ voiceRecordingVC: VoiceRecordingVC,
        addAttachmentFromLocation location: URL,
        duration: TimeInterval,
        waveformData: [Float]
    ) {
        do {
            try addAttachmentToContent(
                from: location,
                type: .voiceRecording,
                info: [
                    .duration: duration,
                    .waveformData: waveformData
                ]
            )
        } catch {
            handleAddAttachmentError(
                attachmentURL: location,
                attachmentType: .voiceRecording,
                error: error
            )
        }
    }

    public func voiceRecordingPublishMessage(_ voiceRecordingVC: VoiceRecordingVC) {
        publishMessage(sender: composerView.sendButton)
    }

    public func voiceRecordingWillBeginRecording(_ voiceRecordingVC: VoiceRecordingVC) {
        /* No-op */
    }

    public func voiceRecordingDidBeginRecording(_ voiceRecordingVC: VoiceRecordingVC) {
        content.recording()
    }

    public func voiceRecordingDidLockRecording(_ voiceRecordingVC: VoiceRecordingVC) {
        content.recordingLocked()
    }

    public func voiceRecordingDidStopRecording(_ voiceRecordingVC: VoiceRecordingVC) {
        content = .init(
            text: content.text,
            state: .new,
            editingMessage: content.editingMessage,
            quotingMessage: content.quotingMessage,
            threadMessage: content.threadMessage,
            attachments: content.attachments,
            mentionedUsers: content.mentionedUsers,
            command: content.command
        )
    }

    public func voiceRecording(
        _ voiceRecordingVC: VoiceRecordingVC,
        presentFloatingView floatingView: UIView
    ) {
        if let parent = parent {
            floatingView.translatesAutoresizingMaskIntoConstraints = false
            parent.view.addSubview(floatingView)
            NSLayoutConstraint.activate([
                floatingView.leadingAnchor.pin(equalTo: parent.view.leadingAnchor),
                floatingView.trailingAnchor.pin(equalTo: parent.view.trailingAnchor),
                composerView.topAnchor.pin(equalTo: floatingView.bottomAnchor),
                floatingView.topAnchor.pin(greaterThanOrEqualTo: parent.view.safeAreaLayoutGuide.topAnchor)
            ])
        }
    }

    // MARK: - Private

    private func presentAlert(
        title: String? = nil,
        message: String? = nil,
        preferredStyle: UIAlertController.Style = .alert,
        actions: [UIAlertAction] = [
            .init(title: L10n.Alert.Actions.ok, style: .default, handler: { _ in })
        ],
        sourceView: UIView? = nil
    ) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: preferredStyle)
        alert.popoverPresentationController?.sourceView = sourceView
        actions.forEach(alert.addAction)

        present(alert, animated: true)
    }
}

/// searchUsers does an autocomplete search on a list of ChatUser and returns users with `id` or `name` containing the search string
/// results are returned sorted by their edit distance from the searched string
/// distance is calculated using the levenshtein algorithm
/// both search and name strings are normalized (lowercased and by replacing diacritics)
func searchUsers(_ users: [ChatUser], by searchInput: String, excludingId: String? = nil) -> [ChatUser] {
    let normalize: (String) -> String = {
        $0.lowercased().folding(options: .diacriticInsensitive, locale: .current)
    }

    let searchInput = normalize(searchInput)

    let matchingUsers = users.filter { $0.id != excludingId }
        .filter { searchInput.isEmpty || $0.id.contains(searchInput) || (normalize($0.name ?? "").contains(searchInput)) }

    let distance: (ChatUser) -> Int = {
        min($0.id.levenshtein(searchInput), $0.name?.levenshtein(searchInput) ?? 1000)
    }

    return Array(Set(matchingUsers)).sorted {
        /// a tie breaker is needed here to avoid results from flickering
        let dist = distance($0) - distance($1)
        if dist == 0 {
            return $0.id < $1.id
        }
        return dist < 0
    }
}

extension ComposerVC: ChatChannelControllerDelegate {
    public func channelController(
        _ channelController: ChatChannelController,
        didUpdateMessages changes: [ListChange<ChatMessage>]
    ) {
        cooldownTracker.start(with: channelController.currentCooldownTime())
    }
}
