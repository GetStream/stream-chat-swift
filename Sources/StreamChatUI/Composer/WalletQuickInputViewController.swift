//
//  WalletQuickInputViewController.swift
//  StreamChatUI
//
//  Created by Parth Kshatriya on 29/12/21.
//

import UIKit

class WalletQuickInputViewController: UIViewController {

    @IBOutlet weak var btnRemove: UIButton!
    @IBOutlet weak var btnAdd: UIButton!
    @IBOutlet weak var btnRequest: UIButton!
    @IBOutlet weak var btnPay: UIButton!
    @IBOutlet weak var lblAmount: UILabel!

    var showKeypad: (() -> Void)?
    var didRequestAction: ((Int) -> Void)?
    var didPayAction: ((Int) -> Void)?
    var amount = 0 {
        didSet {
            lblAmount.text = "$\(amount)"
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
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
    }

    @IBAction func btnShowKeypadAction(_ sender: Any) {
        showKeypad?()
    }

    @IBAction func btnAddAction(_ sender: Any) {
        amount += 1
    }

    @IBAction func btnRemoveAction(_ sender: Any) {
        amount -= 1
    }

    @IBAction func btnRequestAction(_ sender: Any) {
        didRequestAction?(amount)
    }

    @IBAction func btnPayAction(_ sender: Any) {
        didPayAction?(amount)
    }
}
