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
    
    public enum State {
        case initial
        case slashCommand(Command)
        case reply(_ChatMessage<ExtraData>)
        case edit(_ChatMessage<ExtraData>)
    }
    
    // MARK: - Properties

    var controller: _ChatChannelController<ExtraData>?
    weak var suggestionsPresenter: SuggestionsViewControllerPresenter?
    
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
            composerView.attachmentButton.isHidden = !isEmpty
            composerView.commandsButton.isHidden = !isEmpty
            composerView.shrinkInputButton.isHidden = isEmpty
            composerView.sendButton.isEnabled = !isEmpty
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
        picker.mediaTypes = ["public.image", "public.movie"]
        picker.sourceType = .photoLibrary
        picker.delegate = self
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
            composerView.replyView.message = nil
            composerView.sendButton.mode = .new
            composerView.attachmentsView.isHidden = true
            composerView.replyView.isHidden = true
            composerView.container.topStackView.isHidden = true
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
            composerView.container.topStackView.isHidden = false
            composerView.replyView.isHidden = false
            composerView.replyView.message = messageToReply
        case let .edit(message):
            composerView.sendButton.mode = .edit
            composerView.titleLabel.text = L10n.Composer.Title.edit
            let image = UIImage(named: "editPencil", in: .streamChatUI)?
                .tinted(with: uiConfig.colorPalette.messageComposerStateIcon)
            composerView.stateIcon.image = image
            composerView.container.topStackView.isHidden = false
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
        
        composerView.attachmentButton.addTarget(self, action: #selector(showImagePicker), for: .touchUpInside)
        composerView.sendButton.addTarget(self, action: #selector(sendMessage), for: .touchUpInside)
        composerView.shrinkInputButton.addTarget(self, action: #selector(shrinkInput), for: .touchUpInside)
        composerView.commandsButton.addTarget(self, action: #selector(showAvailableCommands), for: .touchUpInside)
        composerView.messageInputView.rightAccessoryButton.addTarget(
            self,
            action: #selector(resetState),
            for: .touchUpInside
        )
        composerView.dismissButton.addTarget(self, action: #selector(resetState), for: .touchUpInside)
        composerView.attachmentsView.didTapRemoveItemButton = { [weak self] index in self?.imageAttachments.remove(at: index) }
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
    
    // MARK: Button actions
    
    @objc func sendMessage() {
        guard let text = composerView.messageInputView.textView.text,
            !text.replacingOccurrences(of: " ", with: "").isEmpty
        else { return }
        
        switch state {
        case .initial:
            // TODO: Attachments
            createNewMessage(text: text)
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
            messageController?.editMessage(text: text)
        case let .slashCommand(command):
            createNewMessage(text: "/\(command.name) " + text)
        }
        
        state = .initial
    }
    
    func createNewMessage(text: String) {
        guard let cid = controller?.cid else { return }
        
        if let threadParentMessage = threadParentMessage {
            let messageController = controller?.client.messageController(
                cid: cid,
                messageId: threadParentMessage.id
            )
            
            messageController?.createNewReply(
                text: text,
                showReplyInChannel: composerView.checkmarkControl.isSelected
            )
        } else {
            controller?.createNewMessage(text: text)
        }
    }
    
    @objc func showImagePicker() {
        present(imagePicker, animated: true, completion: nil)
    }
    
    @objc func shrinkInput() {
        composerView.attachmentButton.isHidden = false
        composerView.commandsButton.isHidden = false
        composerView.shrinkInputButton.isHidden = true
    }
    
    @objc func showAvailableCommands() {
        if suggestionsPresenter?.isSuggestionControllerPresented ?? false {
            dismissSuggestionsViewController()
        } else {
            promptSuggestionIfNeeded(for: "/")
        }
    }
    
    @objc func resetState() {
        state = .initial
    }
    
    // MARK: Suggestions
    
    func showSuggestionsViewController(
        with state: SuggestionsViewControllerState,
        onSelectItem: ((Int) -> Void)
    ) {
        suggestionsPresenter?.showSuggestionsViewController(with: state, onSelectItem: onSelectItem)
    }

    func dismissSuggestionsViewController() {
        suggestionsPresenter?.dismissSuggestionsViewController()
    }

    // MARK: Attachments
    
    var imageAttachments: [UIImage] = [] {
        didSet {
            didUpdateImageAttachments()
        }
    }
    
    func didUpdateImageAttachments() {
        composerView.attachmentsView.previews = imageAttachments
        composerView.attachmentsView.isHidden = imageAttachments.isEmpty
        composerView.invalidateIntrinsicContentSize()
    }
    
    // MARK: UITextView
    
    @objc func promptSuggestionIfNeeded(for text: String) {
        // Check if first symbol is `/` and if there are available commands in `ChatConfig`.
        guard text.trimmingCharacters(in: .whitespacesAndNewlines).first == "/",
            let commands = controller?.channel?.config.commands
        else {
            dismissSuggestionsViewController()
            return
        }
        
        // Get the command value without the `/`
        let typedCommand = String(text.trimmingCharacters(in: .whitespacesAndNewlines).dropFirst())
        
        // Set all commands as hints initially
        var commandHints: [Command] = commands
        
        // Filter commands when user is typing something after `/`
        if !typedCommand.isEmpty {
            commandHints = commands.filter { $0.name.range(of: typedCommand, options: .caseInsensitive) != nil }
        }

        showSuggestionsViewController(
            with: .commands(commandHints),
            onSelectItem: { [weak self] index in
                self?.state = .slashCommand(commandHints[index])
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
        guard let selectedImage = info[.originalImage] as? UIImage else { return }
        
        imageAttachments.append(selectedImage)
        picker.dismiss(animated: true, completion: nil)
    }
}
