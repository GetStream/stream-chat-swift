//
//  ComposerView+TextView.swift
//  StreamChat
//
//  Created by Alexey Bukhtin on 04/06/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import UIKit

// MARK: - Text View Height

extension ComposerView {
    
    func setupTextView() -> UITextView {
        let textView = UITextView(frame: .zero)
        textView.delegate = self
        textView.attributedText = attributedText()
        textView.showsVerticalScrollIndicator = false
        textView.showsHorizontalScrollIndicator = false
        textView.isScrollEnabled = false
        return textView
    }
    
    var textViewPadding: CGFloat {
        baseTextHeight == .greatestFiniteMagnitude ? 0 : ((style?.height ?? .composerHeight) - baseTextHeight) / 2
    }
    
    private var textViewContentSize: CGSize {
        textView.sizeThatFits(CGSize(width: textView.frame.width, height: .greatestFiniteMagnitude))
    }
    
    /// Update the height of the text view for a big text length.
    func updateTextHeightIfNeeded() {
        if baseTextHeight == .greatestFiniteMagnitude {
            let text = textView.attributedText
            textView.attributedText = attributedText(text: "Stream")
            baseTextHeight = textViewContentSize.height.rounded()
            textView.attributedText = text
        }
        
        updateTextHeight(textView.attributedText.length > 0 ? textViewContentSize.height.rounded() : baseTextHeight)
    }
    
    private func updateTextHeight(_ height: CGFloat) {
        guard let heightConstraint = heightConstraint, let style = style else {
            return
        }
        
        var maxHeight = CGFloat.composerMaxHeight
        
        if !imagesCollectionView.isHidden {
            maxHeight -= .composerAttachmentsHeight
        }
        
        if !filesStackView.isHidden {
            let filesHeight = CGFloat.composerFileHeight * CGFloat(filesStackView.arrangedSubviews.count)
            maxHeight -= filesHeight
        }
        
        if let uploadManager = uploadManager {
            imagesCollectionView.isHidden = uploadManager.images.isEmpty
            filesStackView.isHidden = uploadManager.files.isEmpty
        }
        
        var height = min(max(height + 2 * textViewPadding, style.height), maxHeight)
        var textViewTopOffset = textViewPadding
        
        if !imagesCollectionView.isHidden {
            height += .composerAttachmentsHeight
            textViewTopOffset += .composerAttachmentsHeight
        }
        
        if !filesStackView.isHidden {
            let filesHeight = CGFloat.composerFileHeight * CGFloat(filesStackView.arrangedSubviews.count)
            height += filesHeight
            textViewTopOffset += filesHeight
        }
        
        textView.isScrollEnabled = height >= CGFloat.composerMaxHeight
        
        if heightConstraint.layoutConstraints.first?.constant != height {
            heightConstraint.update(offset: height)
            setNeedsLayout()
            layoutIfNeeded()
        }
        
        if textViewTopConstraint?.layoutConstraints.first?.constant != textViewTopOffset {
            textViewTopConstraint?.update(offset: textViewTopOffset)
            setNeedsLayout()
            layoutIfNeeded()
        }
        
        updateToolbarIfNeeded()
    }
    
    func updateToolbarIfNeeded() {
        guard let style = style, let composerViewHeight = heightConstraint?.layoutConstraints.first?.constant else {
            return
        }
        
        let height = composerViewHeight + style.edgeInsets.top + style.edgeInsets.bottom
        
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
