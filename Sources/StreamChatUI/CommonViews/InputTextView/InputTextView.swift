//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// The delegate of the `InputTextView` that notifies when an attachment is pasted in the text view.
public protocol InputTextViewClipboardAttachmentDelegate: AnyObject {
    /// Notifies that an `UIImage` has been pasted into the text view
    /// - Parameters:
    ///   - inputTextView: The `InputTextView` in which the image was pasted
    ///   - image: The `UIImage`
    func inputTextView(_ inputTextView: InputTextView, didPasteImage image: UIImage)
}

/// A view for inputting text with placeholder support. Since it is a subclass
/// of `UITextView`, the `UITextViewDelegate` can be used to observe text changes.
@objc(StreamInputTextView)
open class InputTextView: UITextView, AppearanceProvider {
    /// The delegate which gets notified when an attachment is pasted into the text view
    open weak var clipboardAttachmentDelegate: InputTextViewClipboardAttachmentDelegate?
    
    /// Whether this text view should allow images to be pasted
    open var isPastingImagesEnabled: Bool = true
    
    /// Label used as placeholder for textView when it's empty.
    open private(set) lazy var placeholderLabel: UILabel = UILabel()
        .withoutAutoresizingMaskConstraints
        .withBidirectionalLanguagesSupport
        .withAdjustingFontForContentSizeCategory
    
    override open var text: String! {
        didSet {
            textDidChangeProgrammatically()
        }
    }
    
    /// The minimum height of the text view.
    /// When there is no content in the text view OR the height of the content is less than this value,
    /// the text view will be of this height
    open var minimumHeight: CGFloat {
        38.0
    }
    
    /// The constraint responsible for setting the height of the text view.
    open var heightConstraint: NSLayoutConstraint?
    
    /// The maximum height of the text view.
    /// When the content in the text view is greater than this height, scrolling will be enabled and the text view's height will be restricted to this value
    open var maximumHeight: CGFloat {
        120.0
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
        adjustsFontForContentSizeCategory = true
        
        placeholderLabel.font = font
        placeholderLabel.textColor = appearance.colorPalette.subtitleText
        placeholderLabel.adjustsFontSizeToFitWidth = true
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
        placeholderLabel.widthAnchor.pin(equalTo: widthAnchor, multiplier: 0.95).isActive = true

        heightConstraint = heightAnchor.constraint(equalToConstant: minimumHeight)
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

    override open func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        // Make sure to recalculate height when trait text size changes
        setTextViewHeight()
    }
        
    @objc open func handleTextChange() {
        placeholderLabel.isHidden = !text.isEmpty
        setTextViewHeight()
    }

    open func setTextViewHeight() {
        var heightToSet = minimumHeight

        if contentSize.height <= minimumHeight {
            heightToSet = minimumHeight
        } else if contentSize.height >= maximumHeight {
            heightToSet = maximumHeight
        } else {
            heightToSet = contentSize.height
        }

        heightConstraint?.constant = heightToSet
        heightConstraint?.isActive = true
        layoutIfNeeded()

        // This is due to bug in UITextView where the scroll sometimes disables
        // when a very long text is pasted in it.
        // Doing this ensures that it doesn't happen
        // Reference: https://stackoverflow.com/a/33194525/3825788
        isScrollEnabled = false
        isScrollEnabled = true
    }
    
    // MARK: - Actions on the UITextView
    
    override open func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        // If action is paste and the pasteboard has an image, we allow it
        if action == #selector(paste(_:)) && isPastingImagesEnabled && UIPasteboard.general.hasImages {
            return true
        }

        return super.canPerformAction(action, withSender: sender)
    }

    override open func paste(_ sender: Any?) {
        if let pasteboardImage = UIPasteboard.general.image {
            clipboardAttachmentDelegate?.inputTextView(self, didPasteImage: pasteboardImage)
        } else {
            super.paste(sender)
        }
    }
}
