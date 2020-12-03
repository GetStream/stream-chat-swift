//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

open class ChatMessageBubbleView<ExtraData: UIExtraDataTypes>: View, UIConfigProvider {
    struct Layout {
        let text: CGRect?
        let repliedMessage: CGRect?
        /// must be ChatRepliedMessageContentView<ExtraData>.Layout?
        /// but it's circular dependency, swift confused
        let repliesMessageLayout: Any?
        let attachments: [CGRect]
    }

    var layout: Layout? {
        didSet { setNeedsLayout() }
    }
    
    public var message: _ChatMessageGroupPart<ExtraData>? {
        didSet { updateContent() }
    }

    public let showRepliedMessage: Bool
    
    // MARK: - Subviews

    public private(set) var attachments: [UIView] = []
    
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
        return textView
    }()

    public private(set) lazy var repliedMessageView = showRepliedMessage
        ? uiConfig.messageList.messageContentSubviews.repliedMessageContentView.init()
        : nil
    
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

        borderLayer.frame = layer.bounds

        guard let layout = layout else { return }

        textView.isHidden = layout.text == nil
        if let frame = layout.text {
            textView.frame = frame
        }

        repliedMessageView?.isHidden = layout.repliedMessage == nil
        if let frame = layout.repliedMessage {
            repliedMessageView?.frame = frame
        }
        repliedMessageView?.layout = layout.repliesMessageLayout as? ChatRepliedMessageContentView<ExtraData>.Layout

        zip(attachments, layout.attachments).forEach {
            $0.frame = $1
        }
    }

    override public func defaultAppearance() {
        layer.cornerRadius = 16
        borderLayer.cornerRadius = 16
        borderLayer.borderWidth = 1 / UIScreen.main.scale
    }

    override open func setUpLayout() {
        layer.addSublayer(borderLayer)
        if let reply = repliedMessageView {
            addSubview(reply)
        }
        addSubview(textView)
    }

    override open func updateContent() {
        repliedMessageView?.message = message?.parentMessage

        textView.text = message?.text

        borderLayer.maskedCorners = corners
        borderLayer.isHidden = message == nil

        borderLayer.borderColor = message?.isSentByCurrentUser == true ?
            UIColor.outgoingMessageBubbleBorder.cgColor :
            UIColor.incomingMessageBubbleBorder.cgColor

        backgroundColor = message?.isSentByCurrentUser == true ? .outgoingMessageBubbleBackground : .incomingMessageBubbleBackground
        layer.maskedCorners = corners

        // add attachments subviews
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

class ChatMessageBubbleViewLayoutManager<ExtraData: UIExtraDataTypes> {
    let textView: UITextView = {
        let textView = UITextView()
        textView.isEditable = false
        textView.isScrollEnabled = false
        textView.font = .preferredFont(forTextStyle: .body)
        textView.adjustsFontForContentSizeCategory = true
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0
        return textView
    }()

    /// reply sizer depends on bubble sizer, circle dependency
    /// but bubble inside reply don't need reply sizer so it should be fine as long as you not access it unless needed
    lazy var replySizer = ChatRepliedMessageContentViewLayoutManager<ExtraData>()

    func heightForView(with data: _ChatMessageGroupPart<ExtraData>, limitedBy width: CGFloat) -> CGFloat {
        sizeForView(with: data, limitedBy: width).height
    }

    func sizeForView(with data: _ChatMessageGroupPart<ExtraData>, limitedBy width: CGFloat) -> CGSize {
        let margins: CGFloat = 8
        let workWidth = width - 2 * margins

        var spacings = margins

        var replySize: CGSize = .zero
        if data.parentMessageState != nil {
            replySize = replySizer.sizeForView(with: data.parentMessage, limitedBy: workWidth)
            spacings += margins
        }

        // put attachments here

        var textSize: CGSize = .zero
        if !data.text.isEmpty {
            textSize = {
                textView.text = data.message.text
                return textView.sizeThatFits(CGSize(width: workWidth, height: .greatestFiniteMagnitude))
            }()
            spacings += margins
        }
        
        let width = 2 * margins + max(replySize.width, textSize.width)
        let height = spacings + replySize.height + textSize.height
        return CGSize(width: max(width, 32), height: max(height, 32))
    }

    func layoutForView(
        with data: _ChatMessageGroupPart<ExtraData>,
        of size: CGSize
    ) -> ChatMessageBubbleView<ExtraData>.Layout {
        let margins: CGFloat = 8
        let workWidth = size.width - 2 * margins
        var offsetY = margins

        var replyFrame: CGRect?
        var replyLayout: ChatRepliedMessageContentView<ExtraData>.Layout?
        if data.parentMessageState != nil {
            let replySize = replySizer.sizeForView(with: data.parentMessage, limitedBy: workWidth)
            replyLayout = replySizer.layoutForView(with: data.parentMessage, of: replySize)
            replyFrame = CGRect(origin: CGPoint(x: margins, y: offsetY), size: replySize)
            offsetY += replySize.height
            offsetY += margins
        }

        // put attachments here

        let textSize: CGSize = {
            textView.text = data.message.text
            return textView.sizeThatFits(CGSize(width: workWidth, height: .greatestFiniteMagnitude))
        }()
        var textFrame: CGRect?
        if !data.text.isEmpty {
            textFrame = CGRect(origin: CGPoint(x: margins, y: offsetY), size: textSize)
            offsetY += textSize.height
            offsetY += margins
        }

        return ChatMessageBubbleView.Layout(
            text: textFrame,
            repliedMessage: replyFrame,
            repliesMessageLayout: replyLayout,
            attachments: []
        )
    }
}
