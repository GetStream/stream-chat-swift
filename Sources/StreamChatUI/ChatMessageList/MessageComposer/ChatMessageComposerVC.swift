//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

public protocol _ChatMessageComposerViewControllerDelegate: AnyObject {
    associatedtype ExtraData: ExtraDataTypes

    func messageComposerViewControllerDidSendMessage(_ vc: _ChatMessageComposerVC<ExtraData>)
}

public typealias ChatMessageComposerVC = _ChatMessageComposerVC<NoExtraData>

open class _ChatMessageComposerVC<ExtraData: ExtraDataTypes>: _ViewController,
    ThemeProvider,
    UITextViewDelegate,
    UIImagePickerControllerDelegate,
    UIDocumentPickerDelegate,
    UINavigationControllerDelegate {
    // MARK: - Delegate

    public struct Delegate {
        public var didSendMessage: ((_ChatMessageComposerVC) -> Void)?
    }

    // MARK: - Underlying types

    public var userSuggestionSearchController: _ChatUserSearchController<ExtraData>!
    public private(set) lazy var suggestionsViewController =
        components.messageComposer.suggestionsViewController.init()

    public enum State {
        case initial
        case slashCommand(Command)
        case quote(_ChatMessage<ExtraData>)
        case edit(_ChatMessage<ExtraData>)
    }
    
    // MARK: - Properties

    public var controller: _ChatChannelController<ExtraData>?
    public var delegate: Delegate?
    var shouldShowMentions = false
    
    public var state: State = .initial {
        didSet {
            updateContentIfNeeded()
        }
    }
    
    public var threadParentMessage: _ChatMessage<ExtraData>? {
        didSet {
            updateContentIfNeeded()
        }
    }
    
    var isEmpty: Bool = true {
        didSet {
            setInput(shrinked: isEmpty)
            updateSendButton()
        }
    }
    
    // MARK: - Subviews
        
    public private(set) lazy var composerView = components
        .messageComposer
        .messageComposerView.init()
        .withoutAutoresizingMaskConstraints
    
    /// Convenience getter for underlying `textView`.
    public var inputTextView: ChatInputTextView {
        composerView.messageInputView.inputTextView
    }
    
    public private(set) lazy var imagePicker: UIImagePickerController = {
        let picker = UIImagePickerController()
        picker.mediaTypes = ["public.image"]
        picker.sourceType = .photoLibrary
        picker.delegate = self
        return picker
    }()
    
    public private(set) lazy var documentPicker: UIDocumentPickerViewController = {
        let picker = UIDocumentPickerViewController(documentTypes: ["public.item"], in: .import)
        picker.delegate = self
        picker.allowsMultipleSelection = true
        return picker
    }()
    
    // MARK: Setup

    override open func setUp() {
        super.setUp()
        setupInputView()
    }

    override open func setUpLayout() {
        super.setUpLayout()

        view.embed(composerView)
    }

    override open func updateContent() {
        super.updateContent()
        switch state {
        case .initial:
            inputTextView.text = ""
            inputTextView.becomeFirstResponder()
            inputTextView.placeholderLabel.text = L10n.Composer.Placeholder.message
            imageAttachments = []
            documentAttachments = []
            composerView.messageInputView.messageQuoteView.content = nil
            Animate {
                self.composerView.sendButton.isHidden = false
                self.composerView.confirmButton.isHidden = true
                self.composerView.messageInputView.messageQuoteView.isHidden = true
                self.composerView.headerView.isHidden = true
            }
            composerView.messageInputView.setSlashCommandViews(hidden: true)
        case let .slashCommand(command):
            inputTextView.text = ""
            inputTextView.placeholderLabel.text = command.name.firstUppercased
            composerView.messageInputView.setSlashCommandViews(hidden: false)
            composerView.messageInputView.commandLabel.content = command
            dismissSuggestionsViewController()
        case let .quote(messageToQuote):
            composerView.titleLabel.text = L10n.Composer.Title.reply
            Animate {
                self.composerView.headerView.isHidden = false
                self.composerView.messageInputView.messageQuoteView.isHidden = false
                self.composerView.messageInputView.commandLabel.isHidden = true
            }
            composerView.messageInputView.messageQuoteView.content = .init(message: messageToQuote, avatarAlignment: .left)
        case let .edit(message):
            composerView.titleLabel.text = L10n.Composer.Title.edit
            Animate {
                self.composerView.confirmButton.isHidden = false
                self.composerView.sendButton.isHidden = true
                self.composerView.headerView.isHidden = false
                self.composerView.messageInputView.commandLabel.isHidden = true
            }
            inputTextView.text = message.text
        }
        
        if let memberCount = controller?.channel?.memberCount,
           threadParentMessage != nil {
            Animate {
                self.composerView.bottomContainer.isHidden = false
            }
            
            if memberCount > 2 {
                composerView.checkboxControl.label.text = L10n.Composer.Checkmark.channelReply
            } else {
                composerView.checkboxControl.label.text = L10n.Composer.Checkmark.directMessageReply
            }
        }
    }

    override open func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        dismissSuggestionsViewController()
    }
    
    func setupInputView() {
        composerView.messageInputView.inputTextView.delegate = self
        
        composerView.attachmentButton.addTarget(self, action: #selector(showAttachmentsPicker), for: .touchUpInside)
        composerView.sendButton.addTarget(self, action: #selector(sendMessage), for: .touchUpInside)
        composerView.confirmButton.addTarget(self, action: #selector(sendMessage), for: .touchUpInside)
        composerView.shrinkInputButton.addTarget(self, action: #selector(shrinkInput), for: .touchUpInside)
        composerView.commandsButton.addTarget(self, action: #selector(showAvailableCommands), for: .touchUpInside)
        composerView.messageInputView.clearButton.addTarget(
            self,
            action: #selector(resetState),
            for: .touchUpInside
        )
        composerView.dismissButton.addTarget(self, action: #selector(resetState), for: .touchUpInside)
        
        composerView.messageInputView.imageAttachmentsView.didTapRemoveItemButton = { [weak self] index in
            self?.imageAttachments.remove(at: index)
        }
        
        composerView.messageInputView.documentAttachmentsView.didTapRemoveItemButton = { [weak self] index in
            self?.documentAttachments.remove(at: index)
        }
    }
    
    // MARK: Actions
    
    @objc func sendMessage() {
        switch state {
        case .initial:
            createNewMessage(text: inputTextView.text)
        case let .quote(messageToQuote):
            createNewMessage(text: inputTextView.text, quotedMessageId: messageToQuote.id)
        case let .edit(messageToEdit):
            guard let cid = controller?.cid else { return }
            let messageController = controller?.client.messageController(
                cid: cid,
                messageId: messageToEdit.id
            )
            // TODO: Adjust LLC to edit attachments also
            messageController?.editMessage(text: inputTextView.text)
        case let .slashCommand(command):
            createNewMessage(text: "/\(command.name) " + inputTextView.text)
        }
        
        state = .initial
        delegate?.didSendMessage?(self)
    }
    
    open func createNewMessage(text: String, quotedMessageId: MessageId? = nil, attachments: [AttachmentEnvelope] = []) {
        guard let cid = controller?.cid else { return }
        
        if let threadParentMessage = threadParentMessage {
            let messageController = controller?.client.messageController(
                cid: cid,
                messageId: threadParentMessage.id
            )
            
            messageController?.createNewReply(
                text: text,
                pinning: nil,
                attachments: attachments + attachments,
                showReplyInChannel: composerView.checkboxControl.isSelected,
                quotedMessageId: quotedMessageId
            )
        } else {
            controller?.createNewMessage(
                text: text,
                pinning: nil,
                attachments: attachments + self.attachments,
                quotedMessageId: quotedMessageId
            )
        }
    }
    
    @objc func showAttachmentsPicker() {
        var actionSheet: UIAlertController {
            let actionSheet = UIAlertController(title: nil, message: L10n.Composer.Picker.title, preferredStyle: .actionSheet)
            
            actionSheet.addAction(UIAlertAction(title: L10n.Composer.Picker.file, style: .default, handler: { [weak self] _ in
                guard let self = self else { return }
                self.present(self.documentPicker, animated: true, completion: nil)
            }))
            
            actionSheet.addAction(UIAlertAction(title: L10n.Composer.Picker.image, style: .default, handler: { [weak self] _ in
                guard let self = self else { return }
                self.present(self.imagePicker, animated: true, completion: nil)
            }))
            
            actionSheet.addAction(UIAlertAction(title: L10n.Composer.Picker.cancel, style: .cancel))
            
            return actionSheet
        }
                
        // Right now it's not possible to mix image and file attachments so we are limiting this option.
        switch selectedAttachments {
        case .none:
            present(actionSheet, animated: true, completion: nil)
        case .media:
            present(imagePicker, animated: true, completion: nil)
        case .documents:
            present(documentPicker, animated: true, completion: nil)
        }
    }
    
    @objc func shrinkInput() {
        setInput(shrinked: true)
    }
    
    func setInput(shrinked: Bool) {
        Animate {
            for button in self.composerView.leadingContainer.subviews where button !== self.composerView.shrinkInputButton {
                button.isHidden = !shrinked
            }
            self.composerView.shrinkInputButton.isHidden = shrinked
        }
    }
    
    @objc func showAvailableCommands() {
        if suggestionsViewController.isPresented {
            dismissSuggestionsViewController()
        } else {
            promptSuggestionIfNeeded(for: "/")
        }
    }
    
    @objc func resetState() {
        state = .initial
    }
    
    func updateSendButton() {
        composerView.sendButton.isEnabled = !isEmpty || !imageAttachments.isEmpty || !documentAttachments.isEmpty
        composerView.confirmButton.isEnabled = !isEmpty || !imageAttachments.isEmpty || !documentAttachments.isEmpty
    }
    
    // MARK: Suggestions

    public func showOrUpdateSuggestionsViewController(for kind: SuggestionKind, onSelectItem: @escaping ((Int) -> Void)) {
        guard !suggestionsViewController.isPresented else {
            updateSuggestionsDataIfNeededSource(for: kind, onSelectItem: onSelectItem)
            return
        }

        guard let parent = parent else {
            log.assert(self.parent == nil, "Couldn't find parent on MessageComposerViewController")
            return
        }

        updateSuggestionsDataIfNeededSource(for: kind, onSelectItem: onSelectItem)
        
        parent.addChildViewController(suggestionsViewController, targetView: parent.view)
        suggestionsViewController.bottomAnchorView = composerView
    }

    public func dismissSuggestionsViewController() {
        suggestionsViewController.removeFromParent()
        suggestionsViewController.view.removeFromSuperview()
    }

    public func updateSuggestionsDataIfNeededSource(for kind: SuggestionKind, onSelectItem: @escaping ((Int) -> Void)) {
        let dataSource: UICollectionViewDataSource
        switch kind {
        case let .command(hints):
            dataSource = _ChatMessageComposerSuggestionsCommandDataSource<ExtraData>(
                with: hints,
                collectionView: suggestionsViewController.collectionView
            )
        case .mention:
            dataSource = _ChatMessageComposerSuggestionsMentionDataSource(
                collectionView: suggestionsViewController.collectionView,
                searchController: userSuggestionSearchController
            )
        }
        suggestionsViewController.didSelectItemAt = onSelectItem
        suggestionsViewController.dataSource = dataSource
    }

    // MARK: Attachments

    public enum SelectedAttachments {
        case media, documents
    }
    
    open var selectedAttachments: SelectedAttachments? {
        if imageAttachments.isEmpty, documentAttachments.isEmpty {
            return .none
        } else {
            return imageAttachments.isEmpty ? .documents : .media
        }
    }
    
    open var imageAttachments: [URL] = [] {
        didSet {
            didUpdateImageAttachments()
        }
    }
    
    open var documentAttachments: [URL] = [] {
        didSet {
            didUpdateDocumentAttachments()
        }
    }
    
    open var attachments: [AttachmentEnvelope] {
        switch selectedAttachments {
        case .media:
            return imageAttachments.compactMap(AttachmentEnvelope.init)
        case .documents:
            return documentAttachments.compactMap(AttachmentEnvelope.init)
        case .none:
            return []
        }
    }

    func didUpdateImageAttachments() {
        composerView.messageInputView.imageAttachmentsView.content = imageAttachments.compactMap {
            guard let preview = UIImage(contentsOfFile: $0.path) else { return nil }
            return ImageAttachmentPreview(image: preview)
        }
        Animate {
            self.composerView.messageInputView.imageAttachmentsView.isHidden = self.imageAttachments.isEmpty
        }
        updateSendButton()
    }
    
    func didUpdateDocumentAttachments() {
        composerView.messageInputView.documentAttachmentsView.documents = documentAttachments.map {
            let filePreview = appearance.images.documentPreviews[$0.pathExtension]
            return (
                filePreview ?? appearance.images.fileFallback,
                $0.lastPathComponent,
                $0.attachmentFile?.size ?? 0
            )
        }
        Animate {
            self.composerView.messageInputView.documentAttachmentsView.isHidden = self.documentAttachments.isEmpty
        }
        updateSendButton()
    }
    
    // MARK: Suggestions

    open func promptSuggestionIfNeeded(for text: String) {
        if shouldShowMentions {
            if let index = (text.range(of: "@", options: .backwards)?.upperBound) {
                let textAfterAtSymbol = String(text.suffix(from: index))
                promptMentions(for: textAfterAtSymbol)
            } else {
                promptMentions(for: nil)
            }
        } else if let commands = controller?.channel?.config.commands,
                  text.trimmingCharacters(in: .whitespacesAndNewlines).first == "/" {
            prompt(commands: commands, for: text)
        } else {
            dismissSuggestionsViewController()
        }
    }

    private func prompt(commands: [Command], for text: String) {
        // Get the command value without the `/`
        let typedCommand = String(text.trimmingCharacters(in: .whitespacesAndNewlines).dropFirst())

        // Set all commands as hints initially
        var commandHints: [Command] = commands

        // Filter commands when user is typing something after `/`
        if !typedCommand.isEmpty {
            commandHints = commands.filter { $0.name.range(of: typedCommand, options: .caseInsensitive) != nil }
        }

        showOrUpdateSuggestionsViewController(
            for: .command(hints: commandHints),
            onSelectItem: { [weak self] commandIndex in
                self?.state = .slashCommand(commandHints[commandIndex])
            }
        )
    }

    private func promptMentions(for text: String?) {
        userSuggestionSearchController.search(term: text)
        showOrUpdateSuggestionsViewController(
            for: .mention,
            onSelectItem: { [weak self, textView = self.inputTextView] userIndex in
                guard let self = self else { return }

                let user = self.userSuggestionSearchController.users[userIndex]
                let cursorPosition = textView.selectedRange

                let atRange = (textView.textStorage.string as NSString)
                    .rangeOfCharacter(
                        from: CharacterSet(charactersIn: "@"),
                        options: .backwards,
                        range: NSRange(location: 0, length: cursorPosition.location)
                    )

                let oldPositionTillTheEnd = (textView.text as NSString).length - cursorPosition.location

                textView.textStorage.replaceCharacters(
                    in: NSRange(location: atRange.location, length: cursorPosition.location - atRange.location),
                    with: "@\(user.id) "
                )

                let newPosition = (textView.text as NSString).length - oldPositionTillTheEnd
                textView.selectedRange = NSRange(location: newPosition, length: 0)
                
                // Trigger layout recalculation on `MessageComposerInputTextView`.
                // When we change text with `textStorage.replaceCharacters` method `textViewDidChange` is not fired
                // so height of the textView is not recalculated.
                // It's possible to observe `NSTextStorage.didProccessEditingNotification` but it's
                // not safe to perform operations on textView after this call cause text is not yet updated.
                let text = textView.text
                textView.text = text
                
                self.dismissSuggestionsViewController()
            }
        )
    }

    func replaceTextWithSlashCommandViewIfNeeded() {
        // Extract potential command name from input text
        let potentialCommandNameFromInput = inputTextView.text
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .dropFirst()

        // Condition to check if input text matches any of the available commands
        let commandMatches: ((Command) -> Bool) = { command in command.name == potentialCommandNameFromInput }

        // Update state if command detected
        if let command = controller?.channel?.config.commands?.first(where: commandMatches) {
            state = .slashCommand(command)
        }
    }

    // MARK: - UITextViewDelegate

    public func textViewDidChange(_ textView: UITextView) {
        controller?.sendKeystrokeEvent()

        isEmpty = textView.text.replacingOccurrences(of: " ", with: "").isEmpty
        replaceTextWithSlashCommandViewIfNeeded()

        updateMentionFlag(with: textView.text as NSString, till: textView.selectedRange.location)

        promptSuggestionIfNeeded(for: textView.text!)
    }

    func updateMentionFlag(with text: NSString, till caret: Int) {
        let firstBreakPoint = text.rangeOfCharacter(
            from: CharacterSet(charactersIn: " @"),
            options: .backwards,
            range: NSRange(location: 0, length: caret)
        )
        if firstBreakPoint.location != NSNotFound {
            shouldShowMentions = text.substring(with: firstBreakPoint) == "@"
        } else {
            shouldShowMentions = false
        }
    }

    // MARK: - UIImagePickerControllerDelegate
    
    public func imagePickerController(
        _ picker: UIImagePickerController,
        didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
    ) {
        guard
            let url = info[UIImagePickerController.InfoKey.imageURL] as? URL
        else { return }

        imageAttachments.append(url)
        picker.dismiss(animated: true, completion: nil)
    }
    
    // MARK: - UIDocumentPickerViewControllerDelegate
    
    public func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        documentAttachments.append(contentsOf: urls)
    }
}

public extension _ChatMessageComposerVC.Delegate {
    static func wrap<T: _ChatMessageComposerViewControllerDelegate>(
        _ delegate: T
    ) -> _ChatMessageComposerVC.Delegate where T.ExtraData == ExtraData {
        _ChatMessageComposerVC.Delegate(
            didSendMessage: { [weak delegate] in delegate?.messageComposerViewControllerDidSendMessage($0) }
        )
    }
}
