//
//  WalletAttachmentComposerPreview.swift
//  StreamChatUI
//
//  Created by Parth Kshatriya on 29/12/21.
//

import StreamChat
import UIKit

/// A view that displays wallet attachment preview in composer.
open class WalletAttachmentComposerPreview: _View, ThemeProvider {
    open var width: CGFloat = 150
    open var height: CGFloat = 150

    public var amount: String? {
        didSet {
            updateContentIfNeeded()
        }
    }

    private(set) lazy var bgView: UIView = UIView()
        .withoutAutoresizingMaskConstraints

    private(set) lazy var lblAmount: UILabel = UILabel()
        .withoutAutoresizingMaskConstraints

    override open func setUpAppearance() {
        super.setUpAppearance()

        layer.masksToBounds = true
        layer.cornerRadius = 11
    }

    override open func setUpLayout() {
        super.setUpLayout()

        embed(bgView)
        embed(lblAmount)
        lblAmount.font = .systemFont(ofSize: 22, weight: .bold)
        lblAmount.textColor = .white
        lblAmount.text = amount
        lblAmount.textAlignment = .center
        bgView.backgroundColor = .darkGray
        widthAnchor.pin(equalToConstant: width).isActive = true
        heightAnchor.pin(equalToConstant: height).isActive = true
    }

    override open func updateContent() {
        super.updateContent()

    }
}
