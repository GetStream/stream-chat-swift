//
//  WalletInputViewController.swift
//  StreamChatUI
//
//  Created by Parth Kshatriya on 28/12/21.
//

import UIKit

class WalletInputViewController: WalletQuickInputViewController {

    @IBOutlet weak var viewKeypad: UIStackView!
    @IBOutlet var btnKeyPad: [UIButton]!

    var updatedAmount = 0
    var didHide: ((Int) -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func setupUI() {
        super.setupUI()
        btnKeyPad.forEach { btn in
            btn.layer.cornerRadius = 30
        }
        self.amount = updatedAmount
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        didHide?(amount)
    }

    @IBAction func btnKeypadAction(_ sender: UIButton) {
        if let keyPadNumber = sender.titleLabel?.text {
            let amount = (lblAmount.text ?? "0") + "\(keyPadNumber)"
            self.amount = Int(amount.replacingOccurrences(of: "$", with: "")) ?? 0
        } else {
            var amount = lblAmount.text ?? ""
            _ = amount.removeLast()
            self.amount = Int(amount.replacingOccurrences(of: "$", with: "")) ?? 0
        }
    }

}
