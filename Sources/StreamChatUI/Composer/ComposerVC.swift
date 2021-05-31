//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// The delegate of the ComposerVC that notifies composer events.
public protocol ComposerVCDelegate: AnyObject {
    func composerDidCreateNewMessage()
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
}

/// A view controller that manages the composer view.
public typealias ComposerVC = _ComposerVC<NoExtraData>

/// A view controller that manages the composer view.
open class _ComposerVC<ExtraData: ExtraDataTypes>: _ViewController,
    ThemeProvider,
    UITextViewDelegate,
    UIImagePickerControllerDelegate,
    UIDocumentPickerDelegate,
    UINavigationControllerDelegate {
    /// The content of the composer.
    public struct Content {
        /// The text of the input text view.
        public var text: String
        /// The state of the composer.
        public var state: ComposerState
        /// The editing message if the composer is currently editing a message.
        public let editingMessage: _ChatMessage<ExtraData>?
        /// The quoting message if the composer is currently quoting a message.
        public let quotingMessage: _ChatMessage<ExtraData>?
        /// The thread parent message if the composer is currently replying in a thread.
        public let threadMessage: _ChatMessage<ExtraData>?
        /// The attachments of the message.
        public var attachments: [AnyAttachmentPayload]
        /// The command of the message.
        public var command: Command?

        /// A boolean that checks if the message contains any content.
        public var isEmpty: Bool {
            text.isEmpty && attachments.isEmpty
        }

        /// A boolean that check if the composer is replying in a thread
        public var isInsideThread: Bool { threadMessage != nil }
        /// A boolean that checks if the composer recognised already a command.
        public var hasCommand: Bool { command != nil }

        public init(
            text: String,
            state: ComposerState,
            editingMessage: _ChatMessage<ExtraData>?,
            quotingMessage: _ChatMessage<ExtraData>?,
            threadMessage: _ChatMessage<ExtraData>?,
            attachments: [AnyAttachmentPayload],
            command: Command?
        ) {
            self.text = text
            self.state = state
            self.editingMessage = editingMessage
            self.quotingMessage = quotingMessage
            self.threadMessage = threadMessage
            self.attachments = attachments
            self.command = command
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
                command: nil
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
                command: nil
            )
        }

        /// Sets the content state to editing a message.
        ///
        /// - Parameter message: The message that the composer will edit.
        public mutating func editMessage(_ message: _ChatMessage<ExtraData>) {
            self = .init(
                text: message.text,
                state: .edit,
                editingMessage: message,
                quotingMessage: nil,
                threadMessage: threadMessage,
                attachments: attachments,
                command: command
            )
        }

        /// Sets the content state to quoting a message.
        ///
        /// - Parameter message: The message that the composer will quote.
        public mutating func quoteMessage(_ message: _ChatMessage<ExtraData>) {
            self = .init(
                text: text,
                state: .quote,
                editingMessage: nil,
                quotingMessage: message,
                threadMessage: threadMessage,
                attachments: attachments,
                command: command
            )
        }

        /// Sets the content state to replying to a thread message.
        ///
        /// - Parameter message: The message that belongs to the thread.
        public mutating func threadMessage(_ message: _ChatMessage<ExtraData>) {
            self = .init(
                text: text,
                state: state,
                editingMessage: editingMessage,
                quotingMessage: quotingMessage,
                threadMessage: message,
                attachments: attachments,
                command: command
            )
        }
    }

    /// The content of the composer.
    public var content: Content = .initial() {
        didSet {
            updateContentIfNeeded()
        }
    }

    /// The delegate of the ComposerVC that notifies composer events.
    open weak var delegate: ComposerVCDelegate?

    /// A symbol that is used to recognise when the user is mentioning a user.
    open var mentionSymbol = "@"

    /// A symbol that is used to recognise when the user is typing a command.
    open var commandSymbol = "/"

    /// A controller to search users and that is used to populate the mention suggestions.
    open var userSearchController: _ChatUserSearchController<ExtraData>!

    /// A controller that manages the channel that the composer is creating content for.
    open var channelController: _ChatChannelController<ExtraData>?

    /// The channel config. If it's a new channel, an empty config should be created. (Not yet supported right now)
    public var channelConfig: ChannelConfig? {
        channelController?.channel?.config
    }

    /// The view of the composer.
    open private(set) lazy var composerView: _ComposerView<ExtraData> = components
        .messageComposerView.init()
        .withoutAutoresizingMaskConstraints

    /// The view controller that shows the suggestions when the user is typing.
    open private(set) lazy var suggestionsVC: _ChatSuggestionsViewController<ExtraData> = components
        .suggestionsVC
        .init()
    
    /// The view controller that shows the suggestions when the user is typing.
    open private(set) lazy var attachmentsVC: _AttachmentsPreviewVC<ExtraData> = components
        .messageComposerAttachmentsVC
        .init()

    /// The view controller for selecting image attachments.
    open private(set) lazy var imagePickerVC: UIViewController = {
        let picker = UIImagePickerController()
        picker.mediaTypes = ["public.image"]
        picker.sourceType = .photoLibrary
        picker.delegate = self
        return picker
    }()

    /// The view controller for selecting file attachments.
    open private(set) lazy var filePickerVC: UIViewController = {
        let picker = UIDocumentPickerViewController(documentTypes: ["public.item"], in: .import)
        picker.delegate = self
        picker.allowsMultipleSelection = true
        return picker
    }()
    
    open var selectedAttachmentType: AttachmentType?

    public func setDelegate(_ delegate: ComposerVCDelegate) {
        self.delegate = delegate
    }

    override open func setUp() {
        super.setUp()

        composerView.inputMessageView.textView.delegate = self

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
        
        setupAttachmentsView()
    }

    override open func setUpLayout() {
        super.setUpLayout()

        view.addSubview(composerView)
        composerView.pin(to: view)
    }

    override open func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        dismissSuggestions()
    }

    override open func updateContent() {
        super.updateContent()

        composerView.inputMessageView.textView.text = content.text

        if !content.isEmpty && channelConfig?.typingEventsEnabled == true {
            channelController?.sendKeystrokeEvent()
        }

        switch content.state {
        case .new:
            composerView.inputMessageView.textView.placeholderLabel.text = L10n.Composer.Placeholder.message
            Animate {
                self.composerView.confirmButton.isHidden = true
                self.composerView.sendButton.isHidden = false
                self.composerView.headerView.isHidden = true
            }
        case .quote:
            composerView.titleLabel.text = L10n.Composer.Title.reply
            Animate {
                self.composerView.headerView.isHidden = false
            }
        case .edit:
            composerView.titleLabel.text = L10n.Composer.Title.edit
            Animate {
                self.composerView.confirmButton.isHidden = false
                self.composerView.sendButton.isHidden = true
                self.composerView.headerView.isHidden = false
            }
        default:
            log.warning("The composer state \(content.state.description) was not handled.")
        }

        composerView.sendButton.isEnabled = !content.isEmpty
        composerView.confirmButton.isEnabled = !content.isEmpty

        let isAttachmentButtonHidden = !content.isEmpty || channelConfig?.uploadsEnabled == false
        let isCommandsButtonHidden = !content.isEmpty
        let isShrinkInputButtonHidden = content.isEmpty
        Animate {
            self.composerView.attachmentButton.isHidden = isAttachmentButtonHidden
            self.composerView.commandsButton.isHidden = isCommandsButtonHidden
            self.composerView.shrinkInputButton.isHidden = isShrinkInputButtonHidden
        }

        composerView.inputMessageView.content = .init(
            quotingMessage: content.quotingMessage,
            command: content.command
        )
        
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

        if content.isInsideThread {
            if channelController?.channel?.isDirectMessageChannel == true {
                composerView.checkboxControl.label.text = L10n.Composer.Checkmark.directMessageReply
            } else {
                composerView.checkboxControl.label.text = L10n.Composer.Checkmark.channelReply
            }
        }
        Animate {
            self.composerView.bottomContainer.isHidden = !self.content.isInsideThread
        }

        if let typingCommand = typingCommand(in: composerView.inputMessageView.textView) {
            showCommandSuggestions(for: typingCommand)
            return
        }

        if let (typingMention, mentionRange) = typingMention(in: composerView.inputMessageView.textView) {
            showMentionSuggestions(for: typingMention, mentionRange: mentionRange)
            return
        }

        dismissSuggestions()
    }
    
    open func setupAttachmentsView() {
        addChildViewController(attachmentsVC, embedIn: composerView.inputMessageView.attachmentsViewContainer)
        attachmentsVC.didTapRemoveItemButton = { [weak self] index in
            self?.content.attachments.remove(at: index)
        }
    }
    
    // MARK: - Actions
    
    @objc open func publishMessage(sender: UIButton) {
        let text: String
        if let command = content.command {
            text = "/\(command.name) " + content.text
        } else {
            text = content.text
        }

        if let editingMessage = content.editingMessage {
            editMessage(withId: editingMessage.id, newText: text)
        } else {
            createNewMessage(text: text)
        }

        content.clear()
    }
    
    @objc open func showAttachmentsPicker(sender: UIButton) {
        var actionSheet: UIAlertController {
            let actionSheet: UIAlertController = UIAlertController(
                title: nil,
                message: L10n.Composer.Picker.title,
                preferredStyle: .actionSheet
            )
            actionSheet.popoverPresentationController?.sourceView = sender

            let showFilePickerAction = UIAlertAction(
                title: L10n.Composer.Picker.file,
                style: .default,
                handler: { [weak self] _ in
                    guard let self = self else { return }
                    self.selectedAttachmentType = .file
                    self.present(self.filePickerVC, animated: true, completion: nil)
                }
            )
            let showImagePickerAction = UIAlertAction(
                title: L10n.Composer.Picker.image,
                style: .default,
                handler: { [weak self] _ in
                    guard let self = self else { return }
                    self.selectedAttachmentType = .image
                    self.present(self.imagePickerVC, animated: true, completion: nil)
                }
            )
            let cancelAction = UIAlertAction(title: L10n.Composer.Picker.cancel, style: .cancel)

            [showFilePickerAction, showImagePickerAction, cancelAction].forEach {
                actionSheet.addAction($0)
            }

            return actionSheet
        }
        
        // The UI doesn't support mix of image and file attachments so we are limiting this option.
        // Files in the message composer are scrolling vertically and images horizontally.
        // There is no techical limitation for multiple attachment types.
        if content.attachments.isEmpty {
            selectedAttachmentType = nil
            present(actionSheet, animated: true, completion: nil)
        } else if let attachmentType = selectedAttachmentType {
            switch attachmentType {
            case .image:
                present(imagePickerVC, animated: true, completion: nil)
            case .file:
                present(filePickerVC, animated: true, completion: nil)
            default:
                log.error("Error in handling `selectedAttachmentType`. Unexpected attachment type.")
            }
        } else {
            log.error("Error in handling `selectedAttachmentType`. Missing attachment type.")
        }
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
            if self.channelController?.channel?.config.uploadsEnabled == false {
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
        defer {
            delegate?.composerDidCreateNewMessage()
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
                showReplyInChannel: composerView.checkboxControl.isSelected,
                quotedMessageId: content.quotingMessage?.id
            )
            return
        }

        channelController?.createNewMessage(
            text: text,
            pinning: nil,
            attachments: content.attachments,
            quotedMessageId: content.quotingMessage?.id
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
        // TODO: Adjust LLC to edit attachments also
        messageController?.editMessage(text: newText)
    }

    /// Returns a potential user mention in case the user is currently typing a username.
    /// - Parameter textView: The text view of the message input view where the user is typing.
    /// - Returns: A tuple with the potential user mention and the position of the mention so it can be autocompleted.
    open func typingMention(in textView: UITextView) -> (String, NSRange)? {
        let text = textView.text as NSString
        let caretLocation = textView.selectedRange.location
        let firstMentionSymbolBeforeCaret = text.rangeOfCharacter(
            from: CharacterSet(charactersIn: mentionSymbol),
            options: .backwards,
            range: NSRange(location: 0, length: caretLocation)
        )
        guard firstMentionSymbolBeforeCaret.location != NSNotFound else {
            return nil
        }

        let charIndexBeforeMentionSymbol = firstMentionSymbolBeforeCaret.lowerBound - 1
        let charRangeBeforeMentionSymbol = NSRange(location: charIndexBeforeMentionSymbol, length: 1)
        if charIndexBeforeMentionSymbol >= 0, text.substring(with: charRangeBeforeMentionSymbol) != " " {
            return nil
        }
        
        let mentionStart = firstMentionSymbolBeforeCaret.upperBound
        let mentionEnd = caretLocation
        guard mentionEnd >= mentionStart else {
            return nil
        }

        let mentionRange = NSRange(location: mentionStart, length: mentionEnd - mentionStart)
        let mention = text.substring(with: mentionRange)
        guard !mention.contains(" ") else {
            return nil
        }

        return (mention, mentionRange)
    }

    /// Returns a potential command in case the user is currently typing a command.
    /// - Parameter textView: The text view of the message input view where the user is typing.
    /// - Returns: A string of the corresponding potential command.
    open func typingCommand(in textView: UITextView) -> String? {
        guard let text = textView.text else { return nil }

        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedText.first == Character(commandSymbol) else { return nil }

        let trimmedTextWithoutSymbol = trimmedText.dropFirst()
        guard let potentialCommand = trimmedTextWithoutSymbol.split(separator: " ").first else {
            return String(trimmedTextWithoutSymbol)
        }

        return String(potentialCommand)
    }

    /// Shows the command suggestions for the potential command the current user is typing.
    /// - Parameter typingCommand: The potential command that the current user is typing.
    open func showCommandSuggestions(for typingCommand: String) {
        let availableCommands = channelController?.channel?.config.commands ?? []
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
            var newContent = content
            newContent.command = foundCommand
            newContent.text = ""
            content = newContent

            dismissSuggestions()
            return
        }

        let dataSource = _ChatMessageComposerSuggestionsCommandDataSource<ExtraData>(
            with: commandHints,
            collectionView: suggestionsVC.collectionView
        )
        suggestionsVC.dataSource = dataSource
        suggestionsVC.didSelectItemAt = { [weak self] commandIndex in
            guard var newContent = self?.content else { return }
            newContent.command = commandHints[commandIndex]
            newContent.text = ""
            self?.content = newContent

            self?.dismissSuggestions()
        }

        showSuggestions()
    }

    /// Shows the mention suggestions for the potential mention the current user is typing.
    /// - Parameters:
    ///   - typingMention: The potential user mention the current user is typing.
    ///   - mentionRange: The position where the current user is typing a mention to it can be replaced with the suggestion.
    open func showMentionSuggestions(for typingMention: String, mentionRange: NSRange) {
        userSearchController.search(term: typingMention)
        let dataSource = _ChatMessageComposerSuggestionsMentionDataSource(
            collectionView: suggestionsVC.collectionView,
            searchController: userSearchController
        )
        suggestionsVC.dataSource = dataSource
        suggestionsVC.didSelectItemAt = { [weak self] userIndex in
            guard let self = self else { return }

            let textView = self.composerView.inputMessageView.textView
            let user = self.userSearchController.users[userIndex]

            let text = textView.text as NSString
            let newText = text.replacingCharacters(in: mentionRange, with: user.id)
            self.content.text = newText

            let caretLocation = textView.selectedRange.location
            let newCaretLocation = caretLocation + (user.id.count - typingMention.count)
            textView.selectedRange = NSRange(location: newCaretLocation, length: 0)

            self.dismissSuggestions()
        }

        showSuggestions()
    }

    /// Shows the suggestions view
    open func showSuggestions() {
        if !suggestionsVC.isPresented, let parent = parent {
            parent.addChildViewController(suggestionsVC, targetView: parent.view)
            suggestionsVC.bottomAnchorView = composerView
        }
    }

    /// Dismisses the suggestions view.
    open func dismissSuggestions() {
        suggestionsVC.removeFromParent()
        suggestionsVC.view.removeFromSuperview()
    }

    // MARK: - UITextViewDelegate

    open func textViewDidChange(_ textView: UITextView) {
        // This guard removes the possibility of having a loop when updating the `UITextView`.
        // The aim is that `UITextView.text` is always in sync with `Content.text`.
        // With this in place we have bidirectional binding since if we update `Content.text`
        // it will update `UITextView.text` and vice-versa.
        guard textView.text != content.text else { return }

        content.text = textView.text
    }

    // MARK: - UIImagePickerControllerDelegate
    
    open func imagePickerController(
        _ picker: UIImagePickerController,
        didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
    ) {
        guard let url = info[UIImagePickerController.InfoKey.imageURL] as? URL else { return }
        
        do {
            let attachment = try AnyAttachmentPayload(localFileURL: url, attachmentType: .image)
            content.attachments.append(attachment)
        } catch {
            log.assertionFailure(error.localizedDescription)
        }
        picker.dismiss(animated: true, completion: nil)
    }
    
    // MARK: - UIDocumentPickerViewControllerDelegate
    
    open func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        content.attachments.append(contentsOf: urls.compactMap {
            do {
                return try AnyAttachmentPayload(localFileURL: $0, attachmentType: .file)
            } catch {
                log.assertionFailure(error.localizedDescription)
                return nil
            }
        })
    }
}
