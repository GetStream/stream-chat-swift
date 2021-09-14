//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import UIKit

extension UIView {
    func showLoader(heightToCornerRadiusRatio: CGFloat) {
        isUserInteractionEnabled = false
        if self is UITableView {
            ListLoader.addLoaderTo(
                list: self as! UITableView,
                heightToCornerRadiusRatio: heightToCornerRadiusRatio
            )
        } else if self is UICollectionView {
            ListLoader.addLoaderTo(
                list: self as! UICollectionView,
                heightToCornerRadiusRatio: heightToCornerRadiusRatio
            )
        } else {
            ListLoader.addLoaderTo(
                views: [self],
                heightToCornerRadiusRatio: heightToCornerRadiusRatio
            )
        }
    }
    
    func hideLoader() {
        isUserInteractionEnabled = true
        if self is UITableView {
            ListLoader.removeLoaderFrom(list: self as! UITableView)
        } else if self is UICollectionView {
            ListLoader.removeLoaderFrom(list: self as! UICollectionView)
        } else {
            ListLoader.removeLoaderFrom(views: [self])
        }
    }
}

protocol ListLoadable {
    func visibleContentViews() -> [UIView]
}

extension UITableView: ListLoadable {
    func visibleContentViews() -> [UIView] {
        (visibleCells as NSArray).value(forKey: "contentView") as? [UIView] ?? []
    }
}

extension UICollectionView: ListLoadable {
    func visibleContentViews() -> [UIView] {
        (visibleCells as NSArray).value(forKey: "contentView") as? [UIView] ?? []
    }
}

extension UIColor {
    static func backgroundFadedGrey() -> UIColor {
        UIColor(red: (246.0 / 255.0), green: (247.0 / 255.0), blue: (248.0 / 255.0), alpha: 1)
    }
    
    static func gradientFirstStop() -> UIColor {
        UIColor(red: (238.0 / 255.0), green: (238.0 / 255.0), blue: (238.0 / 255.0), alpha: 1.0)
    }
    
    static func gradientSecondStop() -> UIColor {
        UIColor(red: (221.0 / 255.0), green: (221.0 / 255.0), blue: (221.0 / 255.0), alpha: 1.0)
    }
}

private extension UIView {
    func boundInside(_ superView: UIView) {
        translatesAutoresizingMaskIntoConstraints = false
        superView.addConstraints(
            NSLayoutConstraint.constraints(
                withVisualFormat: "H:|-0-[subview]-0-|",
                options: NSLayoutConstraint.FormatOptions(),
                metrics: nil,
                views: ["subview": self]
            )
        )
        superView.addConstraints(
            NSLayoutConstraint.constraints(
                withVisualFormat: "V:|-0-[subview]-0-|",
                options: NSLayoutConstraint.FormatOptions(),
                metrics: nil,
                views: ["subview": self]
            )
        )
    }
}

private extension CGFloat {
    func doubleValue() -> Double {
        Double(self)
    }
}

enum ListLoader {
    static func addLoaderTo(views: [UIView], heightToCornerRadiusRatio: CGFloat) {
        let views = views.filter { !$0.subviews.contains(where: { $0 is CutoutView }) }
        CATransaction.begin()
        views.forEach { $0.addLoader(heightToCornerRadiusRatio: heightToCornerRadiusRatio) }
        CATransaction.commit()
    }
    
    static func removeLoaderFrom(views: [UIView]) {
        CATransaction.begin()
        views.forEach { $0.removeLoader() }
        CATransaction.commit()
    }
    
    public static func addLoaderTo(list: ListLoadable, heightToCornerRadiusRatio: CGFloat) {
        addLoaderTo(
            views: list.visibleContentViews(),
            heightToCornerRadiusRatio: heightToCornerRadiusRatio
        )
    }
    
    public static func removeLoaderFrom(list: ListLoadable) {
        removeLoaderFrom(views: list.visibleContentViews())
    }
}

final class CutoutView: UIView {
    let heightToCornerRadiusRatio: CGFloat

    init(heightToCornerRadiusRatio: CGFloat) {
        self.heightToCornerRadiusRatio = heightToCornerRadiusRatio
        super.init(frame: .zero)
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        let context = UIGraphicsGetCurrentContext()
        context?.setFillColor(UIColor.white.cgColor)
        context?.fill(bounds)
        
        superview?.subviews.forEach { view in
            if view != self {
                if view is UIStackView || view is ContainerStackView {
                    recursivelyDrawCutOut(
                        in: view,
                        fromParentView: view.superview!,
                        context: context
                    )
                } else {
                    drawPath(context: context, view: view)
                }
            }
        }
    }
    
    private func recursivelyDrawCutOut(
        in view: UIView,
        fromParentView parentView: UIView,
        context: CGContext?
    ) {
        guard let view = view as? Container else { return }
        view.arrangedSubviews.forEach { arrangedSubview in
            if arrangedSubview is Container {
                recursivelyDrawCutOut(
                    in: arrangedSubview,
                    fromParentView: parentView,
                    context: context
                )
                return
            }
            let frame = view.convert(arrangedSubview.frame, to: parentView)
            drawPath(context: context, view: arrangedSubview, fixedFrame: frame)
        }
    }
    
    private func drawCutoutInContainer(
        view: Container,
        fromParentView parentView: UIView,
        context: CGContext?
    ) {
        view.arrangedSubviews.forEach { arrangedSubview in
            if arrangedSubview is Container {
                recursivelyDrawCutOut(
                    in: arrangedSubview,
                    fromParentView: parentView,
                    context: context
                )
                return
            }
            let frame = view.convert(arrangedSubview.frame, to: parentView)
            drawPath(context: context, view: arrangedSubview, fixedFrame: frame)
        }
    }
    
    private func drawPath(
        context: CGContext?,
        view: UIView,
        fixedFrame: CGRect? = nil
    ) {
        let frame = fixedFrame ?? view.frame
        context?.setBlendMode(.clear)
        let rect = frame
        let clipPath: CGPath = UIBezierPath(
            roundedRect: rect,
            cornerRadius: frame.height * heightToCornerRadiusRatio
        )
        .cgPath
        context?.addPath(clipPath)
        context?.setFillColor(UIColor.clear.cgColor)
        context?.closePath()
        context?.fillPath()
    }
    
    override func layoutSubviews() {
        setNeedsDisplay()
        superview?.gradient?.frame = superview?.bounds ?? CGRect()
    }
}

private extension UIView {
    private static var cutoutHandle: UInt8 = 0
    private static var gradientHandle: UInt8 = 0
    private static var loaderDuration = 0.85
    private static var gradientWidth = 0.17
    private static var gradientFirstStop = 0.1
    
    var cutoutView: UIView? {
        get { objc_getAssociatedObject(self, &Self.cutoutHandle) as! UIView? }
        set { objc_setAssociatedObject(self, &Self.cutoutHandle, newValue, .OBJC_ASSOCIATION_RETAIN) }
    }
    
    var gradient: CAGradientLayer? {
        get { objc_getAssociatedObject(self, &Self.gradientHandle) as! CAGradientLayer? }
        set { objc_setAssociatedObject(self, &Self.gradientHandle, newValue, .OBJC_ASSOCIATION_RETAIN) }
    }
    
    func addLoader(heightToCornerRadiusRatio: CGFloat) {
        let gradient: CAGradientLayer = CAGradientLayer()
        gradient.frame = CGRect(x: 0, y: 0, width: bounds.size.width, height: bounds.size.height)
        layer.insertSublayer(gradient, at: 0)
        
        configureAndAddAnimation(to: gradient)
        addCutoutView(heightToCornerRadiusRatio: heightToCornerRadiusRatio)
    }
    
    func removeLoader() {
        cutoutView?.removeFromSuperview()
        gradient?.removeAllAnimations()
        gradient?.removeFromSuperlayer()
        
        subviews.forEach { $0.alpha = 1 }
    }
    
    func configureAndAddAnimation(to gradient: CAGradientLayer) {
        gradient.startPoint = CGPoint(x: -1.0 + CGFloat(Self.gradientWidth), y: 0)
        gradient.endPoint = CGPoint(x: 1.0 + CGFloat(Self.gradientWidth), y: 0)
        
        gradient.colors = [
            UIColor.backgroundFadedGrey().cgColor,
            UIColor.gradientFirstStop().cgColor,
            UIColor.gradientSecondStop().cgColor,
            UIColor.gradientFirstStop().cgColor,
            UIColor.backgroundFadedGrey().cgColor
        ]
        
        let startLocations = [
            NSNumber(value: gradient.startPoint.x.doubleValue()),
            NSNumber(value: gradient.startPoint.x.doubleValue()),
            NSNumber(value: 0),
            NSNumber(value: Self.gradientWidth),
            NSNumber(value: 1 + Self.gradientWidth)
        ]
        
        gradient.locations = startLocations
        let gradientAnimation = CABasicAnimation(keyPath: "locations")
        gradientAnimation.fromValue = startLocations
        gradientAnimation.toValue = [
            NSNumber(value: 0),
            NSNumber(value: 1), NSNumber(value: 1),
            NSNumber(value: 1 + (Self.gradientWidth - Self.gradientFirstStop)),
            NSNumber(value: 1 + Self.gradientWidth)
        ]
        
        gradientAnimation.repeatCount = Float.infinity
        gradientAnimation.fillMode = .forwards
        gradientAnimation.isRemovedOnCompletion = false
        gradientAnimation.duration = Self.loaderDuration
        gradient.add(gradientAnimation, forKey: "locations")
        
        self.gradient = gradient
    }
    
    private func addCutoutView(heightToCornerRadiusRatio: CGFloat) {
        let cutout = CutoutView(heightToCornerRadiusRatio: heightToCornerRadiusRatio)
        cutout.frame = bounds
        cutout.backgroundColor = UIColor.clear
        
        addSubview(cutout)
        cutout.setNeedsDisplay()
        cutout.boundInside(self)
        
        subviews.forEach { view in
            if view != cutout {
                view.alpha = 0
            }
        }
        
        cutoutView = cutout
    }
}

private protocol Container: UIView {
    var arrangedSubviews: [UIView] { get }
}

extension UIStackView: Container {}

extension ContainerStackView: Container {
    var arrangedSubviews: [UIView] {
        subviews
    }
}
