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

    public var walletAttachment: WalletAttachmentPayload! {
        didSet {
            updateContentIfNeeded()
        }
    }

    private(set) lazy var bgView: UIView = UIView()
        .withoutAutoresizingMaskConstraints

    private(set) lazy var lblAmount: UILabel = UILabel()
        .withoutAutoresizingMaskConstraints

    private(set) lazy var lblPaymentType: UILabel = UILabel()
        .withoutAutoresizingMaskConstraints

    override open func setUpAppearance() {
        super.setUpAppearance()

        layer.masksToBounds = true
        layer.cornerRadius = 11
    }

    override open func setUpLayout() {
        super.setUpLayout()

        embed(bgView)
        bgView.embed(lblAmount)
        bgView.addSubview(lblPaymentType)
        lblPaymentType.topAnchor.constraint(equalTo: bgView.topAnchor, constant: 25).isActive = true
        lblPaymentType.leadingAnchor.constraint(equalTo: bgView.leadingAnchor).isActive = true
        lblPaymentType.trailingAnchor.constraint(equalTo: bgView.trailingAnchor).isActive = true
        lblPaymentType.textColor = .white
        lblPaymentType.textAlignment = .center
        lblPaymentType.font = .systemFont(ofSize: 12)
        lblPaymentType.text = walletAttachment.paymentType.rawValue

        lblAmount.font = .systemFont(ofSize: 22, weight: .bold)
        lblAmount.textColor = .white
        lblAmount.text = getOneAmount(data: walletAttachment.extraData) ?? "0 ONE"//walletAttachment.oneAmount
        lblAmount.textAlignment = .center
        bgView.backgroundColor = .darkGray
        widthAnchor.pin(equalToConstant: width).isActive = true
        heightAnchor.pin(equalToConstant: height).isActive = true
    }

    override open func updateContent() {
        super.updateContent()

    }

    func getOneAmount(data: [String: RawJSON]?) -> String? {
        guard let extraData = data else {
            return nil
        }
        if let oneAmount = extraData["oneAmount"] {
            return fetchRawData(raw: oneAmount) as? String ?? ""
        } else {
            return nil
        }
    }
}


/**
 if let userId = raw["highestAmountUserId"] {
     return fetchRawData(raw: userId) as? String ?? ""
 } else {
     return ""
 }
 */
