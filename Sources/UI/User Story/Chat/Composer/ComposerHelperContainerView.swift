//
//  ComposerHelperContainerView.swift
//  StreamChat
//
//  Created by Alexey Bukhtin on 12/05/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import UIKit
import SnapKit

/// A container view for composer view to show more actions or commands.
public final class ComposerHelperContainerView: UIView {
    
    private(set) var shouldBeShown: Bool = false
    
    /// Enables animations to show the container view.
    public var isEnabled = true
    
    private lazy var hiddenTransform = CGAffineTransform(translationX: 0,
                                                         y: frame.height > 0 ? frame.height : UIScreen.main.bounds.height / 2)
    
    private(set) lazy var titleLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.font = .chatRegularBold
        label.textColor = closeButton.tintColor
        return label
    }()
    
    private var containerViewBottomConstraint: Constraint?
    private weak var composerView: ComposerView?
    
    /// TODO: Make it scrollable.
    /// See https://blog.alltheflow.com/scrollable-uistackview/
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
        layer.cornerRadius = .composerHelperCornerRadius
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = .zero
        layer.shadowRadius = .composerHelperShadowRadius
        layer.shadowOpacity = Float(CGFloat.composerHelperShadowOpacity)
        
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
            make.top.equalTo(closeButton.snp.bottom).offset(CGFloat.messageInnerPadding)
            make.left.right.equalToSuperview()
        }
    }
    
    /// Add to a composer view.
    ///
    /// - Note: The composer view should have a parent view.
    ///
    /// - Parameter composerView: a composer view.
    public func add(to composerView: ComposerView) {
        guard let parent = composerView.superview else {
            return
        }
        
        setup()
        self.composerView = composerView
        parent.insertSubview(self, belowSubview: composerView)
        
        snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            make.top.greaterThanOrEqualTo(parent.safeAreaLayoutGuide.snp.topMargin).offset(CGFloat.composerHelperShadowRadius)
        }
        
        moveContainerViewPosition()
    }
    
    /// Move the container view on the top of a given bottom view.
    ///
    /// - Note: It will make the bottom constraint equals to the top constraint of a given view.
    ///         If a given view is nil, then the container view will move back to the position above the composer view.
    ///
    /// - Parameter view: a bottom view.
    public func moveContainerViewPosition(aboveView view: UIView? = nil) {
        guard let view = view ?? self.composerView else {
            return
        }
        
        containerViewBottomConstraint?.deactivate()
        
        containerView.snp.makeConstraints {
            containerViewBottomConstraint = $0.bottom.equalTo(view.snp.top)
                .offset(-CGFloat.messageInnerPadding)
                .priority(999)
                .constraint
        }
    }
    
    /// Show or hide the container view.
    ///
    /// - Parameter show: an action to show or hide the container view.
    public func animate(show: Bool) {
        guard (isEnabled || !show), shouldBeShown != show else {
            return
        }
        
        removeAllAnimations()
        shouldBeShown = show
        
        if show {
            transform = hiddenTransform
            isHidden = false
        }
        
        UIView.animateSmoothly(withDuration: 0.5, options: .curveLinear, animations: {
            self.transform = show ? .identity : self.hiddenTransform
        }, completion: { _ in
            self.isHidden = !self.shouldBeShown
        })
    }
}
