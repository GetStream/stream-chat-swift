//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// A view controller which shows the progress of compressing the videos
/// that were selected in the composer's media picker.
open class VideoCompressionProgressVC: _ViewController, ThemeProvider {
    /// The content of the view controller.
    public struct Content: Equatable {
        /// The progress of preparing all the selected videos, a value between 0 and 1.
        public var progress: Double

        public init(progress: Double = 0) {
            self.progress = progress
        }
    }

    /// The content of the view controller.
    public var content = Content() {
        didSet {
            guard content != oldValue else { return }
            updateContentIfNeeded()
        }
    }

    /// Called when the user cancels the compression.
    public var onCancel: (() -> Void)?

    // MARK: - Subviews

    /// The view which dims the content behind the view controller.
    open private(set) lazy var overlayView = UIView()
        .withoutAutoresizingMaskConstraints

    /// The card which holds the title, the progress bar and the cancel button.
    open private(set) lazy var containerView = ContainerStackView(axis: .vertical)
        .withoutAutoresizingMaskConstraints

    /// The label which describes what is currently being compressed.
    open private(set) lazy var titleLabel = UILabel()
        .withoutAutoresizingMaskConstraints
        .withAdjustingFontForContentSizeCategory
        .withBidirectionalLanguagesSupport

    /// The bar which shows the progress of the compression.
    open private(set) lazy var progressView = UIProgressView(progressViewStyle: .default)
        .withoutAutoresizingMaskConstraints

    /// The button which cancels the compression.
    open private(set) lazy var cancelButton = UIButton(type: .system)
        .withoutAutoresizingMaskConstraints

    // MARK: - Life Cycle

    override open func setUp() {
        super.setUp()

        cancelButton.addTarget(self, action: #selector(cancelButtonTapped(sender:)), for: .touchUpInside)
        cancelButton.setTitle(L10n.Alert.Actions.cancel, for: .normal)
        cancelButton.accessibilityIdentifier = "cancelButton"

        titleLabel.text = L10n.Composer.VideoCompression.preparing
        titleLabel.numberOfLines = 0
        titleLabel.textAlignment = .center
        titleLabel.accessibilityIdentifier = "titleLabel"

        progressView.accessibilityLabel = L10n.Composer.VideoCompression.preparing
        progressView.accessibilityIdentifier = "progressView"

        view.accessibilityViewIsModal = true
    }

    override open func setUpLayout() {
        super.setUpLayout()

        view.embed(overlayView)

        containerView.isLayoutMarginsRelativeArrangement = true
        containerView.directionalLayoutMargins = .init(top: 20, leading: 20, bottom: 12, trailing: 20)
        containerView.spacing = 16
        containerView.addArrangedSubviews([titleLabel, progressView, cancelButton])

        view.addSubview(containerView)
        NSLayoutConstraint.activate([
            containerView.centerXAnchor.pin(equalTo: view.centerXAnchor),
            containerView.centerYAnchor.pin(equalTo: view.centerYAnchor),
            containerView.widthAnchor.pin(equalToConstant: 280).with(priority: .streamRequire),
            containerView.leadingAnchor.pin(greaterThanOrEqualTo: view.leadingAnchor, constant: 32),
            containerView.trailingAnchor.pin(lessThanOrEqualTo: view.trailingAnchor, constant: -32),
            progressView.heightAnchor.pin(equalToConstant: 4)
        ])
    }

    override open func setUpAppearance() {
        super.setUpAppearance()

        view.backgroundColor = .clear
        overlayView.backgroundColor = appearance.colorPalette.backgroundCoreScrim

        containerView.backgroundColor = appearance.colorPalette.backgroundCoreElevation2
        containerView.layer.cornerRadius = 16
        containerView.clipsToBounds = true

        titleLabel.font = appearance.fonts.bodyBold
        titleLabel.textColor = appearance.colorPalette.textPrimary

        progressView.progressTintColor = appearance.colorPalette.accentPrimary
        progressView.trackTintColor = appearance.colorPalette.borderCoreDefault

        cancelButton.setTitleColor(appearance.colorPalette.accentPrimary, for: .normal)
        cancelButton.titleLabel?.font = appearance.fonts.bodyBold
    }

    override open func updateContent() {
        super.updateContent()

        progressView.setProgress(Float(content.progress), animated: content.progress > 0)
    }

    // MARK: - Actions

    @objc open func cancelButtonTapped(sender: UIButton) {
        onCancel?()
    }
}
