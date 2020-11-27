//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

open class ChatMessageBubbleView<ExtraData: UIExtraDataTypes>: View, UIConfigProvider {
    public var message: _ChatMessageGroupPart<ExtraData>? {
        didSet { updateContent() }
    }

    public let showRepliedMessage: Bool
    
    // MARK: - Subviews
    
    public private(set) lazy var stackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = UIStackView.spacingUseSystem
        return stack
    }()
    
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
        return textView
    }()

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
        borderLayer.cornerRadius = 16
        borderLayer.borderWidth = 1 / UIScreen.main.scale
    }

    override open func setUpLayout() {
        layer.addSublayer(borderLayer)

        addSubview(stackView)
        stackView.pin(to: layoutMarginsGuide)

        if let repliedMessageView = repliedMessageView {
            stackView.addArrangedSubview(repliedMessageView)
        }
        stackView.addArrangedSubview(textView)
    }

    override open func updateContent() {
        repliedMessageView?.message = message?.parentMessage
        repliedMessageView?.isHidden = message?.parentMessageState == nil

        textView.text = message?.text
        textView.isHidden = message?.text.isEmpty ?? true

        borderLayer.maskedCorners = corners
        borderLayer.isHidden = message == nil
        borderLayer.borderColor = message?.isSentByCurrentUser == true ?
            UIColor.outgoingMessageBubbleBorder.cgColor :
            UIColor.incomingMessageBubbleBorder.cgColor

        backgroundColor = message?.isSentByCurrentUser == true ? .outgoingMessageBubbleBackground : .incomingMessageBubbleBackground
        layer.maskedCorners = corners
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
