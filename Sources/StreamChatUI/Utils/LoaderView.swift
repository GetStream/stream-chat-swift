//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import UIKit

extension UIView {
    func showLoader(heightToCornerRadiusRatio: CGFloat) {
        isUserInteractionEnabled = false
        if self is UITableView {
            ListLoader.addLoaderTo(self as! UITableView, heightToCornerRadiusRatio: heightToCornerRadiusRatio)
        } else if self is UICollectionView {
            ListLoader.addLoaderTo(self as! UICollectionView, heightToCornerRadiusRatio: heightToCornerRadiusRatio)
        } else {
            ListLoader.addLoaderToViews([self], heightToCornerRadiusRatio: heightToCornerRadiusRatio)
        }
    }
    
    func hideLoader() {
        isUserInteractionEnabled = true
        if self is UITableView {
            ListLoader.removeLoaderFrom(self as! UITableView)
        } else if self is UICollectionView {
            ListLoader.removeLoaderFrom(self as! UICollectionView)
        } else {
            ListLoader.removeLoaderFromViews([self])
        }
    }
}

protocol ListLoadable {
    func ld_visibleContentViews() -> [UIView]
}

extension UITableView: ListLoadable {
    func ld_visibleContentViews() -> [UIView] {
        (visibleCells as NSArray).value(forKey: "contentView") as! [UIView]
    }
}

extension UICollectionView: ListLoadable {
    func ld_visibleContentViews() -> [UIView] {
        (visibleCells as NSArray).value(forKey: "contentView") as! [UIView]
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

extension UIView {
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

extension CGFloat {
    func doubleValue() -> Double {
        Double(self)
    }
}

enum ListLoader {
    static func addLoaderToViews(_ views: [UIView], heightToCornerRadiusRatio: CGFloat) {
        let views = views.filter { !$0.subviews.contains(where: { $0 is CutoutView }) }
        CATransaction.begin()
        views.forEach { $0.ld_addLoader(heightToCornerRadiusRatio: heightToCornerRadiusRatio) }
        CATransaction.commit()
    }
    
    static func removeLoaderFromViews(_ views: [UIView]) {
        CATransaction.begin()
        views.forEach { $0.ld_removeLoader() }
        CATransaction.commit()
    }
    
    public static func addLoaderTo(_ list: ListLoadable, heightToCornerRadiusRatio: CGFloat) {
        addLoaderToViews(list.ld_visibleContentViews(), heightToCornerRadiusRatio: heightToCornerRadiusRatio)
    }
    
    public static func removeLoaderFrom(_ list: ListLoadable) {
        removeLoaderFromViews(list.ld_visibleContentViews())
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
        
        for view in (superview?.subviews)! {
            if view != self {
                if view is UIStackView || view is ContainerStackView {
                    recursivelyDrawCutOutInView(view, fromParentView: view.superview!, context: context)
                } else {
                    drawPath(context: context, view: view)
                }
            }
        }
    }
    
    private func recursivelyDrawCutOutInView(
        _ view: UIView,
        fromParentView parentView: UIView,
        context: CGContext?
    ) {
        guard let view = view as? Container else { return }
        view.arrangedSubviews.forEach { arrangedSubview in
            if arrangedSubview is Container {
                recursivelyDrawCutOutInView(arrangedSubview, fromParentView: parentView, context: context)
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
                recursivelyDrawCutOutInView(arrangedSubview, fromParentView: parentView, context: context)
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
        ).cgPath
        context?.addPath(clipPath)
        context?.setFillColor(UIColor.clear.cgColor)
        context?.closePath()
        context?.fillPath()
    }

    override func layoutSubviews() {
        setNeedsDisplay()
        superview?.ld_getGradient()?.frame = (superview?.bounds)!
    }
}

extension UIView {
    private static var cutoutHandle: UInt8 = 0
    private static var gradientHandle: UInt8 = 0
    private static var loaderDuration = 0.85
    private static var gradientWidth = 0.17
    private static var gradientFirstStop = 0.1
    
    private func ld_getCutoutView() -> UIView? {
        objc_getAssociatedObject(self, &Self.cutoutHandle) as! UIView?
    }
    
    private func ld_setCutoutView(_ aView: UIView) {
        objc_setAssociatedObject(self, &Self.cutoutHandle, aView, .OBJC_ASSOCIATION_RETAIN)
    }
    
    fileprivate func ld_getGradient() -> CAGradientLayer? {
        objc_getAssociatedObject(self, &Self.gradientHandle) as! CAGradientLayer?
    }
    
    private func ld_setGradient(_ aLayer: CAGradientLayer) {
        objc_setAssociatedObject(self, &Self.gradientHandle, aLayer, .OBJC_ASSOCIATION_RETAIN)
    }
    
    fileprivate func ld_addLoader(heightToCornerRadiusRatio: CGFloat) {
        let gradient: CAGradientLayer = CAGradientLayer()
        gradient.frame = CGRect(x: 0, y: 0, width: bounds.size.width, height: bounds.size.height)
        layer.insertSublayer(gradient, at: 0)
        
        configureAndAddAnimationToGradient(gradient)
        addCutoutView(heightToCornerRadiusRatio: heightToCornerRadiusRatio)
    }
    
    fileprivate func ld_removeLoader() {
        ld_getCutoutView()?.removeFromSuperview()
        ld_getGradient()?.removeAllAnimations()
        ld_getGradient()?.removeFromSuperlayer()
        
        for view in subviews {
            view.alpha = 1
        }
    }
    
    func configureAndAddAnimationToGradient(_ gradient: CAGradientLayer) {
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
            NSNumber(value: gradient.startPoint.x.doubleValue() as Double),
            NSNumber(value: gradient.startPoint.x.doubleValue() as Double),
            NSNumber(value: 0 as Double),
            NSNumber(value: Self.gradientWidth as Double),
            NSNumber(value: 1 + Self.gradientWidth as Double)
        ]
        
        gradient.locations = startLocations
        let gradientAnimation = CABasicAnimation(keyPath: "locations")
        gradientAnimation.fromValue = startLocations
        gradientAnimation.toValue = [
            NSNumber(value: 0 as Double),
            NSNumber(value: 1 as Double), NSNumber(value: 1 as Double),
            NSNumber(value: 1 + (Self.gradientWidth - Self.gradientFirstStop) as Double),
            NSNumber(value: 1 + Self.gradientWidth as Double)
        ]
        
        gradientAnimation.repeatCount = Float.infinity
        gradientAnimation.fillMode = .forwards
        gradientAnimation.isRemovedOnCompletion = false
        gradientAnimation.duration = Self.loaderDuration
        gradient.add(gradientAnimation, forKey: "locations")
        
        ld_setGradient(gradient)
    }
    
    private func addCutoutView(heightToCornerRadiusRatio: CGFloat) {
        let cutout = CutoutView(heightToCornerRadiusRatio: heightToCornerRadiusRatio)
        cutout.frame = bounds
        cutout.backgroundColor = UIColor.clear
        
        addSubview(cutout)
        cutout.setNeedsDisplay()
        cutout.boundInside(self)
        
        for view in subviews {
            if view != cutout {
                view.alpha = 0
            }
        }
        
        ld_setCutoutView(cutout)
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
