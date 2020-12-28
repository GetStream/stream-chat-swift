//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

open class ChatMessageBubbleView<ExtraData: ExtraDataTypes>: View, UIConfigProvider {
    public var message: _ChatMessageGroupPart<ExtraData>? {
        didSet { updateContentIfNeeded() }
    }

    public var onLinkTap: (_ChatMessageAttachment<ExtraData>?) -> Void = { _ in }

    public let showRepliedMessage: Bool
    
    // MARK: - Subviews

    public private(set) lazy var attachmentsView = uiConfig
        .messageList
        .messageContentSubviews
        .attachmentSubviews
        .attachmentsView
        .init()
        .withoutAutoresizingMaskConstraints

    public private(set) lazy var textView: UITextView = {
        let textView = OnlyLinkTappableTextView()
        textView.isEditable = false
        textView.dataDetectorTypes = .link
        textView.isScrollEnabled = false
        textView.backgroundColor = .clear
        textView.font = .preferredFont(forTextStyle: .body)
        textView.adjustsFontForContentSizeCategory = true
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0
        return textView.withoutAutoresizingMaskConstraints
    }()

    public private(set) lazy var linkPreviewView = uiConfig
        .messageList
        .messageContentSubviews
        .linkPreviewView
        .init()
        .withoutAutoresizingMaskConstraints

    public private(set) lazy var repliedMessageView = showRepliedMessage ?
        uiConfig.messageList.messageContentSubviews.repliedMessageContentView.init().withoutAutoresizingMaskConstraints :
        nil
    
    public private(set) lazy var borderLayer = CAShapeLayer()

    private var layoutConstraints: [LayoutOptions: [NSLayoutConstraint]] = [:]

    // MARK: - Init
    
    public required init(showRepliedMessage: Bool) {
        self.showRepliedMessage = showRepliedMessage

        super.init(frame: .zero)
    }
    
    public required init?(coder: NSCoder) {
        showRepliedMessage = false
        
        super.init(coder: coder)
    }

    // MARK: - Overrides

    override open func layoutSubviews() {
        super.layoutSubviews()

        borderLayer.frame = bounds
    }

    override open func setUp() {
        super.setUp()
        linkPreviewView.addTarget(self, action: #selector(didTapOnLinkPreview), for: .touchUpInside)
    }

    override public func defaultAppearance() {
        layer.cornerRadius = 16
        layer.masksToBounds = true
        borderLayer.contentsScale = layer.contentsScale
        borderLayer.cornerRadius = 16
        borderLayer.borderWidth = 1
    }

    override open func setUpLayout() {
        layer.addSublayer(borderLayer)

        if let repliedMessageView = repliedMessageView {
            addSubview(repliedMessageView)
        }
        addSubview(attachmentsView)
        addSubview(linkPreviewView)
        addSubview(textView)

        layoutConstraints[.text] = [
            textView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
            textView.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),
            textView.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor),
            textView.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor)
        ]

        // link preview cannot exist without text, we can skip `[.linkPreview]` case

        layoutConstraints[.attachments] = [
            attachmentsView.leadingAnchor.constraint(equalTo: leadingAnchor),
            attachmentsView.trailingAnchor.constraint(equalTo: trailingAnchor),
            attachmentsView.topAnchor.constraint(equalTo: topAnchor),
            attachmentsView.bottomAnchor.constraint(equalTo: bottomAnchor),
            attachmentsView.widthAnchor.constraint(equalToConstant: UIScreen.main.bounds.width * 0.6)
        ]

        layoutConstraints[.inlineReply] = repliedMessageView.flatMap {
            return [
                $0.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
                $0.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),
                $0.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor),
                $0.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor)
            ]
        }

        layoutConstraints[[.text, .attachments]] = [
            attachmentsView.leadingAnchor.constraint(equalTo: leadingAnchor),
            attachmentsView.trailingAnchor.constraint(equalTo: trailingAnchor),
            attachmentsView.topAnchor.constraint(equalTo: topAnchor),
            attachmentsView.widthAnchor.constraint(equalToConstant: UIScreen.main.bounds.width * 0.6),
            
            textView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
            textView.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),
            textView.topAnchor.constraint(equalToSystemSpacingBelow: attachmentsView.bottomAnchor, multiplier: 1),
            textView.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor)
        ]

        layoutConstraints[[.text, .linkPreview]] = [
            textView.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor),
            textView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
            textView.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),
            
            linkPreviewView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
            linkPreviewView.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),
            linkPreviewView.topAnchor.constraint(equalToSystemSpacingBelow: textView.bottomAnchor, multiplier: 1),
            linkPreviewView.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor),
            linkPreviewView.widthAnchor.constraint(equalToConstant: UIScreen.main.bounds.width * 0.6)
        ]

        layoutConstraints[[.text, .inlineReply]] = repliedMessageView.flatMap {
            return [
                $0.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
                $0.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),
                $0.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor),
                
                textView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
                textView.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),
                textView.topAnchor.constraint(equalToSystemSpacingBelow: $0.bottomAnchor, multiplier: 1),
                textView.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor)
            ]
        } ?? layoutConstraints[.text]

        layoutConstraints[[.attachments, .inlineReply]] = repliedMessageView.flatMap {
            return [
                $0.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
                $0.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),
                $0.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor),
                
                attachmentsView.leadingAnchor.constraint(equalTo: leadingAnchor),
                attachmentsView.trailingAnchor.constraint(equalTo: trailingAnchor),
                attachmentsView.topAnchor.constraint(equalToSystemSpacingBelow: $0.bottomAnchor, multiplier: 1),
                attachmentsView.widthAnchor.constraint(equalToConstant: UIScreen.main.bounds.width * 0.6),
                attachmentsView.bottomAnchor.constraint(equalTo: bottomAnchor)
            ]
        } ?? layoutConstraints[.attachments]

        layoutConstraints[[.text, .inlineReply, .linkPreview]] = repliedMessageView.flatMap {
            return [
                $0.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
                $0.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),
                $0.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor),
                
                textView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
                textView.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),
                textView.topAnchor.constraint(equalToSystemSpacingBelow: $0.bottomAnchor, multiplier: 1),
                
                linkPreviewView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
                linkPreviewView.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),
                linkPreviewView.topAnchor.constraint(equalToSystemSpacingBelow: textView.bottomAnchor, multiplier: 1),
                linkPreviewView.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor),
                linkPreviewView.widthAnchor.constraint(equalToConstant: UIScreen.main.bounds.width * 0.6)
            ]
        } ?? layoutConstraints[[.text, .linkPreview]]

        layoutConstraints[[.text, .attachments, .inlineReply]] = repliedMessageView.flatMap {
            return [
                $0.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
                $0.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),
                $0.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor),
                
                attachmentsView.leadingAnchor.constraint(equalTo: leadingAnchor),
                attachmentsView.trailingAnchor.constraint(equalTo: trailingAnchor),
                attachmentsView.topAnchor.constraint(equalToSystemSpacingBelow: $0.bottomAnchor, multiplier: 1),
                attachmentsView.widthAnchor.constraint(equalToConstant: UIScreen.main.bounds.width * 0.6),
                
                textView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
                textView.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),
                textView.topAnchor.constraint(equalToSystemSpacingBelow: attachmentsView.bottomAnchor, multiplier: 1),
                textView.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor)
            ]
        } ?? layoutConstraints[[.text, .attachments]]

        // link preview is not visible when any attachment presented,
        // so we can skip `[.text, .attachments, .inlineReply, .linkPreview]` case
    }

    override open func updateContent() {
        let layoutOptions = message?.layoutOptions ?? []

        repliedMessageView?.message = message?.parentMessage
        repliedMessageView?.isVisible = layoutOptions.contains(.inlineReply)
        
        let font = UIFont.preferredFont(forTextStyle: .body)
        textView.attributedText = .init(string: message?.textContent ?? "", attributes: [
            .foregroundColor: message?.deletedAt == nil ? UIColor.black : uiConfig.colorPalette.messageTimestampText,
            .font: message?.deletedAt == nil ? font : font.italic
        ])
        textView.isVisible = layoutOptions.contains(.text)

        borderLayer.maskedCorners = corners
        borderLayer.isHidden = message == nil

        borderLayer.borderColor = message?.isSentByCurrentUser == true ?
            uiConfig.colorPalette.outgoingMessageBubbleBorder.cgColor :
            uiConfig.colorPalette.incomingMessageBubbleBorder.cgColor

        if message?.type == .ephemeral {
            backgroundColor = uiConfig.colorPalette.ephemeralMessageBubbleBackground
        } else if layoutOptions.contains(.linkPreview) {
            backgroundColor = uiConfig.colorPalette.linkMessageBubbleBackground
        } else {
            backgroundColor = message?.isSentByCurrentUser == true ?
                uiConfig.colorPalette.outgoingMessageBubbleBackground :
                uiConfig.colorPalette.incomingMessageBubbleBackground
        }

        layer.maskedCorners = corners

        attachmentsView.content = message.flatMap {
            .init(
                attachments: $0.attachments,
                didTapOnAttachment: message?.didTapOnAttachment,
                didTapOnAttachmentAction: message?.didTapOnAttachmentAction
            )
        }
        linkPreviewView.content = message?.attachments.first { $0.type == .link }

        attachmentsView.isVisible = layoutOptions.contains(.attachments)
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

// MARK: - LayoutOptions

private struct LayoutOptions: OptionSet, Hashable {
    let rawValue: Int

    static let text = Self(rawValue: 1 << 0)
    static let attachments = Self(rawValue: 1 << 1)
    static let inlineReply = Self(rawValue: 1 << 2)
    static let linkPreview = Self(rawValue: 1 << 3)

    static let all: Self = [.text, .attachments, .inlineReply, .linkPreview]
}

private extension _ChatMessageGroupPart {
    var layoutOptions: LayoutOptions {
        guard message.deletedAt == nil else {
            return [.text]
        }

        var options: LayoutOptions = []

        if !textContent.isEmpty {
            options.insert(.text)
        }

        if parentMessageState != nil {
            options.insert(.inlineReply)
        }

        if message.attachments.contains(where: { $0.isImageOrGIF || $0.type == .file }) {
            options.insert(.attachments)
        } else if message.attachments.contains(where: { $0.type == .link }) {
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
