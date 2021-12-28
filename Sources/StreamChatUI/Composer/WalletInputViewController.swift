//
//  WalletInputViewController.swift
//  StreamChatUI
//
//  Created by Parth Kshatriya on 28/12/21.
//

import UIKit

class WalletInputViewController: UIViewController {

    @IBOutlet weak var btnRemove: UIButton!
    @IBOutlet weak var btnAdd: UIButton!
    @IBOutlet weak var btnRequest: UIButton!
    @IBOutlet weak var btnPay: UIButton!
    @IBOutlet weak var btnShowKeyboard: UIButton!
    @IBOutlet weak var viewKeypad: UIStackView!
    @IBOutlet var btnKeyPad: [UIButton]!

    var showKeypad: (() -> Void)?
    var didHideView: (() -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        viewKeypad.isHidden = true
        btnShowKeyboard.isHidden = false
        didHideView?()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
    }

    func setupUI() {
        btnAdd.layer.cornerRadius = btnAdd.bounds.height / 2
        btnRemove.layer.cornerRadius = btnRemove.bounds.height / 2
        btnRequest.layer.cornerRadius = btnRequest.bounds.height / 2
        btnPay.layer.cornerRadius = btnPay.bounds.height / 2

        btnAdd.layer.maskedCorners = [.layerMinXMinYCorner, .layerMinXMaxYCorner]
        btnRemove.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMaxXMaxYCorner]
        btnRequest.layer.maskedCorners = [.layerMinXMinYCorner, .layerMinXMaxYCorner]
        btnPay.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMaxXMaxYCorner]

        btnKeyPad.forEach { btn in
            btn.layer.cornerRadius = 30
        }
    }

    @IBAction func btnShowKeypadAction(_ sender: Any) {
        viewKeypad.isHidden = false
        btnShowKeyboard.isHidden = true
        showKeypad?()
    }

    func hideKeypad() {
        viewKeypad.isHidden = true
    }
}
