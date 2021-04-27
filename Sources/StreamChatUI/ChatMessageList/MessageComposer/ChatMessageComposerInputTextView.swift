//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

open class ChatMessageComposerInputTextView: UITextView, Customizable, AppearanceProvider {
    // MARK: - Properties
            
    lazy var textViewHeightConstraint = heightAnchor.pin(equalToConstant: .zero)
    
    // MARK: - Subviews
    
    public lazy var placeholderLabel: UILabel = UILabel()
        .withoutAutoresizingMaskConstraints
        .withBidirectionalLanguagesSupport

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
        
        setUpAppearance()
        updateContent()
    }
    
    // MARK: Public
        
    open func setUp() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(textDidChange),
            name: UITextView.textDidChangeNotification,
            object: nil
        )
    }
    
    open func setUpAppearance() {
        font = appearance.fonts.body
        textContainer.lineFragmentPadding = 10
        textColor = appearance.colorPalette.text
        
        placeholderLabel.font = font
        placeholderLabel.textColor = appearance.colorPalette.subtitleText
        placeholderLabel.textAlignment = .center
        
        backgroundColor = .clear
    }
    
    open func setUpLayout() {
        embed(
            placeholderLabel,
            insets: .init(
                top: .zero,
                leading: directionalLayoutMargins.leading,
                bottom: .zero,
                trailing: .zero
            )
        )
        placeholderLabel.pin(anchors: [.centerY], to: self)
        
        isScrollEnabled = false
        
        textViewHeightConstraint.isActive = true
    }
    
    open func updateContent() {}

    open func updateHeightConstraint() {
        textViewHeightConstraint.constant = calculatedTextHeight() + textContainerInset.bottom + textContainerInset.top
    }
    
    func textDidChangeProgrammatically() {
        delegate?.textViewDidChange?(self)
        textDidChange()
    }
        
    @objc func textDidChange() {
        placeholderLabel.isHidden = !text.isEmpty

        updateHeightConstraint()
        layoutIfNeeded()
    }
}
