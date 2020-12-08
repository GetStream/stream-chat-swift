//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import UIKit

extension UIView {
    // MARK: - `embed` family of helpers
    
    func embed(_ subview: UIView, insets: NSDirectionalEdgeInsets = .zero) {
        addSubview(subview)
        subview.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            subview.leadingAnchor.constraint(equalTo: leadingAnchor, constant: insets.leading),
            subview.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -insets.trailing),
            subview.topAnchor.constraint(equalTo: topAnchor, constant: insets.top),
            subview.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -insets.bottom)
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
            return fromView.bottomAnchor.constraint(equalTo: toView.bottomAnchor, constant: constant)
        case .centerX:
            return fromView.centerXAnchor.constraint(equalTo: toView.centerXAnchor, constant: constant)
        case .centerY:
            return fromView.centerYAnchor.constraint(equalTo: toView.centerYAnchor, constant: constant)
        case .firstBaseline:
            return fromView.firstBaselineAnchor.constraint(equalTo: toView.firstBaselineAnchor, constant: constant)
        case .height:
            return fromView.heightAnchor.constraint(equalTo: toView.heightAnchor, constant: constant)
        case .lastBaseline:
            return fromView.lastBaselineAnchor.constraint(equalTo: toView.lastBaselineAnchor, constant: constant)
        case .leading:
            return fromView.leadingAnchor.constraint(equalTo: toView.leadingAnchor, constant: constant)
        case .left:
            return fromView.leftAnchor.constraint(equalTo: toView.leftAnchor, constant: constant)
        case .right:
            return fromView.rightAnchor.constraint(equalTo: toView.rightAnchor, constant: constant)
        case .top:
            return fromView.topAnchor.constraint(equalTo: toView.topAnchor, constant: constant)
        case .trailing:
            return fromView.trailingAnchor.constraint(equalTo: toView.trailingAnchor, constant: constant)
        case .width:
            return fromView.widthAnchor.constraint(equalTo: toView.widthAnchor, constant: constant)
        }
    }
    
    func makeConstraint(fromView: UIView, toLayoutGuide: UILayoutGuide, constant: CGFloat = 0) -> NSLayoutConstraint? {
        switch self {
        case .bottom:
            return fromView.bottomAnchor.constraint(equalTo: toLayoutGuide.bottomAnchor, constant: constant)
        case .centerX:
            return fromView.centerXAnchor.constraint(equalTo: toLayoutGuide.centerXAnchor, constant: constant)
        case .centerY:
            return fromView.centerYAnchor.constraint(equalTo: toLayoutGuide.centerYAnchor, constant: constant)
        case .height:
            return fromView.heightAnchor.constraint(equalTo: toLayoutGuide.heightAnchor, constant: constant)
        case .leading:
            return fromView.leadingAnchor.constraint(equalTo: toLayoutGuide.leadingAnchor, constant: constant)
        case .left:
            return fromView.leftAnchor.constraint(equalTo: toLayoutGuide.leftAnchor, constant: constant)
        case .right:
            return fromView.rightAnchor.constraint(equalTo: toLayoutGuide.rightAnchor, constant: constant)
        case .top:
            return fromView.topAnchor.constraint(equalTo: toLayoutGuide.topAnchor, constant: constant)
        case .trailing:
            return fromView.trailingAnchor.constraint(equalTo: toLayoutGuide.trailingAnchor, constant: constant)
        case .width:
            return fromView.widthAnchor.constraint(equalTo: toLayoutGuide.widthAnchor, constant: constant)
        case .firstBaseline, .lastBaseline:
            // TODO: Log warning? Error?
            return nil
        }
    }
    
    func makeConstraint(fromView: UIView, constant: CGFloat) -> NSLayoutConstraint? {
        switch self {
        case .height:
            return fromView.heightAnchor.constraint(equalToConstant: constant)
        case .width:
            return fromView.widthAnchor.constraint(equalToConstant: constant)
        default:
            // TODO: Log warning? Error?
            return nil
        }
    }
}
