//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import StreamChat
import StreamChatCommonUI
import StreamChatUI
import UIKit

/// Delegate protocol for `LivestreamMessageActionsVC`
@MainActor protocol LivestreamMessageActionsVCDelegate: AnyObject {
    func livestreamMessageActionsVC(
        _ vc: DemoLivestreamMessageActionsVC,
        message: ChatMessage,
        didTapOnActionItem actionItem: ChatMessageActionItem
    )
    func livestreamMessageActionsVCDidFinish(_ vc: DemoLivestreamMessageActionsVC)
}

/// Custom bottom sheet view controller for livestream message actions.
class DemoLivestreamMessageActionsVC: UIViewController {
    // MARK: - Properties
    
    weak var delegate: LivestreamMessageActionsVCDelegate?
    weak var livestreamChannelController: LivestreamChannelController?
    var message: ChatMessage?
    
    // MARK: - UI Components
    
    private lazy var mainStackView = VContainer(spacing: 8)

    private lazy var reactionsStackView = HContainer(
        spacing: 16,
        distribution: .fillEqually,
        alignment: .center
    ).height(50)
    
    private lazy var actionsStackView = HContainer(
        spacing: 16,
        distribution: .fillEqually
    ).height(80)
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupReactions()
        setupActions()
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        view.backgroundColor = Appearance.default.colorPalette.background
        
        view.addSubview(mainStackView)
        NSLayoutConstraint.activate([
            mainStackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            mainStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            mainStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            mainStackView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -10)
        ])
        
        mainStackView.views {
            reactionsStackView
            actionsStackView
        }
    }
    
    private func setupReactions() {
        guard let channel = livestreamChannelController?.channel,
              channel.canSendReaction else { return }

        let availableReactions = Appearance.default.images.availableReactions
        
        let reactionButtons = availableReactions
            .sorted { $0.key.rawValue < $1.key.rawValue }
            .map { (reactionType, reactionAppearance) in
                createReactionButton(image: reactionAppearance.smallIcon, reactionType: reactionType)
            }

        reactionButtons.forEach {
            reactionsStackView.addArrangedSubview($0)
        }
    }
    
    private func setupActions() {
        guard let message = message,
              let livestreamChannelController = livestreamChannelController else { return }
        
        var actionButtons: [UIButton] = []
        
        // Reply action
        if let channel = livestreamChannelController.channel, channel.canQuoteMessage {
            let replyButton = createSquareActionButton(
                title: "Reply",
                icon: UIImage(systemName: "arrowshape.turn.up.left") ?? UIImage(),
                action: { [weak self] in
                    self?.handleReplyAction()
                }
            )
            actionButtons.append(replyButton)
        }
        
        // Pin action
        if let channel = livestreamChannelController.channel, channel.canPinMessage {
            let isPinned = message.pinDetails != nil
            let pinButton = createSquareActionButton(
                title: isPinned ? "Unpin" : "Pin",
                icon: UIImage(systemName: isPinned ? "pin.slash" : "pin") ?? UIImage(),
                action: { [weak self] in
                    self?.handlePinAction()
                }
            )
            actionButtons.append(pinButton)
        }
        
        // Copy action
        if !message.text.isEmpty {
            let copyActionItem = CopyActionItem { [weak self] actionItem in
                guard let self = self, let message = self.message else { return }
                self.delegate?.livestreamMessageActionsVC(self, message: message, didTapOnActionItem: actionItem)
            }
            let copyButton = createSquareActionButton(
                title: copyActionItem.title,
                icon: copyActionItem.icon,
                action: {
                    copyActionItem.action(copyActionItem)
                }
            )
            actionButtons.append(copyButton)
        }

        actionButtons.forEach {
            actionsStackView.addArrangedSubview($0)
        }
    }
    
    private func createReactionButton(image: UIImage, reactionType: MessageReactionType) -> UIButton {
        let button = UIButton(type: .system)
        button.setImage(image, for: .normal)
        button.contentMode = .scaleAspectFit
        button.imageView?.contentMode = .scaleAspectFit
        button.contentEdgeInsets = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)

        let isSelected = message?.currentUserReactions.contains { $0.type == reactionType } ?? false
        let colorPalette = Appearance.default.colorPalette
        button.backgroundColor = isSelected ? colorPalette.accentPrimary.withAlphaComponent(0.5) : .systemGray6
        button.layer.borderWidth = isSelected ? 2 : 0.5
        button.layer.borderColor = isSelected ? colorPalette.accentPrimary.cgColor : UIColor.separator.cgColor
        button.layer.cornerRadius = 20
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 1)
        button.layer.shadowOpacity = 0.1
        button.layer.shadowRadius = 2
        button.width(40).height(40)

        button.addTarget(self, action: #selector(reactionButtonPressed(_:)), for: .touchDown)
        button.addTarget(self, action: #selector(reactionButtonReleased(_:)), for: [.touchUpInside, .touchUpOutside, .touchCancel])
        
        button.addAction(UIAction { [weak self] _ in
            self?.toggleReaction(reactionType)
            self?.delegate?.livestreamMessageActionsVCDidFinish(self!)
        }, for: .touchUpInside)
        
        return button
    }
    
    @objc private func reactionButtonPressed(_ button: UIButton) {
        UIView.animate(withDuration: 0.1) {
            button.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        }
    }
    
    @objc private func reactionButtonReleased(_ button: UIButton) {
        UIView.animate(withDuration: 0.1) {
            button.transform = .identity
        }
    }
    
    private func createSquareActionButton(title: String, icon: UIImage, action: @escaping () -> Void) -> UIButton {
        let button = UIButton(type: .system)
        button.backgroundColor = UIColor.systemGray6
        button.layer.cornerRadius = 12
        
        // Create icon image view
        let iconImageView = UIImageView(image: icon)
        iconImageView.tintColor = .label
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.width(24).height(24)
        
        // Create title label
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        titleLabel.textColor = .label
        titleLabel.textAlignment = .center
        
        // Create vertical container for icon and label
        let contentStack = VContainer(spacing: 8, alignment: .center) {
            iconImageView
            titleLabel
        }
        contentStack.isUserInteractionEnabled = false
        
        button.addSubview(contentStack)
        NSLayoutConstraint.activate([
            contentStack.centerXAnchor.constraint(equalTo: button.centerXAnchor),
            contentStack.centerYAnchor.constraint(equalTo: button.centerYAnchor)
        ])
        
        button.addAction(UIAction { [weak self] _ in
            action()
            self?.delegate?.livestreamMessageActionsVCDidFinish(self!)
        }, for: .touchUpInside)
        
        return button
    }
    
    // MARK: - Action Handlers
    
    private func toggleReaction(_ reactionType: MessageReactionType) {
        guard let message = message else { return }
        
        // Check if current user has already reacted with this type
        let hasReacted = message.currentUserReactions.contains { $0.type == reactionType }
        
        if hasReacted {
            removeReaction(reactionType)
        } else {
            addReaction(reactionType)
        }
    }
    
    private func addReaction(_ reactionType: MessageReactionType) {
        guard let message = message,
              let controller = livestreamChannelController else { return }
        
        controller.addReaction(reactionType, to: message.id) { [weak self] error in
            if let error = error {
                DispatchQueue.main.async {
                    self?.showErrorAlert(error: error)
                }
            }
        }
    }
    
    private func removeReaction(_ reactionType: MessageReactionType) {
        guard let message = message,
              let controller = livestreamChannelController else { return }
        
        controller.deleteReaction(reactionType, from: message.id) { [weak self] error in
            if let error = error {
                DispatchQueue.main.async {
                    self?.showErrorAlert(error: error)
                }
            }
        }
    }
    
    private func handleReplyAction() {
        guard let message = message else { return }
        let actionItem = InlineReplyActionItem { _ in }
        delegate?.livestreamMessageActionsVC(self, message: message, didTapOnActionItem: actionItem)
    }
    
    private func handlePinAction() {
        guard let message = message,
              let controller = livestreamChannelController else { return }
        
        let isPinned = message.pinDetails != nil
        
        if isPinned {
            controller.unpin(messageId: message.id) { [weak self] error in
                if let error = error {
                    DispatchQueue.main.async {
                        self?.showErrorAlert(error: error)
                    }
                }
            }
        } else {
            controller.pin(messageId: message.id, pinning: .noExpiration) { [weak self] error in
                if let error = error {
                    DispatchQueue.main.async {
                        self?.showErrorAlert(error: error)
                    }
                }
            }
        }
    }
    
    private func showErrorAlert(error: Error) {
        let alert = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - Reactions Action Item

/// Action item for adding reactions to a message
public struct ReactionsActionItem: ChatMessageActionItem {
    public var title: String { "Add Reaction" }
    public let icon: UIImage
    public let action: (ChatMessageActionItem) -> Void

    public init(action: @escaping (ChatMessageActionItem) -> Void) {
        self.action = action
        icon = UIImage(systemName: "face.smiling") ?? UIImage()
    }
}

// MARK: - Pin Action Item

/// Action item for pinning/unpinning a message
public struct PinActionItem: ChatMessageActionItem {
    public var title: String
    public let icon: UIImage
    public let action: (ChatMessageActionItem) -> Void
    public let isPinned: Bool

    public init(title: String? = nil, isPinned: Bool, action: @escaping (ChatMessageActionItem) -> Void) {
        self.title = title ?? (isPinned ? "Unpin Message" : "Pin Message")
        self.isPinned = isPinned
        self.action = action
        icon = UIImage(systemName: isPinned ? "pin.slash" : "pin") ?? UIImage()
    }
}
