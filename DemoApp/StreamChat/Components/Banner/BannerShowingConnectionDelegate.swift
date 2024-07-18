//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

final class BannerShowingConnectionDelegate {
    // MARK: - Private Properties

    private let view: UIView
    private let bannerView = DemoConnectionBannerView()
    private let bannerAppearanceDuration: TimeInterval = 0.5

    // MARK: -

    init(showUnder view: UIView) {
        self.view = view
        setupViews()
    }
}

// MARK: - ChatConnectionControllerDelegate

extension BannerShowingConnectionDelegate: ChatConnectionControllerDelegate {
    public func connectionController(_ controller: ChatConnectionController, didUpdateConnectionStatus status: ConnectionStatus) {
        switch status {
        case .disconnected:
            bannerView.update(text: "Disconnected")
            showBanner()
        case .connected:
            bannerView.update(text: "Connected")
            hideBanner()
        case .disconnecting:
            bannerView.update(text: "Disconnecting...")
            showBanner()
        case .connecting:
            bannerView.update(text: "Connecting...")
            showBanner()
        case .initialized:
            break
        }
    }
}

// MARK: - Private Methods

private extension BannerShowingConnectionDelegate {
    func setupViews() {
        attachToTopViewIfNeeded()
        bannerView.alpha = 1
        bannerView.update(text: "Connecting...")
    }

    func attachToTopViewIfNeeded() {
        guard bannerView.superview != view else { return }

        view.addSubview(bannerView)

        bannerView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate(
            [
                bannerView.topAnchor.constraint(equalTo: view.bottomAnchor),
                bannerView.widthAnchor.constraint(equalTo: view.widthAnchor),
                bannerView.heightAnchor.constraint(equalToConstant: 28)
            ]
        )
    }

    func showBanner() {
        attachToTopViewIfNeeded()
        animateBannerAlpha(to: 1)
    }

    func hideBanner() {
        animateBannerAlpha(to: 0)
    }

    func animateBannerAlpha(to value: CGFloat) {
        UIView.animate(withDuration: bannerAppearanceDuration) {
            self.bannerView.alpha = value
        }
    }
}
