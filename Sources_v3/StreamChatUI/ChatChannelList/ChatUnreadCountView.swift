//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

open class ChatUnreadCountView: View {
    // MARK: - Properties
    
    public var inset: CGFloat = 3
    
    override open var intrinsicContentSize: CGSize {
        let height: CGFloat = max(unreadCountLabel.font.pointSize + inset * 2, frame.height)
        let width = max(unreadCountLabel.intrinsicContentSize.width + inset * 2, height)
        return .init(width: width, height: height)
    }
    
    public var unreadCount: ChannelUnreadCount = .noUnread {
        didSet {
            updateContent()
        }
    }
    
    // MARK: - Subviews
    
    private lazy var unreadCountLabel = UILabel().withoutAutoresizingMaskConstraints
    
    // MARK: - Init
    
    override public init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    private func commonInit() {
        updateContent()
    }
    
    // MARK: - Layout
    
    override open func invalidateIntrinsicContentSize() {
        super.invalidateIntrinsicContentSize()
        
        unreadCountLabel.invalidateIntrinsicContentSize()
    }
    
    override open func layoutSubviews() {
        super.layoutSubviews()
        
        invalidateIntrinsicContentSize()
                
        layer.cornerRadius = intrinsicContentSize.height / 2
    }
    
    // MARK: - Public
    
    override open func setUpAppearance() {
        layer.masksToBounds = true
        backgroundColor = .systemRed
        unreadCountLabel.textColor = .white
        unreadCountLabel.font = uiConfig.font.captionBold
        unreadCountLabel.adjustsFontForContentSizeCategory = true
        unreadCountLabel.textAlignment = .center
    }

    override open func setUpLayout() {
        embed(unreadCountLabel, insets: .init(top: inset, leading: inset, bottom: inset, trailing: inset))
        setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
    }
    
    override open func updateContent() {
        isHidden = unreadCount.mentionedMessages == 0 && unreadCount.messages == 0
        unreadCountLabel.text = String(unreadCount.messages)
    }
}
