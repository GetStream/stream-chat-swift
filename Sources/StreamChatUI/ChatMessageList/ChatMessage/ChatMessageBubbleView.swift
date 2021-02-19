//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

internal typealias ChatMessageBubbleView = _ChatMessageBubbleView<NoExtraData>

internal class _ChatMessageBubbleView<ExtraData: ExtraDataTypes>: _View, UIConfigProvider {
    internal var message: _ChatMessageGroupPart<ExtraData>? {
        didSet { updateContentIfNeeded() }
    }

    internal var onLinkTap: (ChatMessageDefaultAttachment?) -> Void = { _ in }
    
    // MARK: - Subviews

    internal private(set) lazy var textView: UITextView = {
        let textView = OnlyLinkTappableTextView()
        textView.isEditable = false
        textView.dataDetectorTypes = .link
        textView.isScrollEnabled = false
        textView.backgroundColor = .clear
        textView.font = uiConfig.fonts.body
        textView.adjustsFontForContentSizeCategory = true
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0
        return textView.withoutAutoresizingMaskConstraints
    }()

    internal private(set) lazy var linkPreviewView = uiConfig
        .messageList
        .messageContentSubviews
        .linkPreviewView
        .init()
        .withoutAutoresizingMaskConstraints

    internal private(set) lazy var quotedMessageView = uiConfig
        .messageList
        .messageContentSubviews
        .quotedMessageBubbleView.init()
        .withoutAutoresizingMaskConstraints
    
    internal private(set) lazy var borderLayer = CAShapeLayer()

    internal fileprivate(set) var layoutConstraints: [ChatMessageBubbleViewLayoutOptions: [NSLayoutConstraint]] = [:]

    // MARK: - Overrides

    override internal func layoutSubviews() {
        super.layoutSubviews()

        borderLayer.frame = bounds
    }

    override internal func setUp() {
        super.setUp()
        linkPreviewView.addTarget(self, action: #selector(didTapOnLinkPreview), for: .touchUpInside)
    }

    override internal func defaultAppearance() {
        layer.cornerRadius = 16
        layer.masksToBounds = true
        borderLayer.contentsScale = layer.contentsScale
        borderLayer.cornerRadius = 16
        borderLayer.borderWidth = 1
    }

    override internal func setUpLayout() {
        layer.addSublayer(borderLayer)

        addSubview(quotedMessageView)
        addSubview(linkPreviewView)
        addSubview(textView)

        layoutConstraints[.text] = [
            textView.leadingAnchor.pin(equalTo: layoutMarginsGuide.leadingAnchor),
            textView.trailingAnchor.pin(equalTo: layoutMarginsGuide.trailingAnchor),
            textView.topAnchor.pin(equalTo: layoutMarginsGuide.topAnchor),
            textView.bottomAnchor.pin(equalTo: layoutMarginsGuide.bottomAnchor)
        ]

        // link preview cannot exist without text, we can skip `[.linkPreview]` case
        
        layoutConstraints[.quotedMessage] = [
            quotedMessageView.leadingAnchor.pin(equalTo: layoutMarginsGuide.leadingAnchor),
            quotedMessageView.trailingAnchor.pin(equalTo: layoutMarginsGuide.trailingAnchor),
            quotedMessageView.topAnchor.pin(equalTo: layoutMarginsGuide.topAnchor),
            quotedMessageView.bottomAnchor.pin(equalTo: layoutMarginsGuide.bottomAnchor)
        ]

        layoutConstraints[[.text, .linkPreview]] = [
            textView.topAnchor.pin(equalTo: layoutMarginsGuide.topAnchor),
            textView.leadingAnchor.pin(equalTo: layoutMarginsGuide.leadingAnchor),
            textView.trailingAnchor.pin(equalTo: layoutMarginsGuide.trailingAnchor),
            
            linkPreviewView.leadingAnchor.pin(equalTo: layoutMarginsGuide.leadingAnchor),
            linkPreviewView.trailingAnchor.pin(equalTo: layoutMarginsGuide.trailingAnchor),
            linkPreviewView.topAnchor.pin(equalToSystemSpacingBelow: textView.bottomAnchor, multiplier: 1),
            linkPreviewView.bottomAnchor.pin(equalTo: layoutMarginsGuide.bottomAnchor),
            linkPreviewView.widthAnchor.pin(equalToConstant: UIScreen.main.bounds.width * 0.6)
        ]

        layoutConstraints[[.text, .quotedMessage]] = [
            quotedMessageView.leadingAnchor.pin(equalTo: layoutMarginsGuide.leadingAnchor),
            quotedMessageView.trailingAnchor.pin(equalTo: layoutMarginsGuide.trailingAnchor),
            quotedMessageView.topAnchor.pin(equalTo: layoutMarginsGuide.topAnchor),
            
            textView.leadingAnchor.pin(equalTo: layoutMarginsGuide.leadingAnchor),
            textView.trailingAnchor.pin(equalTo: layoutMarginsGuide.trailingAnchor),
            textView.topAnchor.pin(equalToSystemSpacingBelow: quotedMessageView.bottomAnchor, multiplier: 1),
            textView.bottomAnchor.pin(equalTo: layoutMarginsGuide.bottomAnchor)
        ]

        layoutConstraints[[.text, .quotedMessage, .linkPreview]] = [
            quotedMessageView.leadingAnchor.pin(equalTo: layoutMarginsGuide.leadingAnchor),
            quotedMessageView.trailingAnchor.pin(equalTo: layoutMarginsGuide.trailingAnchor),
            quotedMessageView.topAnchor.pin(equalTo: layoutMarginsGuide.topAnchor),
            
            textView.leadingAnchor.pin(equalTo: layoutMarginsGuide.leadingAnchor),
            textView.trailingAnchor.pin(equalTo: layoutMarginsGuide.trailingAnchor),
            textView.topAnchor.pin(equalToSystemSpacingBelow: quotedMessageView.bottomAnchor, multiplier: 1),
            
            linkPreviewView.leadingAnchor.pin(equalTo: layoutMarginsGuide.leadingAnchor),
            linkPreviewView.trailingAnchor.pin(equalTo: layoutMarginsGuide.trailingAnchor),
            linkPreviewView.topAnchor.pin(equalToSystemSpacingBelow: textView.bottomAnchor, multiplier: 1),
            linkPreviewView.bottomAnchor.pin(equalTo: layoutMarginsGuide.bottomAnchor),
            linkPreviewView.widthAnchor.pin(equalToConstant: UIScreen.main.bounds.width * 0.6)
        ]

        // link preview is not visible when any attachment presented,
        // so we can skip `[.text, .attachments, .inlineReply, .linkPreview]` case
    }

    override internal func updateContent() {
        let layoutOptions = message?.layoutOptions ?? []

        quotedMessageView.isParentMessageSentByCurrentUser = message?.isSentByCurrentUser
        quotedMessageView.message = message?.quotedMessage
        quotedMessageView.isVisible = layoutOptions.contains(.quotedMessage)
        
        let font: UIFont = uiConfig.fonts.body
        textView.attributedText = .init(string: message?.textContent ?? "", attributes: [
            .foregroundColor: message?.deletedAt == nil ? uiConfig.colorPalette.text : uiConfig.colorPalette.subtitleText,
            .font: message?.deletedAt == nil ? font : font.italic
        ])
        textView.isVisible = layoutOptions.contains(.text)

        borderLayer.maskedCorners = corners
        borderLayer.isHidden = message == nil

        borderLayer.borderColor = message?.isSentByCurrentUser == true ?
            uiConfig.colorPalette.border.cgColor :
            uiConfig.colorPalette.border.cgColor

        if message?.type == .ephemeral {
            backgroundColor = uiConfig.colorPalette.popoverBackground
        } else if layoutOptions.contains(.linkPreview) {
            backgroundColor = uiConfig.colorPalette.highlightedAccentBackground1
        } else {
            backgroundColor = message?.isSentByCurrentUser == true ?
                uiConfig.colorPalette.background2 :
                uiConfig.colorPalette.popoverBackground
        }

        layer.maskedCorners = corners

        linkPreviewView.content = message?.attachments.first { $0.type.isLink } as? ChatMessageDefaultAttachment

        linkPreviewView.isVisible = layoutOptions.contains(.linkPreview)

        layoutConstraints.values.flatMap { $0 }.forEach { $0.isActive = false }
        layoutConstraints[layoutOptions]?.forEach { $0.isActive = true }
    }

    @objc func didTapOnLinkPreview() {
        onLinkTap(linkPreviewView.content)
    }
    
    // MARK: - Private

    private var corners: CACornerMask {
        var roundedCorners: CACornerMask = [
            .layerMinXMinYCorner,
            .layerMinXMaxYCorner,
            .layerMaxXMinYCorner,
            .layerMaxXMaxYCorner
        ]

        guard message?.isPartOfThread == false else { return roundedCorners }

        switch (message?.isLastInGroup, message?.isSentByCurrentUser) {
        case (true, true):
            roundedCorners.remove(.layerMaxXMaxYCorner)
        case (true, false):
            roundedCorners.remove(.layerMinXMaxYCorner)
        default:
            break
        }
        
        return roundedCorners
    }
}

internal typealias ChatMessageAttachmentBubbleView = _ChatMessageAttachmentBubbleView<NoExtraData>

internal class _ChatMessageAttachmentBubbleView<ExtraData: ExtraDataTypes>: _ChatMessageBubbleView<ExtraData> {
    internal private(set) lazy var attachmentsView = uiConfig
        .messageList
        .messageContentSubviews
        .attachmentSubviews
        .attachmentsView
        .init()
        .withoutAutoresizingMaskConstraints
    
    override internal func setUpLayout() {
        super.setUpLayout()
        
        addSubview(attachmentsView)
        
        layoutConstraints[.attachments] = [
            attachmentsView.leadingAnchor.pin(equalTo: leadingAnchor),
            attachmentsView.trailingAnchor.pin(equalTo: trailingAnchor),
            attachmentsView.topAnchor.pin(equalTo: topAnchor),
            attachmentsView.bottomAnchor.pin(equalTo: bottomAnchor),
            attachmentsView.widthAnchor.pin(equalToConstant: UIScreen.main.bounds.width * 0.6)
        ]
        
        layoutConstraints[[.text, .attachments]] = [
            attachmentsView.leadingAnchor.pin(equalTo: leadingAnchor),
            attachmentsView.trailingAnchor.pin(equalTo: trailingAnchor),
            attachmentsView.topAnchor.pin(equalTo: topAnchor),
            attachmentsView.widthAnchor.pin(equalToConstant: UIScreen.main.bounds.width * 0.6),
            
            textView.leadingAnchor.pin(equalTo: layoutMarginsGuide.leadingAnchor),
            textView.trailingAnchor.pin(equalTo: layoutMarginsGuide.trailingAnchor),
            textView.topAnchor.pin(equalToSystemSpacingBelow: attachmentsView.bottomAnchor, multiplier: 1),
            textView.bottomAnchor.pin(equalTo: layoutMarginsGuide.bottomAnchor)
        ]
        
        layoutConstraints[[.attachments, .quotedMessage]] = [
            quotedMessageView.leadingAnchor.pin(equalTo: layoutMarginsGuide.leadingAnchor),
            quotedMessageView.trailingAnchor.pin(equalTo: layoutMarginsGuide.trailingAnchor),
            quotedMessageView.topAnchor.pin(equalTo: layoutMarginsGuide.topAnchor),
            
            attachmentsView.leadingAnchor.pin(equalTo: leadingAnchor),
            attachmentsView.trailingAnchor.pin(equalTo: trailingAnchor),
            attachmentsView.topAnchor.pin(equalToSystemSpacingBelow: quotedMessageView.bottomAnchor, multiplier: 1),
            attachmentsView.widthAnchor.pin(equalToConstant: UIScreen.main.bounds.width * 0.6),
            attachmentsView.bottomAnchor.pin(equalTo: bottomAnchor)
        ]
        
        layoutConstraints[[.text, .attachments, .quotedMessage]] = [
            quotedMessageView.leadingAnchor.pin(equalTo: layoutMarginsGuide.leadingAnchor),
            quotedMessageView.trailingAnchor.pin(equalTo: layoutMarginsGuide.trailingAnchor),
            quotedMessageView.topAnchor.pin(equalTo: layoutMarginsGuide.topAnchor),
            
            attachmentsView.leadingAnchor.pin(equalTo: leadingAnchor),
            attachmentsView.trailingAnchor.pin(equalTo: trailingAnchor),
            attachmentsView.topAnchor.pin(equalToSystemSpacingBelow: quotedMessageView.bottomAnchor, multiplier: 1),
            attachmentsView.widthAnchor.pin(equalToConstant: UIScreen.main.bounds.width * 0.6),
            
            textView.leadingAnchor.pin(equalTo: layoutMarginsGuide.leadingAnchor),
            textView.trailingAnchor.pin(equalTo: layoutMarginsGuide.trailingAnchor),
            textView.topAnchor.pin(equalToSystemSpacingBelow: attachmentsView.bottomAnchor, multiplier: 1),
            textView.bottomAnchor.pin(equalTo: layoutMarginsGuide.bottomAnchor)
        ]
    }
    
    override internal func updateContent() {
        super.updateContent()
        
        attachmentsView.content = message.flatMap {
            .init(
                attachments: $0.attachments.compactMap { $0 as? ChatMessageDefaultAttachment },
                didTapOnAttachment: message?.didTapOnAttachment,
                didTapOnAttachmentAction: message?.didTapOnAttachmentAction
            )
        }
        
        let layoutOptions = message?.layoutOptions ?? []
        
        attachmentsView.isVisible = layoutOptions.contains(.attachments)
    }
}

// MARK: - LayoutOptions

internal struct ChatMessageBubbleViewLayoutOptions: OptionSet, Hashable {
    internal let rawValue: Int
    
    internal init(rawValue: Int) {
        self.rawValue = rawValue
    }

    internal static let text = Self(rawValue: 1 << 0)
    internal static let attachments = Self(rawValue: 1 << 1)
    internal static let quotedMessage = Self(rawValue: 1 << 2)
    internal static let linkPreview = Self(rawValue: 1 << 3)

    internal static let all: Self = [.text, .attachments, .quotedMessage, .linkPreview]
}

private extension _ChatMessageGroupPart {
    var layoutOptions: ChatMessageBubbleViewLayoutOptions {
        guard message.deletedAt == nil else {
            return [.text]
        }

        var options: ChatMessageBubbleViewLayoutOptions = []

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

// MARK: - Extensions

private extension _ChatMessageGroupPart {
    var textContent: String {
        guard message.type != .ephemeral else {
            return ""
        }

        guard message.deletedAt == nil else {
            return L10n.Message.deletedMessagePlaceholder
        }

        return message.text
    }
}
