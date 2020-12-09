//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

open class ChatChannelMessageInputTextView<ExtraData: ExtraDataTypes>: UITextView,
    AppearanceSetting,
    Customizable,
    UIConfigProvider
{
    // MARK: - Subviews
    
    public lazy var placeholderLabel: UILabel = UILabel().withoutAutoresizingMaskConstraints
    
    // MARK: - Overrides
    
    override public var text: String! {
        didSet {
            textDidChange()
        }
    }
    
    override public var attributedText: NSAttributedString! {
        didSet {
            textDidChange()
        }
    }
    
    override open func didMoveToSuperview() {
        super.didMoveToSuperview()
        guard superview != nil else { return }
        
        setUp()
        (self as! Self).applyDefaultAppearance()
        setUpAppearance()
        setUpLayout()
        updateContent()
    }
    
    // MARK: Public
    
    open func defaultAppearance() {
        font = .preferredFont(forTextStyle: .callout)
        textContainer.lineFragmentPadding = 10
        
        placeholderLabel.font = font
        placeholderLabel.textColor = uiConfig.colorPalette.messageComposerPlaceholder
        placeholderLabel.textAlignment = .center
    }
    
    open func setUp() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(textDidChange),
            name: UITextView.textDidChangeNotification,
            object: nil
        )
    }
    
    open func setUpAppearance() {}
    
    open func setUpLayout() {
        embed(placeholderLabel, insets: .init(
            top: .zero,
            leading: textContainer.lineFragmentPadding,
            bottom: .zero,
            trailing: .zero
        ))
        placeholderLabel.pin(anchors: [.centerY], to: self)
    }
    
    open func updateContent() {}
    
    @objc func textDidChange() {
        delegate?.textViewDidChange?(self)
        placeholderLabel.isHidden = !text.isEmpty
    }
}
