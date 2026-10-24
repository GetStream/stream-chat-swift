//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamChatUI
import UIKit

final class DemoComposerBannerView: UIView {
    var onTap: (() -> Void)? {
        didSet { updateAccessibility() }
    }

    var onDismiss: (() -> Void)? {
        didSet { dismissButton.isHidden = onDismiss == nil }
    }

    var title: String? {
        get { titleLabel.text }
        set {
            titleLabel.text = newValue
            updateAccessibility()
        }
    }

    private let iconView = UIImageView(image: UIImage(systemName: "clock"))
    private let titleLabel = UILabel()
    private let dismissButton = UIButton(type: .system)

    override init(frame: CGRect) {
        super.init(frame: frame)

        let colors = Appearance.default.colorPalette
        backgroundColor = colors.backgroundCoreSurfaceStrong
        layer.cornerRadius = 12

        iconView.tintColor = colors.accentPrimary
        iconView.contentMode = .scaleAspectFit
        iconView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(textStyle: .footnote)
        iconView.setContentHuggingPriority(.required, for: .horizontal)

        titleLabel.font = .preferredFont(forTextStyle: .footnote)
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.textColor = colors.textPrimary
        titleLabel.numberOfLines = 0

        dismissButton.setImage(UIImage(systemName: "xmark"), for: .normal)
        dismissButton.tintColor = colors.textSecondary
        dismissButton.accessibilityLabel = "Cancel"
        dismissButton.isHidden = true
        dismissButton.setContentHuggingPriority(.required, for: .horizontal)
        dismissButton.addTarget(self, action: #selector(dismissTapped), for: .touchUpInside)

        let stackView = UIStackView(arrangedSubviews: [iconView, titleLabel, dismissButton])
        stackView.spacing = 8
        stackView.alignment = .center
        stackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12)
        ])

        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapped)))
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func tapped() {
        onTap?()
    }

    @objc private func dismissTapped() {
        onDismiss?()
    }

    private func updateAccessibility() {
        // A tappable banner reads as a single button; otherwise the dismiss button stays reachable.
        isAccessibilityElement = onTap != nil
        accessibilityLabel = titleLabel.text
        accessibilityTraits = onTap != nil ? .button : .none
    }
}
