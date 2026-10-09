//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamChatUI
import UIKit

final class DemoToastView: UIView {
    private let label = UILabel()

    static func show(_ text: String, in view: UIView) {
        let container = view.window ?? view
        let toast = DemoToastView(text: text)
        toast.alpha = 0
        container.addSubview(toast)
        NSLayoutConstraint.activate([
            toast.topAnchor.constraint(equalTo: container.safeAreaLayoutGuide.topAnchor, constant: 8),
            toast.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            toast.leadingAnchor.constraint(greaterThanOrEqualTo: container.leadingAnchor, constant: 16)
        ])
        UIAccessibility.post(notification: .announcement, argument: text)

        UIView.animate(withDuration: 0.25) {
            toast.alpha = 1
        } completion: { _ in
            UIView.animate(withDuration: 0.25, delay: 2.5) {
                toast.alpha = 0
            } completion: { _ in
                toast.removeFromSuperview()
            }
        }
    }

    private init(text: String) {
        super.init(frame: .zero)

        let colors = Appearance.default.colorPalette
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = colors.textPrimary
        layer.cornerRadius = 18
        isUserInteractionEnabled = false

        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = text
        label.textColor = colors.backgroundCoreApp
        label.font = .preferredFont(forTextStyle: .subheadline)
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 0
        label.textAlignment = .center
        addSubview(label)
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            label.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8),
            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16)
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
