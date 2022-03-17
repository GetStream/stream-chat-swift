//
//  GroupQRCodeVC.swift
//  StreamChatUI
//
//  Created by Ajay Ghodadra on 11/01/22.
//  Copyright © 2022 Stream.io Inc. All rights reserved.
//

import UIKit
import EFQRCode
import swiftScan

class GroupQRCodeVC: UIViewController {

    // MARK: - Variables
    var strContent: String?
    var groupName: String?
    
    // MARK: - Outlets
    @IBOutlet weak var btnBack: UIButton!
    @IBOutlet weak var btnShare: UIButton!
    @IBOutlet weak var qrCodeView: UIView!
    @IBOutlet weak var imgQRCode: UIImageView!
    @IBOutlet weak var lblName: UILabel!

    // MARK: - View Life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    // MARK: - IBOutlets
    @IBAction func btnBackAction(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }

    // MARK: - Functions
    private func setupUI() {
        btnBack.setTitle("", for: .normal)
        btnBack.setImage(Appearance.default.images.closeCircle, for: .normal)
        generateQRCode()
        qrCodeView.layoutIfNeeded()
        qrCodeView.cornerRadius = self.qrCodeView.bounds.width / 2
        lblName.text = groupName
        btnShare.tintColor = .white
    }

    private func generateQRCode() {
        guard let content = strContent, let qrCode = EFQRCode.generate(for: content) else {
            return
        }
        imgQRCode.image = UIImage(cgImage: qrCode)
    }
}
