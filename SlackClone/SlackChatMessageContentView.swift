//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import StreamChatUI
import UIKit

final class SlackChatMessageContentView: ChatMessageContentView {
    private var didSetUpConstraints = false
    
    override func setupAvatarView() {
        guard authorAvatarView == nil else { return }
        
        let authorAvatarView = uiConfig
            .messageList
            .messageContentSubviews
            .authorAvatarView
            .init()
        authorAvatarView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(authorAvatarView)
        NSLayoutConstraint.activate([
            authorAvatarView.widthAnchor.constraint(equalToConstant: 32),
            authorAvatarView.heightAnchor.constraint(equalToConstant: 32),
            authorAvatarView.leadingAnchor.constraint(equalTo: leadingAnchor),
            authorAvatarView.topAnchor.constraint(equalTo: topAnchor)
        ])
        self.authorAvatarView = authorAvatarView
    }
    
    override func setupMetadataView() {
        guard messageMetadataView == nil else { return }
        
        setupAvatarView()

        let authorAvatarView = self.authorAvatarView!
        
        let messageMetadataView = uiConfig
            .messageList
            .messageContentSubviews
            .metadataView
            .init()
        messageMetadataView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(messageMetadataView)
        NSLayoutConstraint.activate([
            messageMetadataView.heightAnchor.constraint(equalToConstant: 16),
            messageMetadataView.topAnchor.constraint(equalTo: topAnchor),
            messageMetadataView.topAnchor.constraint(equalTo: authorAvatarView.topAnchor),
            messageMetadataView.leadingAnchor.constraint(equalTo: authorAvatarView.trailingAnchor, constant: 10)
        ])
        self.messageMetadataView = messageMetadataView
    }
    
    override func setupMessageBubbleView() {
        guard messageBubbleView == nil else { return }

        setupAvatarView()
        setupMetadataView()
        
        let messageMetadataView = self.messageMetadataView!
        
        let messageBubbleView = uiConfig
            .messageList
            .messageContentSubviews
            .bubbleView.init()
        messageBubbleView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(messageBubbleView)
        messageBubbleView.setContentCompressionResistancePriority(.required, for: .vertical)
        
        NSLayoutConstraint.activate([
            messageBubbleView.leadingAnchor.constraint(equalTo: messageMetadataView.leadingAnchor),
            messageBubbleView.trailingAnchor.constraint(equalTo: trailingAnchor),
            messageBubbleView.topAnchor.constraint(equalTo: messageMetadataView.bottomAnchor, constant: 5),
            messageBubbleView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        
        messageBubbleView.borderLayer.removeFromSuperlayer()
        
        messageBubbleView.layer.cornerRadius = 0
        
        self.messageBubbleView = messageBubbleView
    }
    
    override func setupAttachmentView() {
        super.setupAttachmentView()
        
        NSLayoutConstraint.activate([
            attachmentsView!.imageGallery.leadingAnchor.constraint(equalTo: messageBubbleView!.leadingAnchor),
            attachmentsView!.imageGallery.trailingAnchor.constraint(equalTo: messageBubbleView!.trailingAnchor)
        ])
    }
    
    override func updateMetadataViewIfNeeded() {
        super.updateMetadataViewIfNeeded()
        
        messageMetadataView!.isHidden = false
    }
    
    override func updateBubbleViewIfNeeded() {
        guard let message = message else { return }
        
        setupMessageBubbleView()
        setupMetadataView()
        setupErrorIndicator()
        let messageBubbleView = self.messageBubbleView!
        
        messageBubbleView.message = message
        
        messageBubbleView.message = message
        messageBubbleView.backgroundColor = .clear
    }
    
    override func updateContent() {
        guard let message = message else { return }
        
        // Base views in the message
        updateBubbleViewIfNeeded()
        updateMetadataViewIfNeeded()
        updateReactionsViewIfNeeded()
        updateThreadViewsIfNeeded()
        updateAvatarViewIfNeeded()
        updateMessagePositionIfNeeded()
        updateErrorIndicatorIfNeeded()

        // Additional views
        updateTextViewIfNeeded()
        updateQuotedMessageViewIfNeeded()
        updateLinkPreviewViewIfNeeded()
        updateAttachmentsViewIfNeeded()
        
        // Necessary constraints
        if !didSetUpConstraints {
            setupConstraints(for: message.layoutOptions)
            didSetUpConstraints = true
        }

        setNeedsUpdateConstraints()
        
        authorAvatarView?.isHidden = false
        threadView?.isHidden = true
        reactionsBubble?.isHidden = true
        linkPreviewView?.isHidden = true
    }
    
    // MARK: - Helpers
    
    private func setupConstraints(for layoutOptions: ChatMessageContentViewLayoutOptions) {
        switch layoutOptions {
        case [.text, .attachments]:
            NSLayoutConstraint.activate([
                textView!.leadingAnchor.constraint(equalTo: messageBubbleView!.leadingAnchor),
                textView!.trailingAnchor.constraint(equalTo: messageBubbleView!.trailingAnchor),
                textView!.topAnchor.constraint(equalTo: messageBubbleView!.topAnchor),
                
                attachmentsView!.topAnchor.constraint(equalTo: textView!.bottomAnchor, constant: 5),
                attachmentsView!.leadingAnchor.constraint(equalTo: messageBubbleView!.leadingAnchor),
                attachmentsView!.trailingAnchor.constraint(equalTo: messageBubbleView!.trailingAnchor),
                attachmentsView!.bottomAnchor.constraint(equalTo: messageBubbleView!.bottomAnchor, constant: -5)
            ])
        case [.text]:
            NSLayoutConstraint.activate([
                textView!.leadingAnchor.constraint(equalTo: messageBubbleView!.leadingAnchor),
                textView!.trailingAnchor.constraint(equalTo: messageBubbleView!.trailingAnchor),
                textView!.topAnchor.constraint(equalTo: messageBubbleView!.topAnchor),
                textView!.bottomAnchor.constraint(equalTo: messageBubbleView!.bottomAnchor)
            ])
        default:
            NSLayoutConstraint.activate([
                textView!.leadingAnchor.constraint(equalTo: messageBubbleView!.leadingAnchor),
                textView!.trailingAnchor.constraint(equalTo: messageBubbleView!.trailingAnchor),
                textView!.topAnchor.constraint(equalTo: messageBubbleView!.topAnchor),
                textView!.bottomAnchor.constraint(equalTo: messageBubbleView!.bottomAnchor)
            ])
        }
    }
}

extension _ChatMessageGroupPart {
    var textContent: String {
        guard message.type != .ephemeral else {
            return ""
        }
        
        guard message.deletedAt == nil else {
            return "Message was deleted"
        }
        
        return message.text
    }
    
    var layoutOptions: ChatMessageContentViewLayoutOptions {
        guard message.deletedAt == nil else {
            return [.text]
        }
        
        var options: ChatMessageContentViewLayoutOptions = []
        
        if !textContent.isEmpty {
            options.insert(.text)
        }
        
        if quotedMessage != nil {
            options.insert(.quotedMessage)
        }
        
        if message.attachments.contains(where: { $0.type == .image || $0.type == .giphy || $0.type == .file }) {
            options.insert(.attachments)
        } else if message.attachments.contains(where: { $0.type.isLink }) {
            // link preview is visible only when no other attachments available
            options.insert(.linkPreview)
        }
        
        return options
    }
}
