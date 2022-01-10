//
//  WalletQuickInputViewController.swift
//  StreamChatUI
//
//  Created by Parth Kshatriya on 29/12/21.
//

import UIKit

class WalletQuickInputViewController: UIViewController {

    // MARK: - Outlets
    @IBOutlet weak var btnRequest: UIButton!
    @IBOutlet weak var walletStepper: WalletStepper!

    // MARK: - Variables
    var showKeypad: ((Double) -> Void)?
    var didRequestAction: ((Double) -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func btnShowKeypadAction(_ sender: Any) {
        showKeypad?(walletStepper.value)
    }

    @IBAction func btnRequestAction(_ sender: Any) {
        didRequestAction?(walletStepper.value)
    }

}
