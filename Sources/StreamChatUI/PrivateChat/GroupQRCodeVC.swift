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
    
    // MARK: - Outlets
    @IBOutlet weak var btnBack: UIButton!
    @IBOutlet weak var imgQRCode: UIImageView!

    // MARK: - View Life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    // MARK: - IBOutlets
    @IBAction func btnBackAction(_ sender: UIButton) {
        navigationController?.popViewController(animated: true)
    }

    // MARK: - Functions
    private func setupUI() {
        btnBack.setTitle("", for: .normal)
        btnBack.setImage(Appearance.default.images.backCircle, for: .normal)
        generateQRCode()
    }

    private func generateQRCode() {
        guard let content = strContent, let qrCode = EFQRCode.generate(for: content) else {
            return
        }
        imgQRCode.image = UIImage(cgImage: qrCode)
    }
}
