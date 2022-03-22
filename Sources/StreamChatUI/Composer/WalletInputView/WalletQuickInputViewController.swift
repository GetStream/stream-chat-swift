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
        guard validateAmount() else { return }
        showPaymentOptions()
        didShowPaymentOption?()
        viewPaymentOption.isHidden = false
    }
    
    @IBAction func btnShowKeypadAction(_ sender: Any) {
        showKeypad?(walletStepper.value)
    }

    @IBAction func btnRequestAction(_ sender: Any) {
        guard validateAmount() else { return }
        viewPaymentOption.isHidden = false
        didShowPaymentOption?()
        paymentType = .request
        showPaymentOptions()
    }

    @IBAction func btnSendAction(_ sender: Any) {
        guard validateAmount() else { return }
        viewPaymentOption.isHidden = false
        didShowPaymentOption?()
        paymentType = .pay
        showPaymentOptions()
    }

    private func validateAmount() -> Bool {
        if walletStepper.value == 0 {
            Snackbar.show(text: "You cannot send/request 0 ONE.")
            return false
        }
        return true
    }

    private func showPaymentOptions() {
        guard validateAmount() else { return }
        if #available(iOS 14.0.0, *) {
            self.children.forEach { childVC in
                childVC.willMove(toParent: nil)
                childVC.removeFromParent()
                childVC.view.removeFromSuperview()
            }
            var paymentSelection = SendPaymentOptionView(amount: .constant("\(walletStepper.value)"), paymentType: paymentType)
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
