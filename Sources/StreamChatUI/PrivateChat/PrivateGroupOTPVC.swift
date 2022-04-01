//
//  PrivateGroupOTPVC.swift
//  StreamChatUI
//
//  Created by Ajay Ghodadra on 04/01/22.
//  Copyright © 2022 Stream.io Inc. All rights reserved.
//

import UIKit
import CoreLocation

protocol PrivateGroupOTPVCDelegate: class {
    func popToThisVC()
}

open class PrivateGroupOTPVC: UIViewController {

    // MARK: - Variables
    var isPushed = false

    // MARK: - Outlets
    @IBOutlet private weak var viewSafeAreaHeader: UIView!
    @IBOutlet weak var viewHeader: UIView!
    @IBOutlet weak var btnBack: UIButton!
    @IBOutlet weak var viewOTP: DPOTPView!
    @IBOutlet weak var lblOtpDetails: UILabel!
    @IBOutlet weak var indicator: UIActivityIndicatorView!
    @IBOutlet weak var heightSafeAreaView: NSLayoutConstraint!
    
    // MARK: - view life cycle
    open override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    // MARK: - IBAction
    @IBAction func btnBackAction(_ sender: UIButton) {
        NotificationCenter.default.post(name: .showTabbar, object: nil)
        popWithAnimation()
    }

    // MARK: - Functions
    private func setupUI() {
        heightSafeAreaView.constant = UIView.safeAreaTop
        NotificationCenter.default.post(name: .hideTabbar, object: nil)
        checkLocationPermission()
        viewOTP.dpOTPViewDelegate = self
        viewOTP.textColorTextField = .white
        viewSafeAreaHeader.backgroundColor = Appearance.default.colorPalette.walletTabbarBackground
        viewHeader.backgroundColor = Appearance.default.colorPalette.walletTabbarBackground
        btnBack.setImage(Appearance.default.images.backCircle, for: .normal)
        btnBack.setTitle("", for: .normal)
        view.backgroundColor = Appearance.default.colorPalette.chatViewBackground
        indicator.startAnimating()
        LocationManager.shared.location.bind { [weak self] location in
            guard let self = self else {
                return
            }
            self.indicator.stopAnimating()
            if !LocationManager.shared.isEmptyCurrentLoc() {
                if self.viewOTP.validate() {
                    self.pushToJoinPrivateGroup()
                }
            }
        }
        lblOtpDetails.text = "Join a group with friends nearby by \n entering the secret four digits"
    }

    private func checkLocationPermission() {
        if LocationManager.shared.hasLocationPermissionDenied() {
            LocationManager.showLocationPermissionAlert()
            viewOTP.resignFirstResponder()
        } else {
            LocationManager.shared.requestLocationAuthorization()
            LocationManager.shared.requestGPS()
            viewOTP.becomeFirstResponder()
        }
    }

    // MARK: - Navigations
    private func pushToJoinPrivateGroup() {
        guard let joinPrivateGroupVC: JoinPrivateGroupVC = JoinPrivateGroupVC.instantiateController(storyboard: .PrivateGroup),
              let opt = viewOTP.text,
              !isPushed else {
            return
        }
        joinPrivateGroupVC.passWord = opt
        joinPrivateGroupVC.otpViewDelegate = self
        pushWithAnimation(controller: joinPrivateGroupVC)
        //navigationController?.pushViewController(joinPrivateGroupVC, animated: true)
    }

    private func handleLocationPermissionAndPush() {
        viewOTP.resignFirstResponder()
        if LocationManager.shared.hasLocationPermissionDenied() {
            LocationManager.showLocationPermissionAlert()
        } else if !LocationManager.shared.isEmptyCurrentLoc() {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                guard let self = self else { return }
                self.pushToJoinPrivateGroup()
            }
        }
    }
}

// MARK: - PrivateGroupOTPVCDelegate
extension PrivateGroupOTPVC: PrivateGroupOTPVCDelegate {
    func popToThisVC() {
        isPushed = false
    }
}

// MARK: - OTPView delegate
extension PrivateGroupOTPVC: DPOTPViewDelegate {
    public func dpOTPViewAddText(_ text: String, at position: Int) {
        if viewOTP.validate() {
            handleLocationPermissionAndPush()
        }
    }

    public func dpOTPViewRemoveText(_ text: String, at position: Int) {
        if viewOTP.validate() {
            handleLocationPermissionAndPush()
        }
    }

    public func dpOTPViewChangePositionAt(_ position: Int) {
    }

    public func dpOTPViewBecomeFirstResponder() {
    }

    public func dpOTPViewResignFirstResponder() {
    }
}
