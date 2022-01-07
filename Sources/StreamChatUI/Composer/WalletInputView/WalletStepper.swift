//
//  WalletStepper.swift
//  StreamChatUI
//
//  Created by Parth Kshatriya on 07/01/22.
//  Copyright © 2022 Stream.io Inc. All rights reserved.
//

import UIKit

class WalletStepper: UIView {

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

    private var centerContainerXLayoutConstraint: NSLayoutConstraint?
    private var centerContainerYLayoutConstraint: NSLayoutConstraint?
    private var startPosition: CGPoint!
    public var value: Int = 0 {
        didSet {
            updateAmount()
        }
    }
    public var minimumValue: Int = 0
    public var maximumValue: Int = Int.max
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
        dragView.addArrangedSubview(lblAmountType)
        lblAmount.font = .systemFont(ofSize: 22)
        lblAmountType.font = .systemFont(ofSize: 12)
        lblAmount.text = "0"
        lblAmount.textAlignment = .center
        lblAmountType.textAlignment = .center
        lblAmountType.text = "ONE"
        lblAmount.textColor = .white
        lblAmountType.textColor = .white.withAlphaComponent(0.6)
        setupPanGestureRecognizer()
    }

    func setupPanGestureRecognizer() {
        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(panGestureDidReceiveInteraction(_:)))
        addGestureRecognizer(panGestureRecognizer)
    }

    @objc func btnAddAction() {
        value += 1
    }

    @objc func btnRemoveAction() {
        value -= 1
    }

    @objc func panGestureDidReceiveInteraction(_ panGesture: UIPanGestureRecognizer) {
        guard let centerContainerXLayoutConstraint = centerContainerXLayoutConstraint, let centerContainerYLayoutConstraint = centerContainerYLayoutConstraint else { return }
        let gestureLocation = panGesture.location(in: self)
        if panGesture.state == .began {
            startPosition = gestureLocation
        } else if panGesture.state == .changed {
            print(gestureLocation)
            print(startPosition)
            print(abs(startPosition.y - gestureLocation.y))

            if abs(startPosition.y - gestureLocation.y) > 5 {
                guard let panGestureInteractionInformation = startPosition else { return }
                let offsetFromStart = gestureLocation.y - panGestureInteractionInformation.y
                let centerX = (detailView.bounds.height / 2) + 10
                let viewAlpha = max((1 - abs(offsetFromStart) / centerX), 0.2)
                btnAdd.alpha = viewAlpha
                btnRemove.alpha = viewAlpha
                if offsetFromStart > 0 {
                    centerContainerYLayoutConstraint.constant = min(offsetFromStart, centerX)
                }
            } else {
                print("left right")
                guard let panGestureInteractionInformation = startPosition else { return }
                let offsetFromStart = gestureLocation.x - panGestureInteractionInformation.x
                let centerX = (detailView.bounds.width / 2) + 10
                let viewAlpha = max((1 - abs(offsetFromStart) / centerX), 0.2)
                btnAdd.alpha = viewAlpha
                btnRemove.alpha = viewAlpha
                if offsetFromStart < 0 {
                    centerContainerXLayoutConstraint.constant = max(offsetFromStart, 0 - centerX)
                } else {
                    centerContainerXLayoutConstraint.constant = min(offsetFromStart, centerX)
                }
            }

        } else if panGesture.state == .ended {
            let offset = centerContainerXLayoutConstraint.constant
            let maxOffset = (detailView.bounds.width / 3)
            if abs(offset) > abs(maxOffset / 2) {
                if offset < 0 {
                    btnRemoveAction()
                } else {
                    btnAddAction()
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

    private func updateAmount() {
        lblAmount.text = "\(value)"
    }

    func updateAmount(amount: Int) {
        self.value = amount
        updateAmount()
    }

    private func animate(animations: @escaping (() -> Void), completion: @escaping (() -> Void)) {
        UIView.animate(withDuration: 0.6, delay: 0.0, usingSpringWithDamping: 0.75, initialSpringVelocity: 2, options: .curveEaseInOut, animations: animations, completion: { _ in
            completion()
        })
    }

}
