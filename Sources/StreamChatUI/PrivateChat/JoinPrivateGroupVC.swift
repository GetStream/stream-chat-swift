//
//  JoinPrivateGroupVC.swift
//  StreamChatUI
//
//  Created by Ajay Ghodadra on 04/01/22.
//  Copyright © 2022 Stream.io Inc. All rights reserved.
//

import UIKit
import CoreLocation

open class JoinPrivateGroupVC: UIViewController {

    // MARK: - Outlets
    @IBOutlet private weak var viewSafeAreaHeader: UIView!
    @IBOutlet weak var viewHeader: UIView!
    @IBOutlet weak var btnBack: UIButton!
    @IBOutlet weak var viewOTP: DPOTPView!


    // MARK: - view life cycle
    open override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    // MARK: - IBAction
    @IBAction func btnBackAction(_ sender: UIButton) {
        navigationController?.popViewController(animated: true)
    }

    // MARK: - Functions
    private func setupUI() {
        viewSafeAreaHeader.backgroundColor = Appearance.default.colorPalette.walletTabbarBackground
        viewHeader.backgroundColor = Appearance.default.colorPalette.walletTabbarBackground
        btnBack.setImage(Appearance.default.images.backCircle, for: .normal)
        btnBack.setTitle("", for: .normal)
        view.backgroundColor = Appearance.default.colorPalette.background
        viewOTP.becomeFirstResponder()
        fetchCurrentLocation()
    }

    private func fetchCurrentLocation() {
        LocationManager.shared.location.bind { location in
            print("------", location)
        }
        if LocationManager.shared.hasLocationPermissionDenied() {
            LocationManager.showLocationPermissionAlert()
        } else {
            LocationManager.shared.requestLocationAuthorization()
            LocationManager.shared.requestGPS()
        }
    }

}

extension JoinPrivateGroupVC : DPOTPViewDelegate {
    public func dpOTPViewAddText(_ text: String, at position: Int) {
        print("addText:- " + text + " at:- \(position)" )
    }

    public func dpOTPViewRemoveText(_ text: String, at position: Int) {
        print("removeText:- " + text + " at:- \(position)" )
    }

    public func dpOTPViewChangePositionAt(_ position: Int) {
        print("at:-\(position)")
    }
    public func dpOTPViewBecomeFirstResponder() {

    }
    public func dpOTPViewResignFirstResponder() {

    }
}
