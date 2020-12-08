//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

open class ChatMessageBubbleView<ExtraData: UIExtraDataTypes>: View, UIConfigProvider {
    public var message: _ChatMessageGroupPart<ExtraData>? {
        didSet { updateContentIfNeeded() }
    }

    public let showRepliedMessage: Bool
    
    // MARK: - Subviews

    public private(set) lazy var imageGallery = uiConfig
        .messageList
        .messageContentSubviews
        .imageGallery
        .init()
        .withoutAutoresizingMaskConstraints

    public private(set) lazy var textView: UITextView = {
        let textView = UITextView()
        textView.isEditable = false
        textView.dataDetectorTypes = .link
        textView.isScrollEnabled = false
        textView.backgroundColor = .clear
        textView.font = .preferredFont(forTextStyle: .body)
        textView.adjustsFontForContentSizeCategory = true
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0
        textView.isUserInteractionEnabled = false
        return textView.withoutAutoresizingMaskConstraints
    }()

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

    override public func defaultAppearance() {
        layer.cornerRadius = 16
        layer.masksToBounds = true
        borderLayer.cornerRadius = 16
        borderLayer.borderWidth = 1 / UIScreen.main.scale
    }

    override open func setUpLayout() {
        layer.addSublayer(borderLayer)

        if let repliedMessageView = repliedMessageView {
            addSubview(repliedMessageView)
        }
        addSubview(imageGallery)
        addSubview(textView)

        layoutConstraints[.text] = [
            textView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
            textView.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),
            textView.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor),
            textView.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor)
        ]

        layoutConstraints[.images] = [
            imageGallery.leadingAnchor.constraint(equalTo: leadingAnchor),
            imageGallery.trailingAnchor.constraint(equalTo: trailingAnchor),
            imageGallery.topAnchor.constraint(equalTo: topAnchor),
            imageGallery.bottomAnchor.constraint(equalTo: bottomAnchor),
            imageGallery.widthAnchor.constraint(equalToConstant: UIScreen.main.bounds.width * 0.6)
        ]

        layoutConstraints[.inlineReply] = repliedMessageView.flatMap {
            return [
                $0.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
                $0.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),
                $0.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor),
                $0.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor)
            ]
        }

        layoutConstraints[[.text, .images]] = [
            imageGallery.leadingAnchor.constraint(equalTo: leadingAnchor),
            imageGallery.trailingAnchor.constraint(equalTo: trailingAnchor),
            imageGallery.topAnchor.constraint(equalTo: topAnchor),
            imageGallery.widthAnchor.constraint(equalToConstant: UIScreen.main.bounds.width * 0.6),
            
            textView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
            textView.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),
            textView.topAnchor.constraint(equalToSystemSpacingBelow: imageGallery.bottomAnchor, multiplier: 1),
            textView.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor)
        ]

        layoutConstraints[[.text, .inlineReply]] = repliedMessageView.flatMap {
            return [
                $0.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
                $0.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),
                $0.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor),
                
                textView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
                textView.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),
                textView.topAnchor.constraint(equalToSystemSpacingBelow: imageGallery.bottomAnchor, multiplier: 1),
                textView.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor)
            ]
        } ?? layoutConstraints[.text]

        layoutConstraints[[.images, .inlineReply]] = repliedMessageView.flatMap {
            return [
                $0.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
                $0.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),
                $0.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor),
                
                imageGallery.leadingAnchor.constraint(equalTo: leadingAnchor),
                imageGallery.trailingAnchor.constraint(equalTo: trailingAnchor),
                imageGallery.topAnchor.constraint(equalToSystemSpacingBelow: $0.bottomAnchor, multiplier: 1),
                imageGallery.widthAnchor.constraint(equalToConstant: UIScreen.main.bounds.width * 0.6),
                imageGallery.bottomAnchor.constraint(equalTo: bottomAnchor)
            ]
        } ?? layoutConstraints[.images]

        layoutConstraints[[.text, .images, .inlineReply]] = repliedMessageView.flatMap {
            return [
                $0.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
                $0.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),
                $0.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor),
                
                imageGallery.leadingAnchor.constraint(equalTo: leadingAnchor),
                imageGallery.trailingAnchor.constraint(equalTo: trailingAnchor),
                imageGallery.topAnchor.constraint(equalToSystemSpacingBelow: $0.bottomAnchor, multiplier: 1),
                imageGallery.widthAnchor.constraint(equalToConstant: UIScreen.main.bounds.width * 0.6),
                
                textView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
                textView.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),
                textView.topAnchor.constraint(equalToSystemSpacingBelow: imageGallery.bottomAnchor, multiplier: 1),
                textView.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor)
            ]
        } ?? layoutConstraints[[.text, .images]]
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

        backgroundColor = message?.isSentByCurrentUser == true ?
            uiConfig.colorPalette.outgoingMessageBubbleBackground :
            uiConfig.colorPalette.incomingMessageBubbleBackground
        layer.maskedCorners = corners

        imageGallery.data = message.flatMap {
            .init(
                attachments: $0.attachments.filter { $0.type == .image },
                didTapOnAttachment: message?.didTapOnAttachment
            )
        }
        imageGallery.isVisible = layoutOptions.contains(.images)

        layoutConstraints.values.flatMap { $0 }.forEach { $0.isActive = false }
        layoutConstraints[layoutOptions]?.forEach { $0.isActive = true }
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
    static let images = Self(rawValue: 1 << 1)
    static let inlineReply = Self(rawValue: 1 << 2)

    static let all: Self = [.text, .images, .inlineReply]
}

private extension _ChatMessageGroupPart {
    var layoutOptions: LayoutOptions {
        guard message.deletedAt == nil else {
            return [.text]
        }

        var options: LayoutOptions = .all

        if textContent.isEmpty {
            options.remove(.text)
        }

        if !message.attachments.contains(where: { $0.type == .image && $0.imageURL != nil }) {
            options.remove(.images)
        }

        if parentMessageState == nil {
            options.remove(.inlineReply)
        }

        return options
    }
}

// MARK: - Extensions

private extension _ChatMessageGroupPart {
    var textContent: String {
        message.deletedAt == nil ? message.text : L10n.Message.deletedMessagePlaceholder
    }
}
