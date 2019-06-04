//
//  ComposerView+TextView.swift
//  GetStreamChat
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
        imagesCollectionView.isHidden = isUploaderImagesEmpty
        filesStackView.isHidden = isUploaderFilesEmpty
        
        if !imagesCollectionView.isHidden {
            height += .composerAttachmentsHeight
        }
        
        if !filesStackView.isHidden {
            height += .composerFileHeight * CGFloat(filesStackView.arrangedSubviews.count)
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
