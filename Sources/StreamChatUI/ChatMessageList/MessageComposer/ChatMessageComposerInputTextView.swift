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
            selector: #selector(handleTextChange),
            name: UITextView.textDidChangeNotification,
            object: nil
        )
    }
    
    open func setUpAppearance() {}
    
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
    }
    
    open func updateContent() {}
    
    func textDidChangeProgrammatically() {
        delegate?.textViewDidChange?(self)
        handleTextChange()
    }
        
    @objc func handleTextChange() {
        placeholderLabel.isHidden = !text.isEmpty
    }
}
