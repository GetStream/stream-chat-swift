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
                
                if self.styleState == .edit {
                    sendButton.setTitleColor(styleState.tintColor, for: .normal)
                } else if self.styleState == .active {
                    sendButton.setTitleColor(styleState.tintColor, for: .normal)
                }
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
    
    lazy var toolBar = UIToolbar(frame: CGRect(width: UIScreen.main.bounds.width,
                                               height: (style?.height ?? .composerHeight)
                                                + (style?.edgeInsets.bottom ?? .messageEdgePadding)
                                                + .messageEdgePadding))
    
    /// An action for a plus button in the images attachments collection view.
    /// If it's nil, it will not be shown in the images collection view.
    public var imagesAddAction: AttachmentCollectionViewCell.TapAction?
    
    private var previousTextBeforeReset: NSAttributedString?
    private let disposeBag = DisposeBag()
    private(set) weak var heightConstraint: Constraint?
    private weak var bottomConstraint: Constraint?
    var baseTextHeight = CGFloat.greatestFiniteMagnitude
    
    /// An images collection view.
    public private(set) lazy var imagesCollectionView = setupImagesCollectionView()
    var imageUploaderItems: [UploaderItem] = []
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
        button.backgroundColor = backgroundColor
        button.titleLabel?.font = .chatMediumBold
        
        button.snp.makeConstraints {
            sendButtonWidthConstraint = $0.width.equalTo(CGFloat.composerButtonWidth).priority(999).constraint
        }
        
        return button
    }()
    
    let sendButtonVisibilityBehaviorSubject = BehaviorSubject<(isHidden: Bool, isEnabled: Bool)>(value: (false, false))
    /// An observable sendButton visibility state.
    public private(set) lazy var sendButtonVisibility = sendButtonVisibilityBehaviorSubject
        .distinctUntilChanged { lhs, rhs -> Bool in lhs.0 == rhs.0 && lhs.1 == rhs.1 }
    
    private var sendButtonWidthConstraint: Constraint?
    private var sendButtonRightConstraint: Constraint?

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
            make.left.equalToSuperview().offset(style.edgeInsets.left)
            make.right.equalToSuperview().offset(-style.edgeInsets.right)
            heightConstraint = make.height.equalTo(style.height).constraint
            let bottomMargin = view.safeAreaLayoutGuide.snp.bottomMargin
            bottomConstraint = make.bottom.equalTo(bottomMargin).offset(-style.edgeInsets.bottom).constraint
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
            make.height.equalTo(style.height)
            make.left.equalToSuperview()
            make.bottom.equalToSuperview()
        }
        
        // Add buttons.
        if style.sendButtonVisibility != .none {
            sendButton.isHidden = style.sendButtonVisibility == .whenActive
            sendButton.isEnabled = style.sendButtonVisibility == .whenActive
            sendButton.setTitleColor(style.style(with: .active).tintColor, for: .normal)
            sendButton.setTitleColor(style.style(with: .disabled).tintColor, for: .disabled)
            sendButtonVisibilityBehaviorSubject.onNext((sendButton.isHidden, sendButton.isEnabled))
            
            addSubview(sendButton)
            
            sendButton.snp.makeConstraints { make in
                make.height.equalTo(style.height)
                make.bottom.equalToSuperview()
                sendButtonRightConstraint = make.right.equalToSuperview().constraint
            }
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
            
            if sendButton.superview == nil {
                make.right.equalToSuperview().offset(-textViewPadding)
            } else {
                make.right.equalTo(sendButton.snp.left)
            }
            
            if attachmentButton.isHidden {
                make.left.equalToSuperview().offset(textViewPadding)
            } else {
                var offset = textView.textContainer.lineFragmentPadding
                
                if let borderWidth = style.states[.active]?.borderWidth, borderWidth > 0 {
                    offset += borderWidth
                }
                
                make.left.equalTo(attachmentButton.snp.right).offset(-offset)
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
            .drive(onNext: { [weak self] in self?.updateBottomConstraint(with: $0) })
            .disposed(by: disposeBag)
    }
    
    /// Reset states of all child views and clear all added/generated data.
    public func reset() {
        isEnabled = true
        isEditing = false
        previousTextBeforeReset = textView.attributedText
        textView.attributedText = attributedText()
        uploader?.reset()
        imageUploaderItems = []
        updatePlaceholder()
        filesStackView.isHidden = true
        filesStackView.removeAllArrangedSubviews()
        updateImagesCollectionView()
        styleState = textView.isFirstResponder ? .active : .normal
    }
    
    /// Toggle `isUserInteractionEnabled` states for all child views.
    public var isEnabled: Bool = true {
        didSet {
            if let style = style {
                sendButton.isEnabled = style.sendButtonVisibility == .whenActive ? isEnabled : false
                sendButtonVisibilityBehaviorSubject.onNext((sendButton.isHidden, sendButton.isEnabled))
            }
            
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
        
        if let style = style {
            let isHidden = text.count == 0 && !isAnyFileUploaded
            
            if style.sendButtonVisibility == .whenActive {
                sendButton.isHidden = isHidden
            } else {
                sendButton.isEnabled = !isHidden
            }
            
            sendButtonVisibilityBehaviorSubject.onNext((sendButton.isHidden, sendButton.isEnabled))
        }
    }
    
    func updateStyleState() {
        styleState = !textView.isFirstResponder
            && imageUploaderItems.isEmpty
            && isUploaderFilesEmpty
            && text.isEmpty ? .normal : (isEditing ? .edit : .active)
    }
}

extension ComposerView {
    
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
    
    private func updateBottomConstraint(with keyboardHeight: CGFloat) {
        let bottom: CGFloat = (style?.edgeInsets.bottom ?? 0)
            + max(0, keyboardHeight - (keyboardHeight > 0 ? .safeAreaBottom + toolBar.frame.height : 0))
        
        bottomConstraint?.update(offset: -bottom)
        
        if keyboardHeight == 0 {
            textView.resignFirstResponder()
        }
        
        DispatchQueue.main.async {
            if self.styleState != .disabled {
                self.updateStyleState()
            }
        }
    }
}

// MARK: - Setup Send Button

extension ComposerView {
    
    /// Replace send button image with a new image.
    ///
    /// - Parameters:
    ///   - image: a new send button image.
    ///   - buttonWidth: update the button width (optional).
    public func setSendButtonImage(_ image: UIImage, buttonWidth: CGFloat? = nil) {
        sendButton.setImage(image, for: .normal)
        
        if let buttonWidth = buttonWidth {
            sendButtonWidthConstraint?.update(offset: max(buttonWidth, image.size.width))
        }
    }
    
    /// Replace send button image with a title.
    ///
    /// - Parameters:
    ///   - title: a send button title
    ///   - rightEdgeOffset: a right edge inset for the title (optional).
    public func setSendButtonTitle(_ title: String, rightEdgeOffset: CGFloat = .messageEdgePadding) {
        sendButton.setImage(nil, for: .normal)
        sendButton.setTitle(title, for: .normal)
        sendButtonWidthConstraint?.deactivate()
        sendButtonWidthConstraint = nil
        sendButtonRightConstraint?.update(offset: -rightEdgeOffset)
    }
}
