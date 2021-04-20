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
    UIConfigProvider,
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
        uiConfig.messageComposer.suggestionsViewController.init()

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
        
    public private(set) lazy var composerView = uiConfig
        .messageComposer
        .messageComposerView.init()
        .withoutAutoresizingMaskConstraints
    
    /// Convenience getter for underlying `textView`.
    public var textView: _ChatMessageComposerInputTextView<ExtraData> {
        composerView.messageInputView.textView
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

    override open func updateContent() {
        super.updateContent()
        switch state {
        case .initial:
            textView.text = ""
            textView.updateHeightConstraint()
            textView.becomeFirstResponder()
            textView.placeholderLabel.text = L10n.Composer.Placeholder.message
            imageAttachments = []
            documentAttachments = []
            composerView.messageQuoteView.content = nil
            composerView.centerRightContainer.showSubview(composerView.sendButton)
            composerView.centerRightContainer.hideSubview(composerView.editButton)
            composerView.centerContentContainer.hideSubview(composerView.messageQuoteView)
            composerView.container.hideSubview(composerView.topContainer)
            composerView.messageInputView.setSlashCommandViews(hidden: true)
        case let .slashCommand(command):
            textView.text = ""
            textView.placeholderLabel.text = command.name.firstUppercased
            composerView.messageInputView.setSlashCommandViews(hidden: false)
            composerView.messageInputView.slashCommandView.commandName = command.name.uppercased()
            dismissSuggestionsViewController()
        case let .quote(messageToQuote):
            composerView.titleLabel.text = L10n.Composer.Title.reply
            let image = uiConfig.images.messageComposerReplyButton.tinted(with: uiConfig.colorPalette.inactiveTint)
            composerView.stateIcon.image = image
            composerView.container.showSubview(composerView.topContainer)
            composerView.centerContentContainer.showSubview(composerView.messageQuoteView)
            composerView.messageInputView.slashCommandView.isHidden = true
            composerView.messageQuoteView.content = .init(message: messageToQuote, avatarAlignment: .left)
        case let .edit(message):
            composerView.centerRightContainer.showSubview(composerView.editButton)
            composerView.centerRightContainer.hideSubview(composerView.sendButton)
            composerView.titleLabel.text = L10n.Composer.Title.edit
            let image = uiConfig.images.messageComposerEditMessage.tinted(with: uiConfig.colorPalette.inactiveTint)
            composerView.stateIcon.image = image
            composerView.container.showSubview(composerView.topContainer)
            composerView.messageInputView.slashCommandView.isHidden = true
            textView.text = message.text
        }
        
        if let memberCount = controller?.channel?.memberCount,
           threadParentMessage != nil {
            composerView.setCheckmarkView(hidden: false)
            
            if memberCount > 2 {
                composerView.checkmarkControl.label.text = L10n.Composer.Checkmark.channelReply
            } else {
                composerView.checkmarkControl.label.text = L10n.Composer.Checkmark.directMessageReply
            }
        }
    }

    override open func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        dismissSuggestionsViewController()
    }
    
    func setupInputView() {
        view.embed(composerView)

        composerView.messageInputView.textView.delegate = self
        
        composerView.attachmentButton.addTarget(self, action: #selector(showAttachmentsPicker), for: .touchUpInside)
        composerView.sendButton.addTarget(self, action: #selector(sendMessage), for: .touchUpInside)
        composerView.editButton.addTarget(self, action: #selector(sendMessage), for: .touchUpInside)
        composerView.shrinkInputButton.addTarget(self, action: #selector(shrinkInput), for: .touchUpInside)
        composerView.commandsButton.addTarget(self, action: #selector(showAvailableCommands), for: .touchUpInside)
        composerView.messageInputView.rightAccessoryButton.addTarget(
            self,
            action: #selector(resetState),
            for: .touchUpInside
        )
        composerView.dismissButton.addTarget(self, action: #selector(resetState), for: .touchUpInside)
        
        composerView.imageAttachmentsView.didTapRemoveItemButton = { [weak self] index in
            self?.imageAttachments.remove(at: index)
        }
        
        composerView.documentAttachmentsView.didTapRemoveItemButton = { [weak self] index in
            self?.documentAttachments.remove(at: index)
        }
    }
    
    // MARK: Actions
    
    @objc func sendMessage() {
        switch state {
        case .initial:
            createNewMessage(text: textView.text)
        case let .quote(messageToQuote):
            createNewMessage(text: textView.text, quotedMessageId: messageToQuote.id)
        case let .edit(messageToEdit):
            guard let cid = controller?.cid else { return }
            let messageController = controller?.client.messageController(
                cid: cid,
                messageId: messageToEdit.id
            )
            // TODO: Adjust LLC to edit attachments also
            messageController?.editMessage(text: textView.text)
        case let .slashCommand(command):
            createNewMessage(text: "/\(command.name) " + textView.text)
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
                attachments: attachments + attachmentSeeds,
                showReplyInChannel: composerView.checkmarkControl.isSelected,
                quotedMessageId: quotedMessageId,
                mentionedUsers: Array(mentionedUsers.keys)
            )
        } else {
            controller?.createNewMessage(
                text: text,
                pinning: nil,
                attachments: attachments + attachmentSeeds,
                quotedMessageId: quotedMessageId,
                mentionedUsers: Array(mentionedUsers.keys)
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
        for button in composerView.centerLeftContainer.subviews
            where button !== composerView.shrinkInputButton {
            if shrinked {
                composerView.centerLeftContainer.showSubview(button)
            } else {
                composerView.centerLeftContainer.hideSubview(button)
            }
        }
        if shrinked {
            composerView.centerLeftContainer.hideSubview(composerView.shrinkInputButton)
        } else {
            composerView.centerLeftContainer.showSubview(composerView.shrinkInputButton)
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
        composerView.editButton.isEnabled = !isEmpty || !imageAttachments.isEmpty || !documentAttachments.isEmpty
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
    
    public typealias MediaAttachmentInfo = (preview: UIImage, localURL: URL)
    public typealias DocumentAttachmentInfo = (preview: UIImage, localURL: URL, size: Int64)
    
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
    
    open var imageAttachments: [MediaAttachmentInfo] = [] {
        didSet {
            didUpdateImageAttachments()
        }
    }
    
    open var documentAttachments: [DocumentAttachmentInfo] = [] {
        didSet {
            didUpdateDocumentAttachments()
        }
    }
    
    open var attachmentSeeds: [ChatMessageAttachmentSeed] {
        switch selectedAttachments {
        case .media:
            return imageAttachments.map {
                .init(
                    localURL: $0.localURL,
                    type: .image
                )
            }
        case .documents:
            return documentAttachments.map {
                .init(
                    localURL: $0.localURL,
                    type: .file
                )
            }
        case .none:
            return []
        }
    }
    
    func didUpdateImageAttachments() {
        composerView.imageAttachmentsView.content = imageAttachments
            .map {
                ImageAttachmentPreview(image: $0.preview)
            }

        if imageAttachments.isEmpty {
            composerView.centerContentContainer.hideSubview(composerView.imageAttachmentsView)
        } else {
            composerView.centerContentContainer.showSubview(composerView.imageAttachmentsView)
        }
        updateSendButton()
    }
    
    func didUpdateDocumentAttachments() {
        composerView.documentAttachmentsView.documents = documentAttachments.map {
            ($0.preview, $0.localURL.lastPathComponent, $0.size)
        }
        if documentAttachments.isEmpty {
            composerView.centerContentContainer.hideSubview(composerView.documentAttachmentsView)
        } else {
            composerView.centerContentContainer.showSubview(composerView.documentAttachmentsView)
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
            onSelectItem: { [weak self, textView = self.textView] userIndex in
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

                // Add to mentioned users
                self.mentionedUsers[user.id] = user.id
                
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

    /// Dictionary mapping user ids to mention text.
    private(set) var mentionedUsers: [String: String] = [:]

    func replaceTextWithSlashCommandViewIfNeeded() {
        // Extract potential command name from input text
        let potentialCommandNameFromInput = textView.text.trimmingCharacters(in: .whitespacesAndNewlines).dropFirst()

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

        // remove any users where the mention text is no longer present
        mentionedUsers.forEach { userMap in
          if !textView.text.contains(userMap.value) {
            mentionedUsers.removeValue(forKey: userMap.key)
          }
        }
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
            let preview = info[.originalImage] as? UIImage,
            let url = info[UIImagePickerController.InfoKey.imageURL] as? URL
        else { return }
        
        imageAttachments.append((preview, url))
        picker.dismiss(animated: true, completion: nil)
    }
    
    // MARK: - UIDocumentPickerViewControllerDelegate
    
    public func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        let documentsInfo: [DocumentAttachmentInfo] = urls.map {
            let preview = uiConfig.images.documentPreviews[$0.pathExtension] ?? uiConfig.images.fileFallback
            let size = (try? FileManager.default.attributesOfItem(atPath: $0.path)[.size] as? Int64) ?? 0
            return (preview, $0, size)
        }
        
        documentAttachments.append(contentsOf: documentsInfo)
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
