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
            updateContent()
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
        observeSizeChanges()
    }

    override open func updateContent() {
        super.updateContent()
        switch state {
        case .initial:
            textView.text = ""
            textView.placeholderLabel.text = L10n.Composer.Placeholder.message
            imageAttachments = []
            documentAttachments = []
            composerView.quotedMessageView.message = nil
            composerView.sendButton.mode = .new
            composerView.documentAttachmentsView.isHidden = true
            composerView.imageAttachmentsView.isHidden = true
            composerView.quotedMessageView.setAnimatedly(hidden: true)
            composerView.container.topStackView.setAnimatedly(hidden: true)
            composerView.messageInputView.setSlashCommandViews(hidden: true)
            composerView.invalidateIntrinsicContentSize()
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
            composerView.container.topStackView.setAnimatedly(hidden: false)
            composerView.quotedMessageView.setAnimatedly(hidden: false)
            composerView.quotedMessageView.message = messageToQuote
            composerView.invalidateIntrinsicContentSize()
        case let .edit(message):
            composerView.sendButton.mode = .edit
            composerView.titleLabel.text = L10n.Composer.Title.edit
            let image = uiConfig.images.messageComposerEditMessage.tinted(with: uiConfig.colorPalette.inactiveTint)
            composerView.stateIcon.image = image
            composerView.container.topStackView.setAnimatedly(hidden: false)
            textView.text = message.text
            composerView.invalidateIntrinsicContentSize()
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
        composerView.sendButton.addTarget(self, action: #selector(sendMessageToChannel), for: .touchUpInside)
        composerView.shrinkInputButton.addTarget(self, action: #selector(shrinkInput), for: .touchUpInside)
        composerView.commandsButton.addTarget(self, action: #selector(showAvailableCommands), for: .touchUpInside)
        composerView.messageInputView.rightAccessoryButton.addTarget(
            self,
            action: #selector(setInitialState),
            for: .touchUpInside
        )
        composerView.dismissButton.addTarget(self, action: #selector(setInitialState), for: .touchUpInside)
        
        composerView.imageAttachmentsView.didTapRemoveItemButton = { [weak self] index in
            self?.imageAttachments.remove(at: index)
            self?.composerView.imageAttachmentsView.invalidateIntrinsicContentSize()
        }
        
        composerView.documentAttachmentsView.didTapRemoveItemButton = { [weak self] index in
            self?.documentAttachments.remove(at: index)
            self?.composerView.documentAttachmentsView.invalidateIntrinsicContentSize()
        }
    }
    
    public func observeSizeChanges() {
        composerView.addObserver(self, forKeyPath: "safeAreaInsets", options: .new, context: nil)
        textView.addObserver(self, forKeyPath: "contentSize", options: .new, context: nil)
    }
    
    // There are some issues with new-style KVO so that is something that will need attention later.
    override open func observeValue(
        forKeyPath keyPath: String?,
        of object: Any?,
        change: [NSKeyValueChangeKey: Any]?,
        context: UnsafeMutableRawPointer?
    ) {
        if object as AnyObject? === textView, keyPath == "contentSize" {
            composerView.invalidateIntrinsicContentSize()
        } else if object as AnyObject? === composerView, keyPath == "safeAreaInsets" {
            composerView.invalidateIntrinsicContentSize()
        }
    }
    
    // MARK: Actions
    
    @objc func sendMessageToChannel() {
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
                quotedMessageId: quotedMessageId
            )
        } else {
            controller?.createNewMessage(
                text: text,
                pinning: nil,
                attachments: attachments + attachmentSeeds,
                quotedMessageId: quotedMessageId
            )
        }
    }
    
    @objc func showAttachmentsPicker(sender: UIButton) {
        var actionSheet: UIAlertController {
            let actionSheet = UIAlertController(title: nil, message: L10n.Composer.Picker.title, preferredStyle: .actionSheet)
            actionSheet.popoverPresentationController?.sourceView = sender
            
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
        for button in composerView.container.leftStackView.arrangedSubviews where button !== composerView.shrinkInputButton {
            button.setAnimatedly(hidden: !shrinked)
        }
        composerView.shrinkInputButton.setAnimatedly(hidden: shrinked)
    }
    
    @objc func showAvailableCommands() {
        if suggestionsViewController.isPresented {
            dismissSuggestionsViewController()
        } else {
            promptSuggestionIfNeeded(for: "/")
        }
    }
    
    @objc func setInitialState() {
        state = .initial
    }
    
    func updateSendButton() {
        composerView.sendButton.isEnabled = !isEmpty || !imageAttachments.isEmpty || !documentAttachments.isEmpty
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
        composerView.imageAttachmentsView.images = imageAttachments.map(\.preview)
        composerView.imageAttachmentsView.setAnimatedly(hidden: imageAttachments.isEmpty)
        composerView.imageAttachmentsView.invalidateIntrinsicContentSize()
        composerView.invalidateIntrinsicContentSize()
        updateSendButton()
    }
    
    func didUpdateDocumentAttachments() {
        composerView.documentAttachmentsView.documents = documentAttachments.map {
            ($0.preview, $0.localURL.lastPathComponent, $0.size)
        }
        composerView.documentAttachmentsView.setAnimatedly(hidden: documentAttachments.isEmpty)
        composerView.documentAttachmentsView.invalidateIntrinsicContentSize()
        composerView.invalidateIntrinsicContentSize()
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
        isEmpty = textView.text.replacingOccurrences(of: " ", with: "").isEmpty
        replaceTextWithSlashCommandViewIfNeeded()

        updateMentionFlag(with: textView.text as NSString, till: textView.selectedRange.location)

        promptSuggestionIfNeeded(for: textView.text!)
        composerView.invalidateIntrinsicContentSize()
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
