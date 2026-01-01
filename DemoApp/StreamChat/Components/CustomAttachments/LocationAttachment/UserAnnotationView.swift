//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import MapKit
import StreamChat
import StreamChatUI

class UserAnnotationView: MKAnnotationView {
    static let reuseIdentifier = "UserAnnotationView"

    private lazy var avatarView: ChatUserAvatarView = {
        let view = ChatUserAvatarView()
        view.shouldShowOnlineIndicator = false
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.masksToBounds = true
        return view
    }()

    private var size: CGSize = .init(width: 40, height: 40)

    private var pulseLayer: CALayer?

    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        backgroundColor = .gray
        frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        layer.cornerRadius = 20
        layer.masksToBounds = false
        layer.borderWidth = 2
        layer.borderColor = UIColor.white.cgColor
        addSubview(avatarView)
        avatarView.width(size.width)
        avatarView.height(size.height)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) not implemented")
    }

    func setUser(_ user: ChatUser) {
        avatarView.content = user
    }

    func startPulsingAnimation() {
        guard pulseLayer == nil else {
            return
        }
        let pulseLayer = CALayer()
        pulseLayer.masksToBounds = false
        pulseLayer.frame = bounds
        pulseLayer.cornerRadius = bounds.width / 2
        pulseLayer.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.5).cgColor
        layer.insertSublayer(pulseLayer, below: avatarView.layer)

        let animationScale = CABasicAnimation(keyPath: "transform.scale")
        animationScale.fromValue = 1.0
        animationScale.toValue = 1.5
        animationScale.duration = 2.0
        animationScale.timingFunction = CAMediaTimingFunction(name: .easeOut)
        animationScale.autoreverses = false
        animationScale.repeatCount = .infinity

        let animationOpacity = CABasicAnimation(keyPath: "opacity")
        animationOpacity.fromValue = 1.0
        animationOpacity.toValue = 0
        animationOpacity.duration = 2.0
        animationOpacity.timingFunction = CAMediaTimingFunction(name: .easeOut)
        animationOpacity.autoreverses = false
        animationOpacity.repeatCount = .infinity

        pulseLayer.add(animationScale, forKey: "pulseScale")
        pulseLayer.add(animationOpacity, forKey: "pulseOpacity")
        self.pulseLayer = pulseLayer
    }

    func stopPulsingAnimation() {
        pulseLayer?.removeFromSuperlayer()
        pulseLayer = nil
    }
}
