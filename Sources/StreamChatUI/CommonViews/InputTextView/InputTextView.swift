//
// Copyright © 2021 Stream.io Inc. All rights reserved.
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
    var handleToolkitToggle: ((_ isHidden: Bool) -> Void)?

    /// Whether this text view should allow images to be pasted
    open var isPastingImagesEnabled: Bool = true
    
    /// Label used as placeholder for textView when it's empty.
    open private(set) lazy var placeholderLabel: UILabel = UILabel()
        .withoutAutoresizingMaskConstraints
        .withBidirectionalLanguagesSupport
    
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
        spellCheckingType = .no
        autocorrectionType = .no
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
        
        heightConstraint = heightAnchor.constraint(equalToConstant: minimumHeight)
        heightConstraint?.isActive = true
        isScrollEnabled = true
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
        setTextViewHeight()
        //NSObject.cancelPreviousPerformRequests(withTarget: self)
        //perform(#selector(handleKeyboardDisplay), with: nil, afterDelay: 0.3)
    }

//    @objc func handleKeyboardDisplay() {
//        if text.isEmpty && spellCheckingType == .default {
//            resignFirstResponder()
//            spellCheckingType = .no
//            autocorrectionType = .no
//            becomeFirstResponder()
//            setNeedsDisplay()
//            handleToolkitToggle?(false)
//        } else if !text.isEmpty && spellCheckingType == .no {
//            resignFirstResponder()
//            spellCheckingType = .default
//            autocorrectionType = .default
//            becomeFirstResponder()
//            setNeedsDisplay()
//            handleToolkitToggle?(true)
//        }
//    }

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
