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
    
    public private(set) lazy var stackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = UIStackView.spacingUseSystem
        return stack
    }()

    private let textViewContainer = UIView()
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

    public private(set) lazy var imageGallery = uiConfig
        .messageList
        .messageContentSubviews
        .imageGallery
        .init()
        .withoutAutoresizingMaskConstraints

    public private(set) lazy var repliedMessageContainer = showRepliedMessage ? UIView() : nil
    public private(set) lazy var repliedMessageView = showRepliedMessage ?
        uiConfig.messageList.messageContentSubviews.repliedMessageContentView.init().withoutAutoresizingMaskConstraints :
        nil
    
    public private(set) lazy var borderLayer = CAShapeLayer()

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

        embed(stackView)

        if let repliedMessageView = repliedMessageView, let container = repliedMessageContainer {
            container.addSubview(repliedMessageView)
            NSLayoutConstraint.activate([
                repliedMessageView.leadingAnchor.constraint(equalTo: container.layoutMarginsGuide.leadingAnchor),
                repliedMessageView.trailingAnchor.constraint(equalTo: container.layoutMarginsGuide.trailingAnchor),
                repliedMessageView.topAnchor.constraint(equalTo: container.topAnchor),
                repliedMessageView.bottomAnchor.constraint(equalTo: container.bottomAnchor)
            ])
            stackView.addArrangedSubview(container)
        }

        textViewContainer.addSubview(textView)
        NSLayoutConstraint.activate([
            textView.leadingAnchor.constraint(equalTo: textViewContainer.layoutMarginsGuide.leadingAnchor),
            textView.trailingAnchor.constraint(equalTo: textViewContainer.layoutMarginsGuide.trailingAnchor),
            textView.topAnchor.constraint(equalTo: textViewContainer.topAnchor),
            textView.bottomAnchor.constraint(equalTo: textViewContainer.bottomAnchor)
        ])
        stackView.addArrangedSubview(textViewContainer)

        imageGallery.widthAnchor.constraint(equalToConstant: UIScreen.main.bounds.width * 0.65).isActive = true
    }

    override open func updateContent() {
        repliedMessageView?.message = message?.parentMessage
        repliedMessageContainer?.isHidden = message?.parentMessageState == nil

        textView.text = message?.text
        textViewContainer.isHidden = message?.text.isEmpty ?? true

        borderLayer.maskedCorners = corners
        borderLayer.isHidden = message == nil

        borderLayer.borderColor = message?.isSentByCurrentUser == true ?
            UIColor.outgoingMessageBubbleBorder.cgColor :
            UIColor.incomingMessageBubbleBorder.cgColor

        backgroundColor = message?.isSentByCurrentUser == true ? .outgoingMessageBubbleBackground : .incomingMessageBubbleBackground
        layer.maskedCorners = corners

        stackView.removeArrangedSubview(imageGallery)
        imageGallery.imageAttachments = message?.attachments.filter { $0.type == .image } ?? []
        if !imageGallery.imageAttachments.isEmpty {
            stackView.insertArrangedSubview(imageGallery, at: showRepliedMessage ? 1 : 0)
        }
    }
    
    // MARK: - Private

    private var corners: CACornerMask {
        var roundedCorners: CACornerMask = [
            .layerMinXMinYCorner,
            .layerMinXMaxYCorner,
            .layerMaxXMinYCorner,
            .layerMaxXMaxYCorner
        ]
        
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
