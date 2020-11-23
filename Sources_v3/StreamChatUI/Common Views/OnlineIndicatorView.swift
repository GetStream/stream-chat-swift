//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import UIKit

open class OnlineIndicatorView: UIView {
    public enum AvailabilityStatus {
        case online
        case offline
        case unknown

        var color: UIColor {
            switch self {
            case .online:
                return .systemGreen
            case .offline:
                return .systemRed
            case .unknown:
                return .systemGray
            }
        }
    }

    open var defaultIntrinsicContentSize: CGSize?
    override open var intrinsicContentSize: CGSize {
        defaultIntrinsicContentSize ?? super.intrinsicContentSize
    }

    public var availabilityStatus: AvailabilityStatus? = .offline {
        didSet { layoutSubviews() }
    }

    // MARK: - Init

    override public init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    private func commonInit() {
        applyDefaultAppearance()
        if #available(iOS 13.0, *) {
            self.backgroundColor = .systemBackground // What if cell background is different??
        } else {
            backgroundColor = .white
        }
    }

    // MARK: - Layout

    override open func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = bounds.width / 2
        clipsToBounds = true
        drawIndicatorDot(with: availabilityStatus)
    }

    // MARK: - Private

    private func drawIndicatorDot(with status: AvailabilityStatus?) {
        guard let status = status, status != .unknown else {
            isHidden = true
            return
        }
        isHidden = false

        let indicatorLayer = CAShapeLayer()
        indicatorLayer.path = UIBezierPath(
            arcCenter: CGPoint(x: bounds.width / 2, y: bounds.height / 2),
            radius: 4,
            startAngle: CGFloat(0),
            endAngle: CGFloat.pi * 2,
            clockwise: true
        )
        .cgPath
        // UIBezierPath(ovalIn: CGRect(origin: self.bounds.origin, size: size)).cgPath
        indicatorLayer.fillColor = status.color.cgColor
        layer.addSublayer(indicatorLayer)
    }
}

extension OnlineIndicatorView: AppearanceSetting {
    public static func initialAppearanceSetup(_ view: OnlineIndicatorView) {
        view.defaultIntrinsicContentSize = .init(width: 14, height: 14)
    }
}
