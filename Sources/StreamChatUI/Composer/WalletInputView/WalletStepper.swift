//
//  WalletStepper.swift
//  StreamChatUI
//
//  Created by Parth Kshatriya on 07/01/22.
//  Copyright © 2022 Stream.io Inc. All rights reserved.
//

import UIKit

class WalletStepper: UIView {

    enum ScrollDirection {
        case upDown
        case leftRight
    }

    enum CurrencyType: String {
        case ONE
        case USD
    }

    // MARK: - Variables
    private lazy var containerView: UIView = UIView()
        .withoutAutoresizingMaskConstraints

    private lazy var detailView: UIView = UIView()
        .withoutAutoresizingMaskConstraints

    private lazy var btnAdd: UIButton = UIButton()
        .withoutAutoresizingMaskConstraints

    private lazy var btnRemove: UIButton = UIButton()
        .withoutAutoresizingMaskConstraints

    private lazy var containerInputView: UIView = UIView()
        .withoutAutoresizingMaskConstraints

    private lazy var lblAmount: UILabel = UILabel()
        .withoutAutoresizingMaskConstraints

    private lazy var lblAmountType: UILabel = UILabel()
        .withoutAutoresizingMaskConstraints
    private lazy var imgClose: UIImageView = UIImageView()
        .withoutAutoresizingMaskConstraints

    private var centerContainerXLayoutConstraint: NSLayoutConstraint?
    private var centerContainerYLayoutConstraint: NSLayoutConstraint?
    private var startPosition: CGPoint!
    public var value: Double = 0 {
        didSet {
            formatAmount()
        }
    }
    public var minimumValue: Double = 0.0
    public var maximumValue: Double = 400
    private var scrollDirection: ScrollDirection?
    private var currencyType: CurrencyType = .ONE {
        didSet {
            self.lblAmountType.text = currencyType.rawValue
        }
    }
    private var scrollLock = false
    private(set) lazy var bgView = UIView()
        .withoutAutoresizingMaskConstraints

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupLayout()
        self.translatesAutoresizingMaskIntoConstraints = false
    }

    func setupLayout() {
        self.backgroundColor = Appearance.default.colorPalette.walletTabbarBackground
        self.embed(containerView)
        self.backgroundColor = .clear
        containerView.backgroundColor = Appearance.default.colorPalette.stepperBackground
        containerView.cornerRadius = self.frame.height / 2

        containerView.addSubview(btnAdd)
        containerView.insertSubview(btnRemove, belowSubview: btnAdd)
        btnRemove.setImage(Appearance.default.images.remove, for: .normal)
        btnAdd.setImage(Appearance.default.images.add, for: .normal)
        btnAdd.addTarget(self, action: #selector(btnAddAction), for: .touchUpInside)
        btnRemove.addTarget(self, action: #selector(btnRemoveAction), for: .touchUpInside)

        btnAdd.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -40).isActive = true
        btnAdd.centerYAnchor.constraint(equalTo: containerView.centerYAnchor).isActive = true
        btnRemove.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 40).isActive = true
        btnRemove.centerYAnchor.constraint(equalTo: containerView.centerYAnchor).isActive = true
        btnRemove.pin(anchors: [.height, .width], to: 30)
        btnAdd.pin(anchors: [.height, .width], to: 30)

        containerView.insertSubview(detailView, aboveSubview: btnAdd)
        detailView.heightAnchor.constraint(equalToConstant: 65).isActive = true
        detailView.widthAnchor.constraint(equalToConstant: 100).isActive = true
        centerContainerXLayoutConstraint = detailView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor)
        centerContainerXLayoutConstraint?.isActive = true
        centerContainerYLayoutConstraint = detailView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor)
        centerContainerYLayoutConstraint?.isActive = true
        detailView.backgroundColor = Appearance.default.colorPalette.stepperForeground
        detailView.cornerRadius = 10

        var dragView = UIStackView()
        dragView.axis = .vertical
        dragView.translatesAutoresizingMaskIntoConstraints = false
        detailView.addSubview(dragView)
        dragView.centerXAnchor.constraint(equalTo: detailView.centerXAnchor).isActive = true
        dragView.centerYAnchor.constraint(equalTo: detailView.centerYAnchor).isActive = true

        dragView.addArrangedSubview(lblAmount)
        lblAmount.widthAnchor.constraint(equalToConstant: 90).isActive = true
        dragView.addArrangedSubview(lblAmountType)

        containerView.insertSubview(imgClose, belowSubview: detailView)
        imgClose.centerXAnchor.constraint(equalTo: containerView.centerXAnchor).isActive = true
        imgClose.centerYAnchor.constraint(equalTo: containerView.centerYAnchor).isActive = true
        imgClose.image = Appearance.default.images.close
        imgClose.tintColor = .white

        lblAmount.font = .systemFont(ofSize: 22)
        lblAmount.adjustsFontSizeToFitWidth = true
        lblAmountType.font = .systemFont(ofSize: 12)
        lblAmount.text = "0"
        lblAmount.textAlignment = .center
        lblAmountType.textAlignment = .center
        lblAmountType.text = "ONE"
        lblAmount.textColor = .white
        lblAmountType.textColor = .white.withAlphaComponent(0.6)
        setupGestureRecognizer()
        self.clipsToBounds = false
        containerView.clipsToBounds = false
        detailView.clipsToBounds = true
    }

    func setupGestureRecognizer() {
        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(panGestureDidReceiveInteraction(_:)))
        addGestureRecognizer(panGestureRecognizer)
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(switchCurrencyFormat))
        self.detailView.addGestureRecognizer(tapGesture)
    }

    @objc func btnAddAction() {
        updateAmount(amount: value + 1.0)
    }

    @objc func btnRemoveAction() {
        updateAmount(amount: value - 1.0)
    }

    @objc func switchCurrencyFormat() {
        currencyType = currencyType == .ONE ? .USD : .ONE
        value = 0.0
    }

    @objc func panGestureDidReceiveInteraction(_ panGesture: UIPanGestureRecognizer) {
        guard let centerContainerXLayoutConstraint = centerContainerXLayoutConstraint, let centerContainerYLayoutConstraint = centerContainerYLayoutConstraint else { return }
        let gestureLocation = panGesture.location(in: self)
        if panGesture.state == .began {
            startPosition = gestureLocation
        } else if panGesture.state == .changed {
            if scrollLock == false {
                scrollDirection = (abs(startPosition.y - gestureLocation.y) > 3) ? .upDown : .leftRight
                scrollLock = true
            }
            guard let scrollDirection = scrollDirection else { return }
            if scrollDirection == .upDown {
                guard let panGestureInteractionInformation = startPosition else { return }
                let offsetFromStart = gestureLocation.y - panGestureInteractionInformation.y
                if offsetFromStart > 0 {
                    let centerX = (detailView.bounds.height / 2) + 15
                    let viewAlpha = max((1 - abs(offsetFromStart) / centerX), 0.2)
                    btnAdd.alpha = viewAlpha
                    btnRemove.alpha = viewAlpha
                    imgClose.alpha = max((abs(offsetFromStart) / centerX), 1)
                    centerContainerYLayoutConstraint.constant = min(offsetFromStart, centerX)
                }
            } else {
                guard let panGestureInteractionInformation = startPosition else { return }
                let offsetFromStart = gestureLocation.x - panGestureInteractionInformation.x
                let centerX = (detailView.bounds.width / 2) + 10
                let viewAlpha = max((1 - abs(offsetFromStart) / centerX), 0.2)
                btnAdd.alpha = viewAlpha
                btnRemove.alpha = viewAlpha
                imgClose.alpha = 0
                if offsetFromStart < 0 {
                    centerContainerXLayoutConstraint.constant = max(offsetFromStart, 0 - centerX)
                } else {
                    centerContainerXLayoutConstraint.constant = min(offsetFromStart, centerX)
                }
            }

        } else if panGesture.state == .ended {
            scrollLock = false
            if scrollDirection == .leftRight {
                let offset = centerContainerXLayoutConstraint.constant
                let maxOffset = (detailView.bounds.width / 3)
                if abs(offset) > abs(maxOffset / 2) {
                    if #available(iOS 13.0, *) {
                        hapticFeedback(style: .soft)
                    } else {
                        hapticFeedback(style: .light)
                    }
                    if offset < 0 {
                        btnRemoveAction()
                    } else {
                        btnAddAction()
                    }
                }
            } else {
                let offset = centerContainerYLayoutConstraint.constant
                let maxOffset = (detailView.bounds.height / 3)
                if abs(offset) > abs(maxOffset / 2) {
                    value = 0
                    if #available(iOS 13.0, *) {
                        hapticFeedback(style: .soft)
                    } else {
                        hapticFeedback(style: .light)
                    }
                }
            }

            centerContainerXLayoutConstraint.constant = 0
            centerContainerYLayoutConstraint.constant = 0
            self.animate(animations: { [weak self] in
                guard let `self` = self else { return }
                self.layoutIfNeeded()
                self.btnAdd.alpha = 1
                self.btnRemove.alpha = 1
            }, completion: { [weak self] in
                guard let `self` = self else { return }
                self.startPosition = nil
            })
        }
    }

    func updateAmount(amount: Double) {
        if amount > maximumValue {
            self.requireUserAttention(on: lblAmount)
            return
        } else if amount < 0 {
            return
        }
        self.value = amount
        formatAmount()
    }

    func insertNumber(numberValue: String?) {
        var amountString = ""
        guard isValidAmountInput(numberValue: numberValue ?? "") else { return }
        if let keyPadNumber = numberValue {
            var walletInputAmount = "\(self.lblAmount.text ?? "")".trimmingCharacters(in: .whitespaces)
            if walletInputAmount == "0" && keyPadNumber != "." {
                walletInputAmount = ""
            }
            amountString = "\(walletInputAmount)" + "\(keyPadNumber ?? "")"
            if numberValue == "." {
                lblAmount.text = amountString
            } else {
                let amount = amountString.replacingOccurrences(of: ",", with: "")
                if !amount.replacingOccurrences(of: "0", with: "").replacingOccurrences(of: ".", with: "").isEmpty &&
                    !(amount.components(separatedBy: ".").last?.replacingOccurrences(of: "0", with: "").isEmpty ?? false) {
                    self.updateAmount(amount: Double(amount) ?? 0.0)
                } else {
                    lblAmount.text = amount
                }
            }
        } else {
            amountString = "\(self.lblAmount.text ?? "")".trimmingCharacters(in: .whitespaces)
            amountString.removeLast()
            if amountString.isEmpty {
                value = 0
            } else {
                let amount = amountString.replacingOccurrences(of: ",", with: "")
                if !amount.replacingOccurrences(of: "0", with: "").replacingOccurrences(of: ".", with: "").isEmpty &&
                    !(amount.components(separatedBy: ".").last?.replacingOccurrences(of: "0", with: "").isEmpty ?? false) {
                    self.updateAmount(amount: Double(amount) ?? 0.0)
                } else {
                    lblAmount.text = amount
                }
            }
        }

    }

    private func isValidAmountInput(numberValue: String) -> Bool {
        if (self.lblAmount.text ?? "").contains(".") && numberValue == "." {
            return false
        }
        var walletInputAmount = "\(self.lblAmount.text ?? "")" + numberValue
        guard walletInputAmount.contains(".") else { return true }
        if currencyType == .ONE {
            return !(walletInputAmount.components(separatedBy: ".").last?.count ?? 0 > 3)
        } else {
            return !(walletInputAmount.components(separatedBy: ".").last?.count ?? 0 > 2)
        }
    }

    private func formatAmount() {
        let currencyFormatter = NumberFormatter()
        currencyFormatter.usesGroupingSeparator = true
        currencyFormatter.numberStyle = .currency
        currencyFormatter.currencySymbol = ""
        currencyFormatter.maximumFractionDigits = 4
        currencyFormatter.minimumFractionDigits = 0
        currencyFormatter.locale = Locale.current
        if let priceString = currencyFormatter.string(from: NSNumber(value: value)) {
            lblAmount.text = priceString
        }
    }

    private func animate(animations: @escaping (() -> Void), completion: @escaping (() -> Void)) {
        UIView.animate(withDuration: 0.6, delay: 0.0, usingSpringWithDamping: 0.75, initialSpringVelocity: 2, options: .curveEaseInOut, animations: animations, completion: { _ in
            completion()
        })
    }

    private func requireUserAttention(on onView: UIView) {
        let animation = CABasicAnimation(keyPath: "position")
        animation.duration = 0.1
        animation.repeatCount = 2
        animation.autoreverses = true
        animation.fromValue = NSValue(cgPoint: CGPoint(x: onView.center.x - 10, y: onView.center.y))
        animation.toValue = NSValue(cgPoint: CGPoint(x: onView.center.x + 10, y: onView.center.y))
        onView.layer.add(animation, forKey: "position")
        hapticFeedback(style: .medium)
    }

    private func hapticFeedback(style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }

}
