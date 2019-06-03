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
    
    private var toolBar = UIToolbar(frame: CGRect(width: UIScreen.main.bounds.width, height: .messagesToComposerPadding))
    
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
    
    var imagesAddAction: AttachmentCollectionViewCell.TapAction?
    
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
    var uploader: Uploader?
    
    var isUploaderEmpty: Bool {
        return (uploader?.items ?? []).isEmpty
    }
    
    private lazy var imagesCollectionView: UICollectionView = {
        let collectionViewLayout = UICollectionViewFlowLayout()
        collectionViewLayout.scrollDirection = .horizontal
        collectionViewLayout.itemSize = CGSize(width: .composerAttachmentSize, height: .composerAttachmentSize)
        collectionViewLayout.minimumLineSpacing = .composerCornerRadius / 2
        collectionViewLayout.minimumInteritemSpacing = 0
        collectionViewLayout.sectionInset = UIEdgeInsets(top: 0, left: .composerCornerRadius, bottom: 0, right: .composerCornerRadius)
        
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
        
        // Add text view.
        addSubview(textView)
        updateTextHeightIfNeeded()
        textView.keyboardAppearance = style.textColor.isDark ? .default : .dark
        textView.backgroundColor = backgroundColor
        
        textView.snp.makeConstraints { make in
            make.left.equalTo(attachmentButton.snp.right)
            make.top.greaterThanOrEqualTo(imagesCollectionView.snp.bottom).offset(textViewPadding).priority(999)
            make.top.equalToSuperview().offset(textViewPadding).priority(998)
            make.bottom.equalToSuperview().offset(-textViewPadding)
            make.right.equalTo(sendButton.snp.left)
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
        updateImagesCollectionView()
        styleState = textView.isFirstResponder ? .active : .normal
    }
    
    /// Toggle `isUserInteractionEnabled` states for all child views.
    public var isEnabled: Bool = true {
        didSet {
            sendButton.isEnabled = isEnabled
            attachmentButton.isEnabled = isEnabled
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
    
    private func updateSendButton() {
        sendButton.isHidden = text.count == 0 && isUploaderEmpty
    }
    
    private func updateStyleState() {
        styleState = !textView.isFirstResponder && isUploaderEmpty && text.isEmpty ? .normal : (isEditing ? .edit : .active)
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
        imagesCollectionView.isHidden = isUploaderEmpty
        
        if !imagesCollectionView.isHidden {
            height += .composerAttachmentsHeight
        }
        
        updateToolBarHeight()

        if heightConstraint.layoutConstraints.first?.constant != height {
            heightConstraint.update(offset: height)
            setNeedsLayout()
            layoutIfNeeded()
        }
    }
    
    public func updateToolBarHeight() {
        let height = CGFloat.messagesToComposerPadding + (imagesCollectionView.isHidden ? 0 : .composerAttachmentsHeight)
        
        guard toolBar.frame.height != height else {
            return
        }
        
        toolBar = UIToolbar(frame: CGRect(width: UIScreen.main.bounds.width, height: height))
        toolBar.isHidden = true
        textView.inputAccessoryView = toolBar
        textView.reloadInputViews()
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
    
    func addImage(_ item: UploaderItem) {
        guard let uploader = uploader else {
            return
        }
        
        uploader.upload(item: item)
        updateImagesCollectionView()
        imagesCollectionView.scrollToItem(at: .item(0), at: .right, animated: false)
    }
    
    private func updateImagesCollectionView() {
        imagesCollectionView.reloadData()
        imagesCollectionView.isHidden = isUploaderEmpty
        updateTextHeightIfNeeded()
        updateSendButton()
        updateStyleState()
        updateToolBarHeight()
    }
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return isUploaderEmpty ? 0 : (uploader?.items.count ?? 0) + (imagesAddAction == nil ? 0 : 1)
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(for: indexPath) as AttachmentCollectionViewCell
        
        if indexPath.item == 0, let imagesAddAction = imagesAddAction {
            cell.updatePlusButton(tintColor: style?.textColor, action: imagesAddAction)
            return cell
        }
        
        let imageIndex = indexPath.item - (imagesAddAction == nil ? 0 : 1)
        
        guard let item = uploader?.items[imageIndex] else {
            return .unused
        }
        
        cell.imageView.image = item.image
        
        cell.updateRemoveButton(tintColor: style?.textColor) { [weak self] in
            if let self = self {
                self.uploader?.remove(at: imageIndex)
                self.updateImagesCollectionView()
            }
        }
        
        if item.url == nil, item.error == nil {
            cell.updateForProgress(item.lastProgress)
            
            item.uploadingCompletion
                .observeOn(MainScheduler.instance)
                .subscribe(onError: { [weak cell] _ in cell?.updateForError() },
                           onCompleted: { [weak cell] in cell?.updateForProgress(1) })
                .disposed(by: cell.disposeBag)
            
            item.uploadingProgress
                .do(onError: { [weak cell] error in cell?.updateForError() },
                    onDispose: { [weak cell, weak item] in
                        if item?.error == nil {
                            cell?.updateForProgress(1)
                        } else {
                            cell?.updateForError()
                        }
                })
                .bind(to: cell.progressView.rx.progress)
                .disposed(by: cell.disposeBag)
            
        } else if item.error != nil {
            cell.updateForError()
        }
        
        return cell
    }
}
