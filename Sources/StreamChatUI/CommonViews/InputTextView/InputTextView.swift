//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// A view for inputting text with placeholder support. Since it is a subclass
/// of `UITextView`, the `UITextViewDelegate` can be used to observe text changes.
open class InputTextView: UITextView, AppearanceProvider {
    /// Label used as placeholder for textView when it's empty.
    open private(set) lazy var placeholderLabel: UILabel = UILabel()
        .withoutAutoresizingMaskConstraints
        .withBidirectionalLanguagesSupport
    
    override open var text: String! {
        didSet {
            textDidChangeProgrammatically()
        }
    }
    
    override open var attributedText: NSAttributedString! {
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
    }
        
    open func setUp() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleTextChange),
            name: UITextView.textDidChangeNotification,
            object: self
        )
    }
    
    open func setUpAppearance() {
        backgroundColor = .clear
        textContainer.lineFragmentPadding = 8
        font = appearance.fonts.body
        textColor = appearance.colorPalette.text
        textAlignment = .natural
        
        placeholderLabel.font = font
        placeholderLabel.textAlignment = .center
        placeholderLabel.textColor = appearance.colorPalette.subtitleText
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
    }

    /// Sets the given text in the current caret position.
    /// In case the caret is selecting a range of text, it replaces that text.
    ///
    /// - Parameter text: A string to replace the text in the caret position.
    open func replaceSelectedText(_ text: String) {
        guard let selectedRange = selectedTextRange else {
            self.text.append(text)
            return
        }

        replace(selectedRange, withText: text)
    }

    open func textDidChangeProgrammatically() {
        delegate?.textViewDidChange?(self)
        handleTextChange()
    }
        
    @objc open func handleTextChange() {
        placeholderLabel.isHidden = !text.isEmpty
    }
}
