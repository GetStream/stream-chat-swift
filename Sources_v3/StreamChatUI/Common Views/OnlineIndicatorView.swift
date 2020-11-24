//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import UIKit

/// View indicating whether the user is online or not.
/// This view is meant to be the green dot on the `ChatChannelAvatarView` indicating that
/// the user is online, should work only for 1-1 Chat and currently shown only green when online.
open class OnlineIndicatorView: UIView {
    /// Enum describing current status of the user inside the chat,
    /// currently, we are indicating just state:
    /// - online: Uses green color when the user is online
    public enum AvailabilityStatus {
        case online
        case none

        var color: UIColor {
            switch self {
            case .online:
                if #available(iOS 13, *) {
                    return .systemGreen
                } else {
                    return .green
                }
            case .none: fatalError("You should never request the color for none status.")
            }
        }
    }

    open var defaultIntrinsicContentSize: CGSize?
    override open var intrinsicContentSize: CGSize {
        defaultIntrinsicContentSize ?? super.intrinsicContentSize
    }

    public var availabilityStatus: AvailabilityStatus = .none {
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
            backgroundColor = .systemBackground // What if cell background is different??
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
        guard let status = status, status != .none else {
            isHidden = true
            return
        }
        isHidden = false
        let indicatorLayer = CALayer()
        indicatorLayer.masksToBounds = true

        indicatorLayer.frame = CGRect(
            origin: .zero,
            size: CGSize(width: 8, height: 8)
        )
        indicatorLayer.cornerRadius = 4

        indicatorLayer.position = CGPoint(x: layer.bounds.midX, y: layer.bounds.midY)
        indicatorLayer.backgroundColor = status.color.cgColor
        layer.addSublayer(indicatorLayer)
    }
}

extension OnlineIndicatorView: AppearanceSetting {
    public static func initialAppearanceSetup(_ view: OnlineIndicatorView) {
        view.defaultIntrinsicContentSize = .init(width: 14, height: 14)
    }
}
