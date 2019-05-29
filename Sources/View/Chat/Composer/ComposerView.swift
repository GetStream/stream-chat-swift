//
//  ComposerView.swift
//  GetStreamChat
//
//  Created by Alexey Bukhtin on 10/04/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa
import RxKeyboard

public final class ComposerView: UIView {
    
    public var style: ComposerViewStyle?
    
    private var styleState: ComposerViewStyle.State = .disabled {
        didSet {
            if styleState != oldValue, let style = style {
                let styleState = style.style(with: self.styleState)
                layer.borderWidth = styleState.borderWidth
                layer.borderColor = styleState.tintColor.cgColor
                textView.tintColor = styleState.tintColor
                sendButton.tintColor = styleState.tintColor
                attachmentButton.tintColor = styleState.tintColor
            }
        }
    }
    
    private var styleStateStyle: ComposerViewStyle.Style? {
        return style?.style(with: styleState)
    }
    
    public var isEditing: Bool = false
    
    /// A stack view for containers.
    private lazy var stackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [attachmentsCollectionView, buttonsStackView])
        stackView.axis = .vertical
        return stackView
    }()
    
    // MARK: - Text View Container
    
    private lazy var buttonsStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [sendButton, activityIndicatorView])
        stackView.axis = .horizontal
        stackView.alignment = .fill
        stackView.distribution = .fill
        return stackView
    }()
    
    /// An `UITextView`.
    /// You have to use the `text` property to change the value of the text view.
    public private(set) lazy var textView: UITextView = {
        let textView = UITextView(frame: .zero)
        textView.delegate = self
        textView.attributedText = attributedText()
        textView.showsVerticalScrollIndicator = false
        textView.showsHorizontalScrollIndicator = false
        textView.isScrollEnabled = false
        return textView
    }()
    
    private var previousTextBeforeReset: NSAttributedString?
    
    private func attributedText(text: String = "", textColor: UIColor? = nil) -> NSAttributedString {
        guard let style = style else {
            return NSAttributedString(string: text)
        }
        
        return NSAttributedString(string: text, attributes: [.foregroundColor: textColor ?? style.textColor,
                                                             .font: style.font,
                                                             .paragraphStyle: NSParagraphStyle.default])
    }
    
    /// A placeholder label.
    /// You have to use the `placeholderText` property to change the value of the placeholder label.
    public private(set) lazy var placeholderLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.textColor = style?.placeholderTextColor
        textView.addSubview(label)
        
        label.snp.makeConstraints { make in
            make.left.equalTo(textView.textContainer.lineFragmentPadding)
            make.top.equalTo(textView.textContainerInset.top)
            make.right.equalToSuperview()
        }
        
        return label
    }()
    
    /// A send button.
    public private(set) lazy var sendButton: UIButton = {
        let button = UIButton(frame: .zero)
        button.setImage(UIImage.Icons.send, for: .normal)
        button.snp.makeConstraints { $0.width.equalTo(CGFloat.composerButtonWidth).priority(999) }
        button.isHidden = true
        button.backgroundColor = backgroundColor
        return button
    }()
    
    private(set) lazy var attachmentButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(UIImage.Icons.plus, for: .normal)
        button.snp.makeConstraints { $0.width.equalTo(CGFloat.composerButtonWidth).priority(999) }
        button.backgroundColor = backgroundColor
        return button
    }()

    /// An `UIActivityIndicatorView`.
    public private(set) lazy var activityIndicatorView = UIActivityIndicatorView(style: .gray)
    
    /// The text of the text view.
    public var text: String {
        get {
            return textView.attributedText.string.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        set {
            textView.attributedText = attributedText(text: newValue)
            updatePlaceholder()
        }
    }
    
    /// The placeholder text.
    public var placeholderText: String {
        get { return placeholderLabel.attributedText?.string ?? "" }
        set { placeholderLabel.attributedText = attributedText(text: newValue, textColor: styleStateStyle?.tintColor) }
    }
    
    private let disposeBag = DisposeBag()
    private weak var heightConstraint: Constraint?
    private weak var bottomConstraint: Constraint?
    private var baseTextHeight = CGFloat.greatestFiniteMagnitude
    
    /// Enables the detector of links in the text.
    public var linksDetectorEnabled = false
    var detectedURL: URL?
    
    // MARK: - Images Collection View
    
    /// Picked images.
    public var images: [UIImage] = []
    
    private lazy var attachmentsCollectionView: UICollectionView = {
        let collectionViewLayout = UICollectionViewFlowLayout()
        collectionViewLayout.scrollDirection = .horizontal
        collectionViewLayout.itemSize = CGSize(width: .composerAttachmentWidth, height: .composerAttachmentHeight)
        collectionViewLayout.minimumLineSpacing = 1
        collectionViewLayout.minimumInteritemSpacing = 0
        collectionViewLayout.sectionInset = UIEdgeInsets(top: 0, left: .composerInnerPadding, bottom: 0, right: .composerInnerPadding)
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: collectionViewLayout)
        collectionView.isHidden = true
        collectionView.backgroundColor = backgroundColor
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.alwaysBounceHorizontal = true
        collectionView.dataSource = self
        collectionView.register(cellType: AttachmentCollectionViewCell.self)
        collectionView.snp.makeConstraints { $0.height.equalTo(CGFloat.composerAttachmentsHeight) }
        
        return collectionView
    }()
    
    // MARK: -
    
    public func addToSuperview(_ view: UIView, placeholderText: String = "Write a message") {
        guard let style = style else {
            return
        }
        
        // Add to superview.
        view.addSubview(self)
        
        snp.makeConstraints { make in
            make.left.equalToSuperview().offset(CGFloat.messageEdgePadding)
            make.right.equalToSuperview().offset(-CGFloat.messageEdgePadding)
            heightConstraint = make.height.equalTo(CGFloat.composerHeight).constraint
            let bottomMargin = view.safeAreaLayoutGuide.snp.bottomMargin
            bottomConstraint = make.bottom.equalTo(bottomMargin).offset(-CGFloat.messageEdgePadding).constraint
        }
        
        // Apply style.
        backgroundColor = style.backgroundColor
        clipsToBounds = true
        layer.cornerRadius = style.cornerRadius
        layer.borderWidth = styleStateStyle?.borderWidth ?? 0
        layer.borderColor = styleStateStyle?.tintColor.cgColor ?? nil
        
        // Add attachment button.
        addSubview(attachmentButton)
        
        attachmentButton.snp.makeConstraints { make in
            make.height.equalTo(CGFloat.composerHeight)
            make.left.equalToSuperview()
            make.bottom.equalToSuperview()
        }
        
        // Add buttons.
        addSubview(buttonsStackView)
        
        buttonsStackView.snp.makeConstraints { make in
            make.height.equalTo(CGFloat.composerHeight)
            make.right.bottom.equalToSuperview()
        }
        
        // Add text view.
        addSubview(textView)
        updateTextHeightIfNeeded()
        textView.keyboardAppearance = style.textColor.isDark ? .default : .dark
        textView.backgroundColor = backgroundColor
        
        textView.snp.makeConstraints { make in
            make.left.equalTo(attachmentButton.snp.right)
            make.top.equalToSuperview().offset(textViewPadding)
            make.bottom.equalToSuperview().offset(-textViewPadding)
            make.right.lessThanOrEqualTo(buttonsStackView.snp.left)
            make.right.equalToSuperview().priority(.high)
        }
        
        if style.backgroundColor == .clear {
            addBlurredBackground(blurEffectStyle: style.textColor.isDark ? .extraLight : .dark)
        }
        
        // Add placeholder.
        self.placeholderText = placeholderText
        
        let toolBar = UIToolbar(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: .messagesToComposerPadding))
        toolBar.isHidden = true
        textView.inputAccessoryView = toolBar
        
        // Observe the keyboard moving.
        RxKeyboard.instance.visibleHeight
            .drive(onNext: { [weak self] height in
                guard let self = self, let parentView = self.superview else {
                    return
                }
                
                let bottom: CGFloat = .messageEdgePadding
                    + max(0, height - (height > 0 ? parentView.safeAreaBottomOffset + .messagesToComposerPadding : 0))
                
                self.bottomConstraint?.update(offset: -bottom)
                self.styleState = height > .messageEdgePadding ? (self.isEditing ? .edit : .active) : .normal
            })
            .disposed(by: disposeBag)
    }
    
    private func addBlurredBackground(blurEffectStyle: UIBlurEffect.Style) {
        let isDark = blurEffectStyle == .dark
        
        guard !UIAccessibility.isReduceTransparencyEnabled else {
            backgroundColor = isDark ? .chatDarkGray : .chatComposer
            return
        }
        
        let blurEffect = UIBlurEffect(style: blurEffectStyle)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.isUserInteractionEnabled = false
        insertSubview(blurView, at: 0)
        blurView.makeEdgesEqualToSuperview()
        
        let adjustingView = UIView(frame: .zero)
        adjustingView.isUserInteractionEnabled = false
        adjustingView.backgroundColor = .init(white: isDark ? 1 : 0, alpha: isDark ? 0.25 : 0.1)
        insertSubview(adjustingView, at: 0)
        adjustingView.makeEdgesEqualToSuperview()
    }
    
    /// Check if the content is valid: text is not empty or at least one image was added.
    public var isValidContent: Bool {
        return textView.attributedText.length != 0 || !images.isEmpty
    }
    
    /// Reset states of all child views and clear all added/generated data.
    public func reset() {
        isEnabled = true
        isEditing = false
        previousTextBeforeReset = textView.attributedText
        textView.attributedText = attributedText()
        images = []
        attachmentsCollectionView.isHidden = true
        attachmentsCollectionView.reloadData()
        activityIndicatorView.stopAnimating()
        updatePlaceholder()
        updateTextHeightIfNeeded()
        styleState = .normal
        
        if textView.isFirstResponder {
            textView.resignFirstResponder()
        }
    }
    
    /// Toggle `isUserInteractionEnabled` states for all child views.
    public var isEnabled: Bool = true {
        didSet {
            textView.isUserInteractionEnabled = isEnabled
            sendButton.isEnabled = isEnabled
            attachmentButton.isEnabled = isEnabled
            attachmentsCollectionView.isUserInteractionEnabled = isEnabled
            attachmentsCollectionView.alpha = isEnabled ? 1 : 0.5
            styleState = isEnabled ? .normal : .disabled
        }
    }
    
    /// Update the placeholder and send button visibility.
    public func updatePlaceholder() {
        placeholderLabel.isHidden = textView.attributedText.length != 0
        DispatchQueue.main.async { [weak self] in self?.updateSendButton() }
    }
    
    private func updateSendButton() {
        sendButton.isHidden = text.count == 0
    }
}

// MARK: - Text View Height

extension ComposerView {
    
    private var textViewPadding: CGFloat {
        return (CGFloat.composerHeight - baseTextHeight) / 2
    }
    
    private var textViewContentSize: CGSize {
        return textView.sizeThatFits(CGSize(width: textView.frame.width, height: .greatestFiniteMagnitude))
    }
    
    /// Update the height of the text view for a big text length.
    func updateTextHeightIfNeeded() {
        if baseTextHeight == .greatestFiniteMagnitude {
            let text = textView.attributedText
            textView.attributedText = attributedText(text: "T")
            baseTextHeight = textViewContentSize.height.rounded()
            textView.attributedText = text
        }
        
        updateTextHeight(textView.attributedText.length > 0 ? textViewContentSize.height.rounded() : baseTextHeight)
    }
    
    private func updateTextHeight(_ height: CGFloat) {
        guard let heightConstraint = heightConstraint else {
            return
        }
        
        var height = min(max(height + 2 * textViewPadding, CGFloat.composerHeight), CGFloat.composerMaxHeight)
        textView.isScrollEnabled = height == CGFloat.composerMaxHeight
        attachmentsCollectionView.isHidden = images.count == 0
        
        if !attachmentsCollectionView.isHidden {
            height += CGFloat.composerAttachmentsHeight
        }
        
        if heightConstraint.layoutConstraints.first?.constant != height {
            heightConstraint.update(offset: height)
            setNeedsLayout()
            layoutIfNeeded()
        }
    }
}

// MARK: - Text View Delegate

extension ComposerView: UITextViewDelegate {
    
    public func textViewDidBeginEditing(_ textView: UITextView) {
        updateTextHeightIfNeeded()
        updateSendButton()
    }
    
    public func textViewDidEndEditing(_ textView: UITextView) {
        updateTextHeightIfNeeded()
        updatePlaceholder()
    }
    
    public func textViewDidChange(_ textView: UITextView) {
        updatePlaceholder()
        updateTextHeightIfNeeded()
    }
}

// MARK: - Images Collection View

extension ComposerView: UICollectionViewDataSource {
    
    /// Enables the image picking with a given view controller.
    /// The view controller will be used to present `UIImagePickerController`.
//    public func enableImagePicking(with viewController: UIViewController) {
//        filePickerButton.isHidden = false
//
//        filePickerButton.addTap { [weak self, weak viewController] _ in
//            if let self = self, let viewController = viewController {
//                viewController.view.endEditing(true)
//                self.imagePickerButton.isEnabled = false
//
//                viewController.pickImage { info, authorizationStatus, removed in
//                    if let image = info[.originalImage] as? UIImage {
//                        self.images.insert(image, at: 0)
//                        self.imagesCollectionView.reloadData()
//                        self.updateTextHeightIfNeeded()
//                    } else if authorizationStatus != .authorized {
//                        print("❌ Photos authorization status: ", authorizationStatus)
//                    }
//
//                    if !self.textView.isFirstResponder {
//                        self.textView.becomeFirstResponder()
//                    }
//
//                    if authorizationStatus == .authorized || authorizationStatus == .notDetermined {
//                        self.imagePickerButton.isEnabled = true
//                    }
//                }
//            }
//        }
//    }
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return images.count
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(for: indexPath) as AttachmentCollectionViewCell
        cell.imageView.image = images[indexPath.item]
        
//        cell.removeButton.addTap { [weak self] _ in
//            if let self = self {
//                self.images.remove(at: indexPath.item)
//                self.imagesCollectionView.reloadData()
//                self.updateTextHeightIfNeeded()
//            }
//        }
        
        return cell
    }
}
