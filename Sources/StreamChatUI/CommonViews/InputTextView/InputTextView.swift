//
// Copyright © 2024 Stream.io Inc. All rights reserved.
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

    override open var intrinsicContentSize: CGSize {
        .init(width: UIView.noIntrinsicMetric, height: minimumHeight)
    }

    private var oldText: String = ""
    private var oldSize: CGSize = .zero
    private var shouldScrollAfterHeightChanged = false

    override open func didMoveToSuperview() {
        super.didMoveToSuperview()
        guard superview != nil else { return }

        setUp()
        setUpLayout()
        setUpAppearance()
    }

    override open func layoutSubviews() {
        super.layoutSubviews()

        if text == oldText, bounds.size == oldSize { return }
        oldText = text
        oldSize = bounds.size

        let size = sizeThatFits(CGSize(width: bounds.size.width, height: CGFloat.greatestFiniteMagnitude))
        var height = size.height

        // Constrain minimum height
        height = minimumHeight > 0 ? max(height, minimumHeight) : height

        // Constrain maximum height
        height = maximumHeight > 0 ? min(height, maximumHeight) : height

        // Update height constraint if needed
        if height != heightConstraint!.constant {
            shouldScrollAfterHeightChanged = true
            heightConstraint!.constant = height
        } else if shouldScrollAfterHeightChanged {
            shouldScrollAfterHeightChanged = false
            scrollToCaretPosition(animated: true)
        }
    }

    open func setUp() {
        contentMode = .redraw

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleTextChange),
            name: UITextView.textDidChangeNotification,
            object: self
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(textDidEndEditing),
            name: UITextView.textDidEndEditingNotification,
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

        // This makes scrollToCaretPosition() more precise.
        // This should be disabled by default according to Apple, but in some iOS versions is not.
        // Reference: https://stackoverflow.com/a/48602171/5493299
        layoutManager.allowsNonContiguousLayout = false

        placeholderLabel.font = font
        placeholderLabel.textColor = appearance.colorPalette.subtitleText
        placeholderLabel.adjustsFontSizeToFitWidth = true
    }

    open func setUpLayout() {
        addSubview(placeholderLabel)
        NSLayoutConstraint.activate([
            placeholderLabel.leadingAnchor.pin(equalTo: leadingAnchor, constant: directionalLayoutMargins.leading),
            placeholderLabel.trailingAnchor.pin(lessThanOrEqualTo: trailingAnchor),
            placeholderLabel.topAnchor.pin(equalTo: topAnchor),
            placeholderLabel.bottomAnchor.pin(lessThanOrEqualTo: bottomAnchor),
            
            placeholderLabel.centerYAnchor.pin(equalTo: centerYAnchor)
        ])

        heightConstraint = heightAnchor.pin(equalToConstant: minimumHeight)
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
        setNeedsLayout()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            // This is due to bug in UITextView where the scroll sometimes disables
            // when a very long text is pasted in it.
            // Doing this ensures that it doesn't happen
            // Reference: https://stackoverflow.com/a/62386088/5493299

            self?.isScrollEnabled = false
            self?.layoutIfNeeded()
            self?.isScrollEnabled = true
        }
    }

    @objc func textDidEndEditing(notification: Notification) {
        if let sender = notification.object as? InputTextView, sender == self {
            scrollToCaretPosition(animated: true)
        }
    }

    @available(*, deprecated, message: "The calculations made by this method are now happening in a more consistent way inside layoutSubviews. This method is not being used now.")
    open func setTextViewHeight() {
        var heightToSet = minimumHeight

        if contentSize.height <= minimumHeight {
            heightToSet = minimumHeight
        } else if contentSize.height >= maximumHeight {
            heightToSet = maximumHeight
        } else {
            heightToSet = contentSize.height
        }

        // This is due to bug in UITextView where the scroll sometimes disables
        // when a very long text is pasted in it.
        // Doing this ensures that it doesn't happen
        // Reference: https://stackoverflow.com/a/62386088/5493299
        isScrollEnabled = false
        heightConstraint?.constant = heightToSet
        layoutIfNeeded()
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
        if isPastingImagesEnabled, let pasteboardImage = UIPasteboard.general.image {
            clipboardAttachmentDelegate?.inputTextView(self, didPasteImage: pasteboardImage)
        } else {
            super.paste(sender)
        }
        setNeedsDisplay()
    }

    /// Scrolls the text view to to the caret's position.
    public func scrollToCaretPosition(animated: Bool) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            guard let selectedTextRange = self.selectedTextRange else { return }
            let caret = self.caretRect(for: selectedTextRange.start)
            guard !self.bounds.contains(caret.origin) else { return }
            self.scrollRectToVisible(caret, animated: animated)
        }
    }
}
