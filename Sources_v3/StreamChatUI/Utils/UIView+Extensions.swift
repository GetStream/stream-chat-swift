//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import UIKit

extension UIView {
    // MARK: - `embed` family of helpers
    
    func embed(_ subview: UIView, insets: NSDirectionalEdgeInsets = .zero) {
        addSubview(subview)
        subview.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            subview.leadingAnchor.pin(equalTo: leadingAnchor, constant: insets.leading),
            subview.trailingAnchor.pin(equalTo: trailingAnchor, constant: -insets.trailing),
            subview.topAnchor.pin(equalTo: topAnchor, constant: insets.top),
            subview.bottomAnchor.pin(equalTo: bottomAnchor, constant: -insets.bottom)
        ])
    }
    
    // MARK: - `pin` family of helpers
    
    func pin(anchors: [LayoutAnchorName] = [.top, .left, .bottom, .right], to view: UIView) {
        translatesAutoresizingMaskIntoConstraints = false
        view.translatesAutoresizingMaskIntoConstraints = false
        anchors
            .map { $0.makeConstraint(fromView: self, toView: view) }
            .forEach { $0.isActive = true }
    }
    
    func pin(anchors: [LayoutAnchorName] = [.top, .left, .bottom, .right], to layoutGuide: UILayoutGuide) {
        translatesAutoresizingMaskIntoConstraints = false
        anchors
            .compactMap { $0.makeConstraint(fromView: self, toLayoutGuide: layoutGuide) }
            .forEach { $0.isActive = true }
    }
    
    func pin(anchors: [LayoutAnchorName] = [.width, .height], to constant: CGFloat) {
        translatesAutoresizingMaskIntoConstraints = false
        anchors
            .compactMap { $0.makeConstraint(fromView: self, constant: constant) }
            .forEach { $0.isActive = true }
    }
    
    var withoutAutoresizingMaskConstraints: Self {
        translatesAutoresizingMaskIntoConstraints = false
        return self
    }

    var isVisible: Bool {
        get { !isHidden }
        set { isHidden = !newValue }
    }
    
    func setAnimatedly(hidden: Bool) {
        Animate({
            self.alpha = hidden ? 0.0 : 1.0
            self.isHidden = hidden
        }) { _ in
            self.isHidden = hidden
        }
    }
}

enum LayoutAnchorName {
    case bottom
    case centerX
    case centerY
    case firstBaseline
    case height
    case lastBaseline
    case leading
    case left
    case right
    case top
    case trailing
    case width
    
    func makeConstraint(fromView: UIView, toView: UIView, constant: CGFloat = 0) -> NSLayoutConstraint {
        switch self {
        case .bottom:
            return fromView.bottomAnchor.pin(equalTo: toView.bottomAnchor, constant: constant)
        case .centerX:
            return fromView.centerXAnchor.pin(equalTo: toView.centerXAnchor, constant: constant)
        case .centerY:
            return fromView.centerYAnchor.pin(equalTo: toView.centerYAnchor, constant: constant)
        case .firstBaseline:
            return fromView.firstBaselineAnchor.pin(equalTo: toView.firstBaselineAnchor, constant: constant)
        case .height:
            return fromView.heightAnchor.pin(equalTo: toView.heightAnchor, constant: constant)
        case .lastBaseline:
            return fromView.lastBaselineAnchor.pin(equalTo: toView.lastBaselineAnchor, constant: constant)
        case .leading:
            return fromView.leadingAnchor.pin(equalTo: toView.leadingAnchor, constant: constant)
        case .left:
            return fromView.leftAnchor.pin(equalTo: toView.leftAnchor, constant: constant)
        case .right:
            return fromView.rightAnchor.pin(equalTo: toView.rightAnchor, constant: constant)
        case .top:
            return fromView.topAnchor.pin(equalTo: toView.topAnchor, constant: constant)
        case .trailing:
            return fromView.trailingAnchor.pin(equalTo: toView.trailingAnchor, constant: constant)
        case .width:
            return fromView.widthAnchor.pin(equalTo: toView.widthAnchor, constant: constant)
        }
    }
    
    func makeConstraint(fromView: UIView, toLayoutGuide: UILayoutGuide, constant: CGFloat = 0) -> NSLayoutConstraint? {
        switch self {
        case .bottom:
            return fromView.bottomAnchor.pin(equalTo: toLayoutGuide.bottomAnchor, constant: constant)
        case .centerX:
            return fromView.centerXAnchor.pin(equalTo: toLayoutGuide.centerXAnchor, constant: constant)
        case .centerY:
            return fromView.centerYAnchor.pin(equalTo: toLayoutGuide.centerYAnchor, constant: constant)
        case .height:
            return fromView.heightAnchor.pin(equalTo: toLayoutGuide.heightAnchor, constant: constant)
        case .leading:
            return fromView.leadingAnchor.pin(equalTo: toLayoutGuide.leadingAnchor, constant: constant)
        case .left:
            return fromView.leftAnchor.pin(equalTo: toLayoutGuide.leftAnchor, constant: constant)
        case .right:
            return fromView.rightAnchor.pin(equalTo: toLayoutGuide.rightAnchor, constant: constant)
        case .top:
            return fromView.topAnchor.pin(equalTo: toLayoutGuide.topAnchor, constant: constant)
        case .trailing:
            return fromView.trailingAnchor.pin(equalTo: toLayoutGuide.trailingAnchor, constant: constant)
        case .width:
            return fromView.widthAnchor.pin(equalTo: toLayoutGuide.widthAnchor, constant: constant)
        case .firstBaseline, .lastBaseline:
            // TODO: Log warning? Error?
            return nil
        }
    }
    
    func makeConstraint(fromView: UIView, constant: CGFloat) -> NSLayoutConstraint? {
        switch self {
        case .height:
            return fromView.heightAnchor.pin(equalToConstant: constant)
        case .width:
            return fromView.widthAnchor.pin(equalToConstant: constant)
        default:
            // TODO: Log warning? Error?
            return nil
        }
    }
}
