//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

open class MessageComposerViewController<ExtraData: ExtraDataTypes>: ViewController,
    UIConfigProvider,
    UITextViewDelegate,
    UIImagePickerControllerDelegate,
    UIDocumentPickerDelegate,
    UINavigationControllerDelegate {
    // MARK: - Underlying types

    public var userSuggestionSearchController: _ChatUserSearchController<ExtraData>!
    public private(set) lazy var suggestionsViewController: MessageComposerSuggestionsViewController<ExtraData> =
        uiConfig.messageComposer.suggestionsViewController.init()

    public enum State {
        case initial
        case slashCommand(Command)
        case reply(_ChatMessage<ExtraData>)
        case edit(_ChatMessage<ExtraData>)
    }
    
    // MARK: - Properties

    public var controller: _ChatChannelController<ExtraData>?
    
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
        
    public private(set) lazy var composerView: MessageComposerView<ExtraData> = uiConfig
        .messageComposer
        .messageComposerView.init()
        .withoutAutoresizingMaskConstraints
    
    /// Convenience getter for underlying `textView`.
    public var textView: MessageComposerInputTextView<ExtraData> {
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
            composerView.replyView.message = nil
            composerView.sendButton.mode = .new
            composerView.documentAttachmentsView.isHidden = true
            composerView.imageAttachmentsView.isHidden = true
            composerView.replyView.setAnimatedly(hidden: true)
            composerView.container.topStackView.setAnimatedly(hidden: true)
            composerView.messageInputView.setSlashCommandViews(hidden: true)
        case let .slashCommand(command):
            textView.text = ""
            textView.placeholderLabel.text = command.name.firstUppercased
            composerView.messageInputView.setSlashCommandViews(hidden: false)
            composerView.messageInputView.slashCommandView.commandName = command.name.uppercased()
            dismissSuggestionsViewController()
        case let .reply(messageToReply):
            composerView.titleLabel.text = L10n.Composer.Title.reply
            let image = UIImage(named: "replyArrow", in: .streamChatUI)?
                .tinted(with: uiConfig.colorPalette.messageComposerStateIcon)
            composerView.stateIcon.image = image
            composerView.container.topStackView.setAnimatedly(hidden: false)
            composerView.replyView.setAnimatedly(hidden: false)
            composerView.replyView.message = messageToReply
        case let .edit(message):
            composerView.sendButton.mode = .edit
            composerView.titleLabel.text = L10n.Composer.Title.edit
            let image = UIImage(named: "editPencil", in: .streamChatUI)?
                .tinted(with: uiConfig.colorPalette.messageComposerStateIcon)
            composerView.stateIcon.image = image
            composerView.container.topStackView.setAnimatedly(hidden: false)
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
    // swiftlint:disable block_based_kvo
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
    
    @objc func sendMessage() {
        switch state {
        case .initial:
            createNewMessage(text: textView.text)
        case .reply:
            // TODO:
            // 1. Attachments
            // 2. Should be inline reply after backend implementation.
            print("Inline reply sent.")
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
    }
    
    open func createNewMessage(text: String) {
        guard let cid = controller?.cid else { return }
        
        if let threadParentMessage = threadParentMessage {
            let messageController = controller?.client.messageController(
                cid: cid,
                messageId: threadParentMessage.id
            )
            
            messageController?.createNewReply(
                text: text,
                attachments: attachmentSeeds,
                showReplyInChannel: composerView.checkmarkControl.isSelected
            )
        } else {
            controller?.createNewMessage(text: text, attachments: attachmentSeeds)
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
        composerView.attachmentButton.setAnimatedly(hidden: !shrinked)
        composerView.commandsButton.setAnimatedly(hidden: !shrinked)
        composerView.shrinkInputButton.setAnimatedly(hidden: shrinked)
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
    }
    
    // MARK: Suggestions

    public func showSuggestionsViewController(for kind: SuggestionKind, onSelectItem: @escaping ((Int) -> Void)) {
        guard let parent = parent else { return }

        let dataSource: UICollectionViewDataSource
        switch kind {
        case let .command(hints):
            dataSource = SuggestionsCommandDataSource(
                with: hints,
                collectionView: suggestionsViewController.collectionView
            )
        case .mention:
            dataSource = SuggestionsMentionDataSource(
                collectionView: suggestionsViewController.collectionView,
                searchController: userSuggestionSearchController
            )
        }
        suggestionsViewController.didSelectItemAt = onSelectItem
        suggestionsViewController.dataSource = dataSource
        suggestionsViewController.updateContentIfNeeded()

        parent.addChildViewController(suggestionsViewController, targetView: parent.view)
        suggestionsViewController.bottomAnchorView = composerView
    }

    public func dismissSuggestionsViewController() {
        suggestionsViewController.removeFromParent()
        suggestionsViewController.view.removeFromSuperview()
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
    
    open var attachmentSeeds: [_ChatMessageAttachment<ExtraData>.Seed] {
        switch selectedAttachments {
        case .media:
            return imageAttachments.map {
                .init(
                    localURL: $0.localURL,
                    fileName: $0.localURL.lastPathComponent,
                    type: .image,
                    extraData: .defaultValue
                )
            }
        case .documents:
            return documentAttachments.map {
                .init(
                    localURL: $0.localURL,
                    fileName: $0.localURL.lastPathComponent,
                    type: .file,
                    extraData: .defaultValue
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
    
    // MARK: UITextView

    @objc func promptSuggestionIfNeeded(for text: String) {
        if text.trimmingCharacters(in: .whitespacesAndNewlines).contains("@") {
            if let index = (text.range(of: "@")?.upperBound) {
                let textAfterAtSymbol = String(text.suffix(from: index))
                promptMentions(for: textAfterAtSymbol)
            }

        } else if let commands = controller?.channel?.config.commands,
            text.trimmingCharacters(in: .whitespacesAndNewlines).first == "/" {
            prompt(commands: commands, for: text)
        } else {
            dismissSuggestionsViewController()
        }
    }

    func prompt(commands: [Command], for text: String) {
        // Get the command value without the `/`
        let typedCommand = String(text.trimmingCharacters(in: .whitespacesAndNewlines).dropFirst())

        // Set all commands as hints initially
        var commandHints: [Command] = commands

        // Filter commands when user is typing something after `/`
        if !typedCommand.isEmpty {
            commandHints = commands.filter { $0.name.range(of: typedCommand, options: .caseInsensitive) != nil }
        }

        showSuggestionsViewController(
            for: .command(hints: commandHints),
            onSelectItem: { [weak self] commandIndex in
                self?.state = .slashCommand(commandHints[commandIndex])
            }
        )
    }

    func promptMentions(for text: String) {
        userSuggestionSearchController.search(term: text)

        showSuggestionsViewController(
            for: .mention,
            onSelectItem: { [weak self] _ in
                self?.textView.text = self?.textView.text.appending("@ \(text)")
                self?.state = .initial
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
        promptSuggestionIfNeeded(for: textView.text)
        composerView.invalidateIntrinsicContentSize()
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
            let preview = uiConfig.messageComposer.documentPreviews[$0.pathExtension] ??
                uiConfig.messageComposer.fallbackDocumentPreview
            let size = (try? FileManager.default.attributesOfItem(atPath: $0.path)[.size] as? Int64) ?? 0
            return (preview, $0, size)
        }
        
        documentAttachments.append(contentsOf: documentsInfo)
    }
}
