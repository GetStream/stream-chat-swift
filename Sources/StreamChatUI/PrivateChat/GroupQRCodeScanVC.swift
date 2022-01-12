//
//  GroupQRCodeScanVC.swift
//  StreamChatUI
//
//  Created by Ajay Ghodadra on 12/01/22.
//  Copyright © 2022 Stream.io Inc. All rights reserved.
//

import UIKit
import swiftScan

open class GroupQRCodeScanVC: LBXScanViewController {

    // MARK: - variables
    private let generator = UINotificationFeedbackGenerator()
    open var onScanSuccess: ((String) -> Void)?

    // MARK: - outlets
    @IBOutlet weak var btnClose: UIButton!


    // MARK: - view life cycle
    open override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    // MARK: - IB Actions
    @IBAction func btnCloseAction(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }

    // MARK: - Functions
    private func setupUI() {
        btnClose.setImage(Appearance.default.images.closeCircle, for: .normal)
        setQRScan()
    }

    private func setQRScan() {
        setNeedCodeImage(needCodeImg: true)
        setOpenInterestRect(isOpen: true)
        scanStyle?.colorRetangleLine = .clear
        scanStyle?.colorAngle = .clear
        scanStyle?.centerUpOffset = 0
        scanStyle?.xScanRetangleOffset = 0
    }

    open override func handleCodeResult(arrayResult: [LBXScanResult]) {
        playHapticEvent()
        let result: LBXScanResult = arrayResult[0]
        if !(result.strScanned?.isBlank ?? false) {
            onScanSuccess?(result.strScanned ?? "")
            dismiss(animated: true)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [weak self] in
            guard let self = self else {
                return
            }
            self.startScan()
        }
    }

    private func playHapticEvent() {
        generator.notificationOccurred(.success)
    }
}
