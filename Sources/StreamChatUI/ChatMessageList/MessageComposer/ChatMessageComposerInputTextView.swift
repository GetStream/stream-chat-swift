//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

internal typealias ChatMessageComposerInputTextView = _ChatMessageComposerInputTextView<NoExtraData>

internal class _ChatMessageComposerInputTextView<ExtraData: ExtraDataTypes>: UITextView,
    AppearanceSetting,
    Customizable,
    UIConfigProvider
{
    // MARK: - Subviews
    
    internal lazy var placeholderLabel: UILabel = UILabel()
        .withoutAutoresizingMaskConstraints
        .withBidirectionalLanguagesSupport

    // MARK: - Overrides
    
    override internal var text: String! {
        didSet {
            textDidChangeProgrammatically()
        }
    }
    
    override internal var attributedText: NSAttributedString! {
        didSet {
            textDidChangeProgrammatically()
        }
    }
    
    override internal func didMoveToSuperview() {
        super.didMoveToSuperview()
        guard superview != nil else { return }
        
        setUp()
        setUpLayout()
        (self as! Self).applyDefaultAppearance()
        setUpAppearance()
        updateContent()
    }
    
    // MARK: internal
    
    internal func defaultAppearance() {
        font = uiConfig.fonts.body
        textContainer.lineFragmentPadding = 10
        textColor = uiConfig.colorPalette.text
        
        placeholderLabel.font = font
        placeholderLabel.textColor = uiConfig.colorPalette.subtitleText
        placeholderLabel.textAlignment = .center
        
        backgroundColor = .clear
    }
    
    internal func setUp() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleTextChange),
            name: UITextView.textDidChangeNotification,
            object: nil
        )
    }
    
    internal func setUpAppearance() {}
    
    internal func setUpLayout() {
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
    
    internal func updateContent() {}
    
    func textDidChangeProgrammatically() {
        delegate?.textViewDidChange?(self)
        handleTextChange()
    }
        
    @objc func handleTextChange() {
        placeholderLabel.isHidden = !text.isEmpty
    }
}
