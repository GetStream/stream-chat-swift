//
//  WalletInputViewController.swift
//  StreamChatUI
//
//  Created by Parth Kshatriya on 28/12/21.
//

import UIKit
import StreamChat

class WalletInputViewController: UIViewController {

    // MARK: - Outlets
    @IBOutlet weak var viewKeypad: UIStackView!
    @IBOutlet weak var btnClose: UIButton!
    @IBOutlet var btnKeyPad: [UIButton]!
    @IBOutlet weak var walletStepper: WalletStepper!

    // MARK: - Variables
    var updatedAmount = 0.0
    var didHide: ((Double) -> Void)?
    var didRequestAction: ((Double, WalletAttachmentPayload.PaymentType) -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    func setupUI() {
        btnKeyPad.forEach { btn in
            btn.layer.cornerRadius = 30
        }
        btnClose.setImage(Appearance.default.images.closePopup, for: .normal)
        self.walletStepper.updateAmount(amount: updatedAmount)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        didHide?(walletStepper.value)
    }

    @IBAction func btnRequestAction(_ sender: Any) {
        didRequestAction?(walletStepper.value, .request)
    }

    @IBAction func btnSendAction(_ sender: Any) {
        didRequestAction?(walletStepper.value, .pay)
    }

    @IBAction func btnKeypadAction(_ sender: UIButton) {
        walletStepper.insertNumber(numberValue: sender.titleLabel?.text)
    }

    @IBAction func btnCloseAction(_ sender: Any) {
        didHide?(walletStepper.value)
        self.dismiss(animated: true, completion: nil)
    }

}
