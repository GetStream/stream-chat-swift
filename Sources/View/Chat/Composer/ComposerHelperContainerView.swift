//
//  ComposerHelperContainerView.swift
//  GetStreamChat
//
//  Created by Alexey Bukhtin on 12/05/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import UIKit
import SnapKit

final class ComposerHelperContainerView: UIView {
    
    private(set) var shouldBeShown: Bool = false
    
    private(set) lazy var titleLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.font = .chatRegularBold
        label.textColor = closeButton.tintColor
        return label
    }()
    
    private(set) lazy var containerView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [])
        stackView.axis = .vertical
        return stackView
    }()
    
    private(set) lazy var closeButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(UIImage.Icons.close, for: .normal)
        button.snp.makeConstraints { $0.width.height.equalTo(CGFloat.composerHelperIconSize) }
        button.tintColor = backgroundColor?.oppositeBlackAndWhite ?? .black
        button.backgroundColor = button.tintColor.withAlphaComponent(0.1)
        button.layer.cornerRadius = .composerHelperButtonCornerRadius
        return button
    }()
    
    private func setup() {
        isHidden = true
        layer.cornerRadius = .composerCornerRadius
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = .zero
        layer.shadowRadius = .composerHelperShadowRadius
        layer.shadowOpacity = Float(CGFloat.composerHelperShdowOpacity)
        
        addSubview(closeButton)
        addSubview(titleLabel)
        addSubview(containerView)

        closeButton.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(CGFloat.composerHelperButtonEdgePadding)
            make.right.equalToSuperview().offset(-CGFloat.composerHelperButtonEdgePadding)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(CGFloat.composerHelperTitleEdgePadding)
            make.centerY.equalTo(closeButton.snp.centerY)
        }
        
        containerView.snp.makeConstraints { make in
            make.top.equalTo(closeButton.snp.bottom).offset(CGFloat.messageEdgePadding)
            make.left.right.equalToSuperview()
        }
    }
    
    func add(for composerView: ComposerView) {
        guard let parent = composerView.superview else {
            return
        }
        
        setup()
        parent.insertSubview(self, belowSubview: composerView)
        snp.makeConstraints { $0.left.right.bottom.equalToSuperview() }
        containerView.snp.makeConstraints { $0.bottom.equalTo(composerView.snp.top).offset(-CGFloat.messageEdgePadding) }
    }
    
    func animate(show: Bool) {
        guard shouldBeShown != show else {
            return
        }
        
        removeAllAnimations()
        shouldBeShown = show
        
        let height = frame.height > 0 ? frame.height : UIScreen.main.bounds.height / 2
        let hiddenTransform = CGAffineTransform(translationX: 0, y: height)
        
        if show {
            transform = hiddenTransform
        }
        
        UIView.animateSmoothly(withDuration: 0.4, animations: {
            self.isHidden = false
            self.transform = show ? .identity : hiddenTransform
        }, completion: { _ in
            self.isHidden = !self.shouldBeShown
        })
    }
}
