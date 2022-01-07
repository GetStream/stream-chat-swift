//
//  WalletInputViewController.swift
//  StreamChatUI
//
//  Created by Parth Kshatriya on 28/12/21.
//

import UIKit

class WalletInputViewController: UIViewController {

    // MARK: - Outlets
    @IBOutlet weak var viewKeypad: UIStackView!
    @IBOutlet var btnKeyPad: [UIButton]!
    @IBOutlet weak var walletStepper: WalletStepper!

    // MARK: - Variables
    var updatedAmount = 0
    var didHide: ((Int) -> Void)?
    var didRequestAction: ((Int) -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    func setupUI() {
        btnKeyPad.forEach { btn in
            btn.layer.cornerRadius = 30
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        didHide?(1)
    }

    @IBAction func btnRequestAction(_ sender: Any) {
        didRequestAction?(1)
    }

    @IBAction func btnKeypadAction(_ sender: UIButton) {
        if let keyPadNumber = sender.titleLabel?.text {
            let amount = "\(walletStepper.value)" + "\(keyPadNumber)"
            walletStepper.updateAmount(amount: Int(amount) ?? 0)
        } else {
            var amount = "\(walletStepper.value)"
            _ = amount.removeLast()
            walletStepper.updateAmount(amount: Int(amount) ?? 0)
        }
    }

}
