//
//  ComposerView.swift
//  StreamChat
//
//  Created by Alexey Bukhtin on 10/04/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import UIKit
import StreamChatCore
import SnapKit
import RxSwift
import RxCocoa

/// A composer view.
public final class ComposerView: UIView {
    
    /// A composer view  style.
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
    
    /// An `UITextView`.
    /// You have to use the `text` property to change the value of the text view.
    public private(set) lazy var textView = setupTextView()
    var textViewTopConstraint: Constraint?
    var toolBar = UIToolbar(frame: CGRect(width: UIScreen.main.bounds.width, height: .messagesToComposerPadding))
    
    /// An action for a plus button in the images attachments collection view.
    public var imagesAddAction: AttachmentCollectionViewCell.TapAction?
    
    private var previousTextBeforeReset: NSAttributedString?
    private let disposeBag = DisposeBag()
    private(set) weak var heightConstraint: Constraint?
    private weak var bottomConstraint: Constraint?
    var baseTextHeight = CGFloat.greatestFiniteMagnitude
    
    /// An images collection view.
    public private(set) lazy var imagesCollectionView = setupImagesCollectionView()
    /// A files stack view.
    public private(set) lazy var filesStackView = setupFilesStackView()
    
    /// Uploader for images and files.
    public var uploader: Uploader?
    
    /// An editing state of the composer.
    public var isEditing: Bool = false
    
    func attributedText(text: String = "", textColor: UIColor? = nil) -> NSAttributedString {
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
    
    /// An attachment button.
    public private(set) lazy var attachmentButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(UIImage.Icons.plus, for: .normal)
        button.snp.makeConstraints { $0.width.equalTo(CGFloat.composerButtonWidth).priority(999) }
        button.backgroundColor = backgroundColor
        return button
    }()
    
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
    
    // MARK: -
    
    
    /// Add the composer to a view.
    ///
    /// - Parameters:
    ///   - view: a superview.
    ///   - placeholderText: a placeholder text.
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
            bottomConstraint = make.bottom.equalTo(bottomMargin).offset(-CGFloat.messageBottomPadding).constraint
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
        addSubview(sendButton)
        
        sendButton.snp.makeConstraints { make in
            make.height.equalTo(CGFloat.composerHeight)
            make.right.bottom.equalToSuperview()
        }
        
        // Images Collection View.
        addSubview(imagesCollectionView)
        
        imagesCollectionView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalToSuperview()
        }
        
        // Files Stack View.
        addSubview(filesStackView)
        
        filesStackView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalToSuperview()
        }
        
        // Add text view.
        addSubview(textView)
        updateTextHeightIfNeeded()
        textView.keyboardAppearance = style.textColor.isDark ? .default : .dark
        textView.backgroundColor = backgroundColor
        
        textView.snp.makeConstraints { make in
            textViewTopConstraint = make.top.equalToSuperview().offset(textViewPadding).priority(999).constraint
            make.bottom.equalToSuperview().offset(-textViewPadding)
            make.right.equalTo(sendButton.snp.left)
            
            if attachmentButton.isHidden {
                make.left.equalToSuperview().offset(textViewPadding)
            } else {
                make.left.equalTo(attachmentButton.snp.right).offset(-textView.textContainer.lineFragmentPadding)
            }
        }
        
        textView.setContentCompressionResistancePriority(.required, for: .vertical)
        
        // Blurred background.
        if style.backgroundColor == .clear {
            addBlurredBackground(blurEffectStyle: style.textColor.isDark ? .extraLight : .dark)
        }
        
        // Add placeholder.
        self.placeholderText = placeholderText
        
        toolBar.isHidden = true
        textView.inputAccessoryView = toolBar
        updateStyleState()
        
        // Observe the keyboard moving.
        RxKeyboard.instance.visibleHeight
            .skip(1)
            .drive(onNext: { [weak self] height in
                guard let self = self, let parentView = self.superview else {
                    return
                }
                
                let bottom: CGFloat = .messageEdgePadding
                    + max(0, height - (height > 0 ? parentView.safeAreaBottomOffset + self.toolBar.frame.height : 0))
                
                self.bottomConstraint?.update(offset: -bottom)
                
                if height == 0 {
                    self.textView.resignFirstResponder()
                }
                
                DispatchQueue.main.async {
                    if self.styleState != .disabled {
                        self.updateStyleState()
                    }
                }
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
    
    /// Reset states of all child views and clear all added/generated data.
    public func reset() {
        isEnabled = true
        isEditing = false
        previousTextBeforeReset = textView.attributedText
        textView.attributedText = attributedText()
        uploader?.reset()
        updatePlaceholder()
        filesStackView.isHidden = true
        filesStackView.removeAllArrangedSubviews()
        updateImagesCollectionView()
        styleState = textView.isFirstResponder ? .active : .normal
    }
    
    /// Toggle `isUserInteractionEnabled` states for all child views.
    public var isEnabled: Bool = true {
        didSet {
            sendButton.isEnabled = isEnabled
            attachmentButton.isEnabled = isEnabled
            imagesCollectionView.isUserInteractionEnabled = isEnabled
            imagesCollectionView.alpha = isEnabled ? 1 : 0.5
            styleState = isEnabled ? .normal : .disabled
        }
    }
    
    /// Update the placeholder and send button visibility.
    public func updatePlaceholder() {
        placeholderLabel.isHidden = textView.attributedText.length != 0
        DispatchQueue.main.async { [weak self] in self?.updateSendButton() }
    }
    
    func updateSendButton() {
        let isAnyFileUploaded = uploader?.items.first(where: { $0.attachment != nil }) != nil
        sendButton.isHidden = text.count == 0 && !isAnyFileUploaded
    }
    
    func updateStyleState() {
        styleState = !textView.isFirstResponder
            && isUploaderImagesEmpty
            && isUploaderFilesEmpty
            && text.isEmpty ? .normal : (isEditing ? .edit : .active)
    }
}
