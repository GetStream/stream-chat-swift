//
//  WalletInputView.swift
//  StreamChatUI
//
//  Created by Parth Kshatriya on 28/12/21.
//

import UIKit
import StreamChat

class WalletInputView: UIInputView {

    // MARK: - Variables
    var keyboardToolTipTapped: ((_ tooltip: ToolKit) -> Void)?
    var showKeypad: (() -> Void)?
    lazy var toolTipList: [ToolKit] = {
        return KeyboardToolKit().getList()
    }()

    private var contentViewBottomConstraint: NSLayoutConstraint!

    lazy var containerView: UIView = UIView()
        .withoutAutoresizingMaskConstraints

    lazy var containerInputView: UIView = UIView()
        .withoutAutoresizingMaskConstraints

    private(set) lazy var toolBarCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 8
        layout.scrollDirection = .horizontal
        let collectionView = UICollectionView(
            frame: .init(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 38),
            collectionViewLayout: layout)
            .withoutAutoresizingMaskConstraints
        collectionView.backgroundColor = .clear
        collectionView.showsHorizontalScrollIndicator = false
        return collectionView
    }()
    
    var intrinsicHeight: CGFloat = 340 {
        didSet {
            self.invalidateIntrinsicContentSize()
        }
    }

    override var intrinsicContentSize: CGSize {
        return CGSize(width: UIView.noIntrinsicMetric, height: self.intrinsicHeight)
    }

    private(set) lazy var bgView = UIView()
        .withoutAutoresizingMaskConstraints

    init() {
        super.init(frame: CGRect(), inputViewStyle: .default)
        self.translatesAutoresizingMaskIntoConstraints = false
        setupLayout()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.translatesAutoresizingMaskIntoConstraints = false
    }

    func setupLayout() {
        self.backgroundColor = Appearance.default.colorPalette.walletTabbarBackground

        self.addSubview(containerView)

        toolBarCollectionView.delegate = self
        toolBarCollectionView.dataSource = self
        toolBarCollectionView.register(KeyboardToolTipCVCell.self,
                                       forCellWithReuseIdentifier: KeyboardToolTipCVCell.reuseId)


//        self.addSubview(toolBarCollectionView)
//        toolBarCollectionView.heightAnchor.constraint(equalToConstant: 38).isActive = true
//        toolBarCollectionView.leadingAnchor.constraint(equalTo: self.leadingAnchor).isActive = true
//        toolBarCollectionView.trailingAnchor.constraint(equalTo: self.trailingAnchor).isActive = true
//        toolBarCollectionView.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
//        toolBarCollectionView.reloadData()
//        toolBarCollectionView.backgroundColor = Appearance.default.colorPalette.walletTabbarBackground

        containerView.leadingAnchor.constraint(equalTo: self.leadingAnchor).isActive = true
        containerView.trailingAnchor.constraint(equalTo: self.trailingAnchor).isActive = true
        contentViewBottomConstraint = containerView.bottomAnchor.constraint(equalTo: self.bottomAnchor)
        contentViewBottomConstraint.isActive = true
        containerView.heightAnchor.constraint(equalTo: self.heightAnchor, constant: 0).isActive = true
        containerView.backgroundColor = .black

//        let gesture = UIPanGestureRecognizer(target: self, action: #selector(panGesture))
//        self.addGestureRecognizer(gesture)
//        gesture.delegate = self


        //Add containerInputView
        self.containerView.addSubview(containerInputView)
        containerInputView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor).isActive = true
        containerInputView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 100).isActive = true

        var requestStack = UIStackView()
        requestStack.distribution = .fillEqually
        let btnRequest = UIButton()
        btnRequest.setTitle("Request", for: .normal)
        btnRequest.setTitleColor(.white, for: .normal)
        btnRequest.titleLabel?.font = .systemFont(ofSize: 12)
        btnRequest.backgroundColor = Appearance.default.colorPalette.walletTabbarBackground
        btnRequest.widthAnchor.constraint(equalToConstant: 100).isActive = true
        btnRequest.layer.cornerRadius = 15
        btnRequest.layer.maskedCorners = [.layerMinXMinYCorner, .layerMinXMaxYCorner]

        let btnPay = UIButton()
        btnPay.setTitle("Pay", for: .normal)
        btnPay.setTitleColor(.white, for: .normal)
        btnPay.titleLabel?.font = .systemFont(ofSize: 12)
        btnPay.backgroundColor = Appearance.default.colorPalette.walletTabbarBackground
        btnPay.widthAnchor.constraint(equalToConstant: 100).isActive = true
        btnPay.layer.cornerRadius = 15
        btnPay.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMaxXMaxYCorner]

        requestStack.addArrangedSubview(btnRequest)
        requestStack.addArrangedSubview(btnPay)
        requestStack.axis = .horizontal
        requestStack.heightAnchor.constraint(equalToConstant: 30).isActive = true
        requestStack.spacing = 5
        requestStack.translatesAutoresizingMaskIntoConstraints = false

        //Amount Stack
        var amountStack = UIStackView()
        let btnAdd = UIButton()
        btnAdd.setTitle("+", for: .normal)
        btnAdd.setTitleColor(.white, for: .normal)
        btnAdd.backgroundColor = Appearance.default.colorPalette.walletTabbarBackground
        btnAdd.widthAnchor.constraint(equalToConstant: 40).isActive = true
        btnAdd.layer.cornerRadius = 35
        btnAdd.layer.maskedCorners = [.layerMinXMinYCorner, .layerMinXMaxYCorner]

        let btnRemove = UIButton()
        btnRemove.setTitle("-", for: .normal)
        btnRemove.setTitleColor(.white, for: .normal)
        btnRemove.backgroundColor = Appearance.default.colorPalette.walletTabbarBackground
        btnRemove.widthAnchor.constraint(equalToConstant: 40).isActive = true
        btnRemove.layer.cornerRadius = 35
        btnRemove.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMaxXMaxYCorner]

        let viewAmount = UIStackView()
        viewAmount.axis = .vertical
        viewAmount.spacing = 5
        let lblAmount = UILabel()
        lblAmount.textAlignment = .center
        lblAmount.text = "0$"
        lblAmount.font = .systemFont(ofSize: 25, weight: .bold)
        lblAmount.textColor = .white

        let btnShowKeyboard = UIButton()
        btnShowKeyboard.setTitle("Show Keypad", for: .normal)
        btnShowKeyboard.titleLabel?.font = .systemFont(ofSize: 10)
        btnShowKeyboard.setTitleColor(.white, for: .normal)
        btnShowKeyboard.addTarget(self, action: #selector(btnShowKeyboardAction), for: .touchUpInside)

        viewAmount.addArrangedSubview(lblAmount)
        viewAmount.addArrangedSubview(btnShowKeyboard)
        viewAmount.widthAnchor.constraint(equalToConstant: 150).isActive = true
        viewAmount.backgroundColor = Appearance.default.colorPalette.walletTabbarBackground

        amountStack.addArrangedSubview(btnAdd)
        amountStack.addArrangedSubview(viewAmount)
        amountStack.addArrangedSubview(btnRemove)
        amountStack.axis = .horizontal
        amountStack.distribution = .fillProportionally
        amountStack.heightAnchor.constraint(equalToConstant: 70).isActive = true
        amountStack.spacing = 5

        amountStack.translatesAutoresizingMaskIntoConstraints = false

        containerInputView.addSubview(requestStack)
        containerInputView.addSubview(amountStack)
        requestStack.translatesAutoresizingMaskIntoConstraints = false
        amountStack.translatesAutoresizingMaskIntoConstraints = false

        amountStack.leadingAnchor.constraint(equalTo: containerInputView.leadingAnchor).isActive = true
        amountStack.trailingAnchor.constraint(equalTo: containerInputView.trailingAnchor).isActive = true
        amountStack.topAnchor.constraint(equalTo: containerInputView.topAnchor).isActive = true

        requestStack.centerXAnchor.constraint(equalTo: containerInputView.centerXAnchor).isActive = true
        requestStack.topAnchor.constraint(equalTo: amountStack.bottomAnchor, constant: 15).isActive = true
        requestStack.bottomAnchor.constraint(equalTo: containerInputView.bottomAnchor).isActive = true

    }

    @objc private func panGesture(_ recognizer: UIPanGestureRecognizer) {
        let translation = recognizer.translation(in: self)
        let y = self.frame.minY
        containerView.frame = CGRect(x: 0, y: y + translation.y, width: self.frame.width, height: self.frame.height)
        recognizer.setTranslation(CGPoint.zero, in: self)
    }

    @objc func btnShowKeyboardAction() {
        showKeypad?()
    }
}

extension WalletInputView: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return toolTipList.count
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: KeyboardToolTipCVCell.reuseId,
            for: indexPath) as? KeyboardToolTipCVCell else {
            return UICollectionViewCell()
        }
        let indexData = toolTipList[indexPath.row]
        cell.configCell(indexData)
        return cell
    }

    public func collectionView(_ collectionView: UICollectionView,
                               layout collectionViewLayout: UICollectionViewLayout,
                               sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 40, height: collectionView.frame.height)
    }

    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let indexData = toolTipList[indexPath.row]
        keyboardToolTipTapped?(indexData)
    }

    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: 8, height: collectionView.frame.height)
    }

    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        return CGSize(width: 8, height: collectionView.frame.height)
    }
}

extension WalletInputView: UIGestureRecognizerDelegate {
    public func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        return false
    }
}
