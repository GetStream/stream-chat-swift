//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

public typealias ChatMessageComposerInputTextView = _ChatMessageComposerInputTextView<NoExtraData>

open class _ChatMessageComposerInputTextView<ExtraData: ExtraDataTypes>: UITextView,
    AppearanceSetting,
    Customizable,
    UIConfigProvider
{
    // MARK: - Properties
            
    lazy var textViewHeightConstraint = heightAnchor.pin(equalToConstant: .zero)
    
    // MARK: - Subviews
    
    public lazy var placeholderLabel: UILabel = UILabel().withoutAutoresizingMaskConstraints
    
    // MARK: - Overrides
    
    override public var text: String! {
        didSet {
            textDidChangeProgrammatically()
        }
    }
    
    override public var attributedText: NSAttributedString! {
        didSet {
            textDidChangeProgrammatically()
        }
    }
    
    override open func didMoveToSuperview() {
        super.didMoveToSuperview()
        guard superview != nil else { return }
        
        setUp()
        setUpLayout()
        (self as! Self).applyDefaultAppearance()
        setUpAppearance()
        updateContent()
    }
    
    // MARK: Public
    
    open func defaultAppearance() {
        font = uiConfig.font.body
        textContainer.lineFragmentPadding = 10
        textColor = uiConfig.colorPalette.text
        
        placeholderLabel.font = font
        placeholderLabel.textColor = uiConfig.colorPalette.subtitleText
        placeholderLabel.textAlignment = .center
        
        backgroundColor = .clear
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
        
        isScrollEnabled = false
        
        textViewHeightConstraint.isActive = true
    }
    
    open func updateContent() {}
    
    func textDidChangeProgrammatically() {
        delegate?.textViewDidChange?(self)
        textDidChange()
    }
        
    @objc func textDidChange() {
        placeholderLabel.isHidden = !text.isEmpty
        textViewHeightConstraint.constant = calculatedTextHeight() + textContainerInset.bottom + textContainerInset.top
        layoutIfNeeded()
    }
}
