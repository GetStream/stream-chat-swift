//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import UIKit

extension UIView {
    // MARK: - `embed` family of helpers

    func embed(_ subview: UIView, insets: NSDirectionalEdgeInsets = .zero) {
        addSubview(subview)

        NSLayoutConstraint.activate([
            subview.leadingAnchor.pin(equalTo: leadingAnchor, constant: insets.leading),
            subview.trailingAnchor.pin(equalTo: trailingAnchor, constant: -insets.trailing),
            subview.topAnchor.pin(equalTo: topAnchor, constant: insets.top),
            subview.bottomAnchor.pin(equalTo: bottomAnchor, constant: -insets.bottom)
        ])
    }
    
    func pin(anchors: [LayoutAnchorName] = [.top, .leading, .bottom, .trailing], to view: UIView) {
        anchors
            .map { $0.makeConstraint(fromView: self, toView: view) }
            .forEach { $0.isActive = true }
    }
    
    func pin(anchors: [LayoutAnchorName] = [.top, .leading, .bottom, .trailing], to layoutGuide: UILayoutGuide) {
        anchors
            .compactMap { $0.makeConstraint(fromView: self, toLayoutGuide: layoutGuide) }
            .forEach { $0.isActive = true }
    }
    
    func pin(anchors: [LayoutAnchorName] = [.width, .height], to constant: CGFloat) {
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
    
    /// Returns `UIView` that is flexible along defined `axis`.
    static func spacer(axis: NSLayoutConstraint.Axis) -> UIView {
        UIView().flexible(axis: axis)
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

extension UIView {
    /// According to this property, you can differ whether the current language is `rightToLeft`
    /// and setup actions according to it.
    var currentLanguageIsRightToLeftDirection: Bool {
        traitCollection.layoutDirection == .rightToLeft
    }
}

extension UIView {

    @IBInspectable public var cornerRadius: CGFloat {
        get {
            return layer.cornerRadius
        }
        set {
            layer.cornerRadius = newValue
            layer.masksToBounds = newValue > 0
        }
    }

    @IBInspectable public var borderWidth: CGFloat {
        get {
            return layer.borderWidth
        }
        set {
            layer.borderWidth = newValue
        }
    }

    @IBInspectable public var borderColor: UIColor? {
        get {
            return UIColor(cgColor: layer.borderColor!)
        }
        set {
            layer.borderColor = newValue?.cgColor
        }
    }
}


extension UIView {
    //
    public func updateChildViewContraint(childView: UIView?) {
        childView?.translatesAutoresizingMaskIntoConstraints = false
        childView?.topAnchor.constraint(equalTo: topAnchor).isActive = true
        childView?.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
        childView?.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        childView?.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
    }
    
    public func updateChildViewInCenter(childView: UIView?, constant: CGFloat = 200) {
        childView?.translatesAutoresizingMaskIntoConstraints = false
        childView?.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        childView?.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        childView?.widthAnchor.constraint(equalToConstant: constant).isActive = true
    }
    public func shake(for duration: TimeInterval = 0.5, withTranslation translation: CGFloat = 10) {
        let propertyAnimator = UIViewPropertyAnimator(duration: duration, dampingRatio: 0.3) {
            self.layer.borderColor = UIColor.red.cgColor
            self.layer.borderWidth = 1
            self.transform = CGAffineTransform(translationX: translation, y: 0)
        }

        propertyAnimator.addAnimations({
            self.transform = CGAffineTransform(translationX: 0, y: 0)
        }, delayFactor: 0.2)

        propertyAnimator.addCompletion { (_) in
            self.layer.borderWidth = 0
        }

        propertyAnimator.startAnimation()
    }
}
