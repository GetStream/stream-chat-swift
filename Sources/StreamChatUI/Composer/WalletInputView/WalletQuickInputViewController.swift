//
//  WalletQuickInputViewController.swift
//  StreamChatUI
//
//  Created by Parth Kshatriya on 29/12/21.
//

import UIKit
import StreamChat
import SwiftUI

class WalletQuickInputViewController: UIViewController {

    // MARK: - Outlets
    @IBOutlet weak var btnRequest: UIButton!
    @IBOutlet weak var walletStepper: WalletStepper!
    @IBOutlet weak var viewPaymentOption: UIView!

    // MARK: - Variables
    var showKeypad: ((Double) -> Void)?
    var didRequestAction: ((Double, WalletAttachmentPayload.PaymentType, WalletAttachmentPayload.PaymentTheme) -> Void)?
    var paymentType: WalletAttachmentPayload.PaymentType = .request
    var didShowPaymentOption: (() -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(hidePaymentOptions(_:)), name: .hidePaymentOptions, object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc func hidePaymentOptions(_ notification: Notification) {
        viewPaymentOption.isHidden = true
    }

    func showPaymentOptionView() {
        showPaymentOptions()
        didShowPaymentOption?()
        viewPaymentOption.isHidden = false
    }
    
    @IBAction func btnShowKeypadAction(_ sender: Any) {
        showKeypad?(walletStepper.value)
    }

    @IBAction func btnRequestAction(_ sender: Any) {
        showPaymentOptions()
        viewPaymentOption.isHidden = false
        didShowPaymentOption?()
        paymentType = .request
    }

    @IBAction func btnSendAction(_ sender: Any) {
        showPaymentOptions()
        viewPaymentOption.isHidden = false
        didShowPaymentOption?()
        paymentType = .pay
    }

    private func showPaymentOptions() {
        if #available(iOS 14.0.0, *) {
            self.children.forEach { vc in
                vc.removeFromParent()
            }
            var paymentSelection = SendPaymentOptionView(amount: .constant("\(walletStepper.value)"))
            paymentSelection.didSelectPayment = { [weak self] paymentOption in
                guard let `self` = self else { return }
                self.viewPaymentOption.isHidden = true
                self.didShowPaymentOption?()
                self.didRequestAction?(self.walletStepper.value, self.paymentType, paymentOption)
            }
            let controller = UIHostingController(rootView: paymentSelection)
            addChild(controller)
            controller.view.translatesAutoresizingMaskIntoConstraints = false
            viewPaymentOption.addSubview(controller.view)
            controller.didMove(toParent: self)

            NSLayoutConstraint.activate([
                controller.view.widthAnchor.constraint(equalTo: viewPaymentOption.widthAnchor),
                controller.view.heightAnchor.constraint(equalTo: viewPaymentOption.heightAnchor),
                controller.view.centerXAnchor.constraint(equalTo: viewPaymentOption.centerXAnchor),
                controller.view.centerYAnchor.constraint(equalTo: viewPaymentOption.centerYAnchor)
            ])
        } else {
            // Fallback on earlier versions
        }
    }
}
