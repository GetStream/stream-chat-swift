//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChat
import UIKit
import SwiftUI

extension Notification.Name {
    public static let sendOneWalletTapAction = Notification.Name("kStreamChatOneWalletTapAction")
    public static let sendOneAction = Notification.Name("kStreamChatSendOneAction")
    public static let sendRedPacketTapAction = Notification.Name("kStreamChatSendRedPacketTapAction")
    public static let sendOneWallet = Notification.Name("kTimelessWalletsendOneWallet")
    public static let sendRedPacket = Notification.Name("kTimelessWalletsendRedPacket")
    public static let pickUpRedPacket = Notification.Name("kStreamChatPickUpRedPacket")
    public static let showSnackBar = Notification.Name("kStreamshowSnackBar")
    public static let payRequestTapAction = Notification.Name("kPayRequestTapAction")
}

/// The possible errors that can occur in attachment validation
public enum AttachmentValidationError: Error {
    /// The size of the attachment exceeds the max file size
    case maxFileSizeExceeded
    
    /// The number of attachments reached the limit.
    case maxAttachmentsCountPerMessageExceeded(limit: Int)
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
open class ComposerVC: _ViewController,
    ThemeProvider,
    UITextViewDelegate,
    UIImagePickerControllerDelegate,
    UIDocumentPickerDelegate,
    UINavigationControllerDelegate,
    InputTextViewClipboardAttachmentDelegate {

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

        /// A boolean that checks if the message contains any content.
        public var isEmpty: Bool {
            text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && attachments.isEmpty
        }

        /// A boolean that checks if the composer is replying in a thread
        public var isInsideThread: Bool { threadMessage != nil }
        /// A boolean that checks if the composer recognised already a command.
        public var hasCommand: Bool { command != nil }

        public init(
            text: String,
            state: ComposerState,
            editingMessage: ChatMessage?,
            quotingMessage: ChatMessage?,
            threadMessage: ChatMessage?,
            attachments: [AnyAttachmentPayload],
            mentionedUsers: Set<ChatUser>,
            command: Command?
        ) {
            self.text = text
            self.state = state
            self.editingMessage = editingMessage
            self.quotingMessage = quotingMessage
            self.threadMessage = threadMessage
            self.attachments = attachments
            self.mentionedUsers = mentionedUsers
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
                mentionedUsers: [],
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
                mentionedUsers: [],
                command: nil
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
                attachments: attachments,
                mentionedUsers: message.mentionedUsers,
                command: command
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
                command: command
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
        channelConfig?.uploadsEnabled == true
    }

    /// When enabled mentions search users across the entire app instead of searching
    open private(set) lazy var mentionAllAppUsers: Bool = components.mentionAllAppUsers

    /// A controller to search users and that is used to populate the mention suggestions.
    open var userSearchController: ChatUserSearchController!

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

    /// The view of the composer.
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

    /// The view controller for selecting file attachments.
    open private(set) lazy var filePickerVC: UIViewController = {
        let picker = UIDocumentPickerViewController(documentTypes: ["public.item"], in: .import)
        picker.delegate = self
        picker.allowsMultipleSelection = true
        return picker
    }()

    private(set) lazy var tempInputAccessaryView: UIView = {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 44))
        view.backgroundColor = .red
        return view
    }()

    private var walletInputView: WalletQuickInputViewController?
    private var menuController: ChatMenuViewController?
    private var isMenuShowing = false
    private var keyboardHeight = UIScreen.main.bounds.height * 0.33

    override open func setUp() {
        super.setUp()

        composerView.inputMessageView.textView.delegate = self
        // Set the delegate for handling the pasting of UIImages in the text view
        composerView.inputMessageView.textView.clipboardAttachmentDelegate = self
        self.composerView.toolKitView.isHidden = true
        composerView.inputMessageView.textView.handleToolkitToggle = { [weak self] isHidden in
            guard let weakSelf = self else {
                return
            }
            weakSelf.composerView.toolKitView.isHidden = isHidden
        }

        composerView.inputMessageView.sendButton.addTarget(self, action: #selector(publishMessage), for: .touchUpInside)
        composerView.confirmButton.addTarget(self, action: #selector(publishMessage), for: .touchUpInside)
        composerView.shrinkInputButton.addTarget(self, action: #selector(shrinkInput), for: .touchUpInside)
        //composerView.commandsButton.addTarget(self, action: #selector(showAvailableCommands), for: .touchUpInside)
        composerView.dismissButton.addTarget(self, action: #selector(clearContent(sender:)), for: .touchUpInside)
        //composerView.moneyTransferButton.addTarget(self, action: #selector(sendMoneyAction(sender:)), for: .touchUpInside)
        composerView.toolbarToggleButton.addTarget(self, action: #selector(toolKitToggleAction(sender:)), for: .touchUpInside)
        composerView.toolbarBackButton.addTarget(self, action: #selector(toolKitBackAction(sender:)), for: .touchUpInside)
        composerView.inputMessageView.clearButton.addTarget(
            self,
            action: #selector(clearContent(sender:)),
            for: .touchUpInside
        )
        composerView.keyboardToolTipTapped = { [weak self] toolKit in
            guard let weakSelf = self else {
                return
            }
            switch toolKit.type {
            case .photoPicker:
                weakSelf.composerView.inputMessageView.textView.resignFirstResponder()
                weakSelf.showAttachmentsPicker()
            case .sendOneDollar:
                weakSelf.composerView.inputMessageView.textView.resignFirstResponder()
                weakSelf.sendONEAction()
            case .sendRedPacket:
                weakSelf.composerView.inputMessageView.textView.resignFirstResponder()
                weakSelf.sendRedPacketAction()
            case .shareNFTGalllery:
                weakSelf.composerView.inputMessageView.textView.resignFirstResponder()
                weakSelf.showAvailableCommands()
            case .pay:
                weakSelf.showPayment()
            }
        }
        setupAttachmentsView()
        bindMenuController()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            guard let `self` = self else { return }
            self.keyboardHeight = KeyboardService.shared.measuredSize
        }
    }

    override open func setUpLayout() {
        super.setUpLayout()

        view.addSubview(composerView)
        composerView.pin(to: view)
    }

    override open func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(sendOneWalletBubble(notification:)), name: .sendOneWallet, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(redPacketBubble(notification:)), name: .sendRedPacket, object: nil)
    }

    override open func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        dismissSuggestions()
    }

    override open func updateContent() {
        super.updateContent()

        if composerView.inputMessageView.textView.text != content.text {
            // Updating the text unnecessarily makes the caret jump to the end of input
            composerView.inputMessageView.textView.text = content.text
        }

        if !content.isEmpty && channelConfig?.typingEventsEnabled == true {
            channelController?.sendKeystrokeEvent()
        }

        switch content.state {
        case .new:
            composerView.inputMessageView.textView.placeholderLabel.text = L10n.Composer.Placeholder.message
            Animate {
                self.composerView.confirmButton.isHidden = true
                self.composerView.inputMessageView.sendButton.isHidden = false
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
                self.composerView.inputMessageView.sendButton.isHidden = true
                self.composerView.headerView.isHidden = false
            }
        default:
            log.warning("The composer state \(content.state.description) was not handled.")
        }

        composerView.inputMessageView.sendButton.isHidden = content.isEmpty && content.attachments.isEmpty
        composerView.confirmButton.isEnabled = !content.isEmpty

        let isAttachmentButtonHidden = !content.isEmpty || !isAttachmentsEnabled || content.hasCommand
        let isCommandsButtonHidden = !content.isEmpty || !isCommandsEnabled || content.hasCommand
        let isMoneyTransferButtonHiddden = !content.isEmpty
        let isShrinkInputButtonHidden = content.isEmpty || (!isCommandsEnabled && !isAttachmentsEnabled) || content.hasCommand
        
        Animate {
            self.composerView.attachmentButton.isHidden = isAttachmentButtonHidden
            self.composerView.commandsButton.isHidden = isCommandsButtonHidden
            self.composerView.shrinkInputButton.isHidden = isShrinkInputButtonHidden
            self.composerView.moneyTransferButton.isHidden = isMoneyTransferButtonHiddden
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

        if isCommandsEnabled, let typingCommand = typingCommand(in: composerView.inputMessageView.textView) {
            showCommandSuggestions(for: typingCommand)
            return
        }

        if isMentionsEnabled, let (typingMention, mentionRange) = typingMention(in: composerView.inputMessageView.textView) {
            showMentionSuggestions(for: typingMention, mentionRange: mentionRange)
            return
        }
        
        // If we have files in attachments, do not allow images to be pasted in the text view.
        // This is due to the limitation of UI(files and images cannot be shown together)
        let filesExistInAttachments = content.attachments.contains(where: { $0.type == .file })
        composerView.inputMessageView.textView.isPastingImagesEnabled = !filesExistInAttachments

        dismissSuggestions()
    }
    
    open func setupAttachmentsView() {
        addChildViewController(attachmentsVC, embedIn: composerView.inputMessageView.attachmentsViewContainer)
        attachmentsVC.didTapRemoveItemButton = { [weak self] index in
            guard let `self` = self else { return }
            if self.content.attachments[index].type == .wallet {
                self.showMessageOption(isHide: false)
            }
            self.content.attachments.remove(at: index)
            self.composerView.inputMessageView.sendButton.isHidden = self.content.isEmpty && self.content.attachments.isEmpty
        }
    }

    private func bindWalletOption() {
        walletInputView?.didShowPaymentOption = { [weak self] in
            guard let `self` = self else { return }
            self.composerView.toolbarBackButton.isHidden.toggle()
            self.composerView.toolbarToggleButton.isHidden.toggle()
        }
        walletInputView?.didRequestAction = { [weak self] (amount, type, theme) in
            guard let `self` = self else { return }
            if type == .request {
                self.addWalletAttachment(amount: amount, paymentType: type, paymentTheme: theme)
            } else {
                self.composerView.inputMessageView.textView.text = nil
                self.composerView.inputMessageView.textView.resignFirstResponder()
                guard let channelId = self.channelController?.channel?.cid else { return }
                var userInfo = [String: Any]()
                userInfo["channelId"] = channelId
                userInfo["currencyValue"] = "\(amount)"
                userInfo["currencyDisplay"] = "\(amount)"
                userInfo["paymentTheme"] = theme.getPaymentThemeUrl()
                NotificationCenter.default.post(name: .sendOneAction, object: nil, userInfo: userInfo)
                self.hideInputView()
                self.composerView.leadingContainer.isHidden = false
                self.animateToolkitView(isHide: true)
            }
        }
    }

    func bindMenuController() {
        menuController = ChatMenuViewController.instantiateController(storyboard: .wallet)
        menuController?.didTapAction = { [weak self] action in
            guard let `self` = self else { return }
            switch action {
            case .media:
                self.composerView.inputMessageView.textView.resignFirstResponder()
                self.showAttachmentsPicker()
                self.animateToolkitView(isHide: true)
            case .contact:
                self.animateToolkitView(isHide: true)
                break
            case .weather:
                break
            case .crypto:
                self.showPayment()
            case .oneN:
                self.animateToolkitView(isHide: true)
                break
            case .nft:
                self.animateToolkitView(isHide: true)
            case .redPacket:
                self.animateToolkitView(isHide: true)
                self.composerView.inputMessageView.textView.resignFirstResponder()
                self.sendRedPacketAction()
            case .dao:
                self.animateToolkitView(isHide: true)
                break
            }
        }

    }

    // MARK: - Actions
    
    @objc open func publishMessage(sender: UIButton) {
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
        } else {
            createNewMessage(text: text)
        }
        content.clear()
        self.composerView.leadingContainer.isHidden = false
    }
    
    /// Shows a photo/media picker.
    open func showMediaPicker() {
        present(mediaPickerVC, animated: true)
    }
    
    /// Shows a document picker.
    open func showFilePicker() {
        present(filePickerVC, animated: true)
    }
    
    /// Returns actions for attachments picker.
    open var attachmentsPickerActions: [UIAlertAction] {
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
        
        let cancelAction = UIAlertAction(
            title: L10n.Composer.Picker.cancel,
            style: .cancel
        )
        
        return [showMediaPickerAction, showFilePickerAction, cancelAction]
    }
    
    /// Action that handles tap on attachments button in composer.
    @objc open func showAttachmentsPicker(sender: UIButton = UIButton()) {
        // The UI doesn't support mix of image and file attachments so we are limiting this option.
        // Files in the message composer are scrolling vertically and images horizontally.
        // There is no techical limitation for multiple attachment types.
        if content.attachments.isEmpty {
            presentAlert(
                message: L10n.Composer.Picker.title,
                preferredStyle: .actionSheet,
                actions: attachmentsPickerActions,
                sourceView: sender
            )
        } else if content.attachments.contains(where: { $0.type == .file }) {
            showFilePicker()
        } else if content.attachments.contains(where: { $0.type == .image || $0.type == .video }) {
            showMediaPicker()
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
    
    @objc open func showAvailableCommands() {
        if suggestionsVC.isPresented {
            dismissSuggestions()
        } else {
            showCommandSuggestions(for: "")
        }
    }
    
    @objc open func clearContent(sender: UIButton) {
        content.clear()
    }

    open func showPayment() {
        walletInputView = WalletQuickInputViewController.instantiateController(storyboard: .wallet)
        bindWalletOption()
        showInputViewController(walletInputView)
        walletInputView?.showKeypad = { [weak self] amount in
            guard let `self` = self else { return }
            guard let walletView: WalletInputViewController = WalletInputViewController.instantiateController(storyboard: .wallet) else { return }
            walletView.updatedAmount = amount
            walletView.didHide = { [weak self] amount, type in
                guard let `self` = self else { return }
                self.walletInputView?.paymentType = type
                self.walletInputView?.walletStepper.updateAmount(amount: amount)
                self.walletInputView?.showPaymentOptionView()
            }
            UIApplication.shared.windows.first?.rootViewController?.present(walletView, animated: true, completion: nil)
        }
    }

    private func showMessageOption(isHide: Bool) {
        self.animateToolkitView(isHide: isHide)
        self.composerView.leadingContainer.isHidden = isHide
    }

    private func hideInputView() {
        self.composerView.inputMessageView.textView.inputView = nil
        self.composerView.inputMessageView.textView.reloadInputViews()
    }

    private func showInputViewController(_ uiViewController: UIViewController?) {
        let walletView = UIView()
        if let menu = uiViewController?.view {
            walletView.embed(menu)
            menu.widthAnchor.constraint(equalToConstant: self.view.bounds.width).isActive = true
            menu.heightAnchor.constraint(equalToConstant: keyboardHeight).isActive = true
        }
        walletView.frame = CGRect(x: 0, y: 0, width: self.view.bounds.width, height: keyboardHeight)
        self.composerView.inputMessageView.textView.inputView = walletView
        self.composerView.inputMessageView.textView.reloadInputViews()
        self.composerView.inputMessageView.textView.becomeFirstResponder()
    }

    private func addWalletAttachment(
        amount: Double,
        paymentType: WalletAttachmentPayload.PaymentType,
        paymentTheme: WalletAttachmentPayload.PaymentTheme
    ) {
        DispatchQueue.main.async {
            do {
                var extraData = [String: RawJSON]()
                extraData["transferAmount"] = .string("\(amount)")
                extraData["recipientName"] = .string(ChatClient.shared.currentUserController().currentUser?.name ?? "")
                extraData["recipientUserId"] = .string(ChatClient.shared.currentUserId ?? "")
                extraData["isPaid"] = .bool(false)
                extraData["paymentTheme"] = .string(paymentTheme.getPaymentThemeUrl())
                extraData["recipientImageUrl"] = .string(ChatClient.shared.currentUserController().currentUser?.imageURL?.absoluteString ?? "")
                let attachment = try AnyAttachmentPayload(extraData: extraData, paymentType: paymentType)
                self.content.attachments.append(attachment)
                self.composerView.inputMessageView.sendButton.isHidden = false
                self.hideInputView()
                self.showMessageOption(isHide: true)
            } catch {
                print(error)
            }
        }
    }

    @objc open func sendONEAction() {
        composerView.inputMessageView.textView.text = nil
        composerView.inputMessageView.textView.resignFirstResponder()
        guard let channelId = channelController?.channel?.cid else { return }
        var userInfo = [String: Any]()
        userInfo["channelId"] = channelId
        NotificationCenter.default.post(name: .sendOneWalletTapAction, object: nil, userInfo: userInfo)
    }

    @objc open func sendRedPacketAction() {
        composerView.inputMessageView.textView.text = nil
        composerView.inputMessageView.textView.resignFirstResponder()
        guard let channelId = channelController?.channel?.cid else { return }
        var userInfo = [String: Any]()
        userInfo["channelId"] = channelId
        NotificationCenter.default.post(name: .sendRedPacketTapAction, object: nil, userInfo: userInfo)
    }

    private func animateMenuButton() {
        if !isMenuShowing {
            UIView.animate(withDuration: 0.5, delay: 0.0, usingSpringWithDamping: 0.5, initialSpringVelocity: 5, options: .curveEaseInOut, animations: { [weak self] in
                guard let `self` = self else { return }
                self.composerView.toolbarToggleButton.transform = CGAffineTransform(rotationAngle: CGFloat(Double.pi/4))
            }, completion: { [weak self] _ in
                guard let `self` = self else { return }
                self.isMenuShowing = true
            })
        } else {
            UIView.animate(withDuration: 0.5, delay: 0.0, usingSpringWithDamping: 0.5, initialSpringVelocity: 5, options: .curveEaseInOut, animations: { [weak self] in
                guard let `self` = self else { return }
                self.composerView.toolbarToggleButton.transform = CGAffineTransform.identity
            }, completion: { [weak self] _ in
                guard let `self` = self else { return }
                self.isMenuShowing = false
            })
        }
    }

    func animateToolkitView(isHide: Bool) {
        animateMenuButton()
        if !isHide {
            self.showInputViewController(menuController)
            self.isMenuShowing = true
        } else {
            self.composerView.inputMessageView.textView.inputView = nil
            self.composerView.inputMessageView.textView.reloadInputViews()
            self.isMenuShowing = false
        }
    }

    @objc open func toolKitToggleAction(sender: UIButton) {
        if !isMenuShowing {
            animateToolkitView(isHide: false)
        } else {
            animateToolkitView(isHide: true)
        }
    }

    @objc open func toolKitBackAction(sender: UIButton) {
        self.composerView.toolbarBackButton.isHidden.toggle()
        self.composerView.toolbarToggleButton.isHidden.toggle()
        NotificationCenter.default.post(name: .hidePaymentOptions, object: nil, userInfo: ["isHide": true])
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
                quotedMessageId: content.quotingMessage?.id
            )
            return
        }

        channelController?.createNewMessage(
            text: text,
            pinning: nil,
            attachments: content.attachments,
            mentionedUserIds: content.mentionedUsers.map(\.id),
            quotedMessageId: content.quotingMessage?.id
        )
    }

    @objc open func sendOneWalletBubble(notification: Notification) {
        guard let sendOneWalletData = notification.userInfo?["oneWalletTx"] as? SendOneWallet else {
            return
        }
        channelController?.createNewMessage(
            text: "One Wallet Transfer",
            pinning: nil,
            attachments: [],
            mentionedUserIds: content.mentionedUsers.map(\.id),
            quotedMessageId: content.quotingMessage?.id,
            extraData: ["oneWalletTx" : .dictionary(sendOneWalletData.toDictionary())],
            completion: nil)
    }

    @objc open func redPacketBubble(notification: Notification) {
        guard let redPacket = notification.userInfo?["redPacketPickup"] as? RedPacket else {
            return
        }
        channelController?.createNewMessage(
            text: "Red Packet Drop",
            pinning: nil,
            attachments: [],
            mentionedUserIds: content.mentionedUsers.map(\.id),
            quotedMessageId: content.quotingMessage?.id,
            extraData: ["redPacketPickup" : .dictionary(redPacket.toDictionary())],
            completion: nil)
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
        // TODO: Adjust LLC to edit mentions
        messageController?.editMessage(text: newText)
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
        print("*****", typingSuggestion?.text)
        return typingSuggestion?.text
    }

    /// Shows the command suggestions for the potential command the current user is typing.
    /// - Parameter typingCommand: The potential command that the current user is typing.
    open func showCommandSuggestions(for typingCommand: String) {
        print("^^^^^",typingCommand)
        var availableCommands = channelController?.channel?.config.commands ?? []
        // Don't show the commands suggestion VC if there are no commands
        guard availableCommands.isEmpty == false else { return }
        availableCommands.append(contentsOf: extraCommands())
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
            let commandName = foundCommand.name
            if commandName == "Send" {
                sendONEAction()
            } else if commandName == "redpacket" {
                sendRedPacketAction()
            } else {
                content.addCommand(foundCommand)
                dismissSuggestions()
            }
            return
        }

        let dataSource = ChatMessageComposerSuggestionsCommandDataSource(
            with: commandHints,
            collectionView: suggestionsVC.collectionView
        )
        suggestionsVC.dataSource = dataSource
        suggestionsVC.didSelectItemAt = { [weak self] commandIndex in
            let command = dataSource.commands[commandIndex]
            print(command.name)
            let commandName = command.name
            if commandName == "Send" {
                self?.sendONEAction()
            } else if commandName == "redpacket" {
                self?.sendRedPacketAction()
            } else {
                self?.content.addCommand(commandHints[commandIndex])
                self?.dismissSuggestions()
            }
        }
        showSuggestions()
    }

    open func extraCommands() -> [Command] {
        let sendOne = Command(name: "Send", description: "Shortcut for send $ONE", set: "$ONE", args: "Send $ONE")
        let redPacket = Command(name: "redpacket", description: "Shortcut for redpacket", set: "$ONE", args: "RedPacket")
        return [sendOne, redPacket]
    }
    
    /// Returns the query to be used for searching users for the given typing mention.
    ///
    /// This function is called in `showMentionSuggestions` to retrieve the query
    /// that will be used to search the users. You should override this if you want to change the
    /// user searching logic.
    ///
    /// - Parameter typingMention: The potential user mention the current user is typing.
    /// - Returns: `_UserListQuery` instance that will be used for searching users.
    open func queryForMentionSuggestionsSearch(typingMention term: String) -> UserListQuery {
        UserListQuery(
            filter: .or([
                .autocomplete(.name, text: term),
                .autocomplete(.id, text: term)
            ]),
            sort: [.init(key: .name, isAscending: true)]
        )
    }

    /// Shows the mention suggestions for the potential mention the current user is typing.
    /// - Parameters:
    ///   - typingMention: The potential user mention the current user is typing.
    ///   - mentionRange: The position where the current user is typing a mention to it can be replaced with the suggestion.
    open func showMentionSuggestions(for typingMention: String, mentionRange: NSRange) {
        guard let channel = channelController?.channel else {
            return
        }
        guard let currentUserId = channelController?.client.currentUserId else {
            return
        }
        
        var usersCache: [ChatUser] = []

        if mentionAllAppUsers {
            userSearchController.search(
                query: queryForMentionSuggestionsSearch(typingMention: typingMention)
            )
        } else {
            usersCache = searchUsers(
                channel.lastActiveWatchers.map { $0 } + channel.lastActiveMembers.map { $0 },
                by: typingMention,
                excludingId: currentUserId
            )
        }

        let dataSource = ChatMessageComposerSuggestionsMentionDataSource(
            collectionView: suggestionsVC.collectionView,
            searchController: userSearchController,
            usersCache: usersCache
        )
        suggestionsVC.dataSource = dataSource
        suggestionsVC.didSelectItemAt = { [weak self] userIndex in
            guard let self = self else { return }
            guard dataSource.usersCache.count >= userIndex else {
                return
            }

            let textView = self.composerView.inputMessageView.textView
            let user = dataSource.usersCache[userIndex]
            let text = textView.text as NSString
            let mentionText = self.mentionText(for: user)
            let newText = text.replacingCharacters(in: mentionRange, with: mentionText)
            self.content.text = newText
            self.content.mentionedUsers.insert(user)

            let caretLocation = textView.selectedRange.location
            let newCaretLocation = caretLocation + (mentionText.count - typingMention.count)
            textView.selectedRange = NSRange(location: newCaretLocation, length: 0)

            self.dismissSuggestions()
        }

        showSuggestions()
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
    
    /// Creates and adds an attachment from the given URL to the `content`
    /// - Parameters:
    ///   - url: The URL of the attachment
    ///   - type: The type of the attachment
    open func addAttachmentToContent(from url: URL, type: AttachmentType) throws {
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
        guard fileSize < chatConfig.maxAttachmentSize else {
            throw AttachmentValidationError.maxFileSizeExceeded
        }
        
        let attachment = try AnyAttachmentPayload(localFileURL: url, attachmentType: type)
        content.attachments.append(attachment)
        self.composerView.inputMessageView.sendButton.isHidden = false
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

    // MARK: - UITextViewDelegate

    open func textViewDidChange(_ textView: UITextView) {
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
            
            do {
                try self?.addAttachmentToContent(from: urlAndType.0, type: urlAndType.1)
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
        let type: AttachmentType = .file
        
        for fileURL in urls {
            do {
                try addAttachmentToContent(from: fileURL, type: type)
            } catch {
                handleAddAttachmentError(
                    attachmentURL: fileURL,
                    attachmentType: type,
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
            try addAttachmentToContent(from: imageUrl, type: type)
        } catch {
            handleAddAttachmentError(
                attachmentURL: imageUrl,
                attachmentType: type,
                error: error
            )
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
        .filter { searchInput == "" || $0.id.contains(searchInput) || (normalize($0.name ?? "").contains(searchInput)) }

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
