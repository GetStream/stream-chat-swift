//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation
import UIKit

/// A component that presents the active recording time during a recording flow.
open class RecordingIndicatorView: _View, ThemeProvider {
    public var content: TimeInterval = 0 {
        didSet { updateContentIfNeeded() }
    }

    // MARK: - UI Components

    open private(set) lazy var container: UIStackView = .init()
        .withoutAutoresizingMaskConstraints

    open private(set) lazy var recordingIndicator: UIImageView = .init()
        .withoutAutoresizingMaskConstraints

    open private(set) lazy var durationLabel: UILabel = UILabel()
        .withBidirectionalLanguagesSupport
        .withoutAutoresizingMaskConstraints

    // MARK: - Lifecycle

    override open func setUpLayout() {
        super.setUpLayout()
        recordingIndicator.pin(anchors: [.width], to: 35)
        recordingIndicator.pin(anchors: [.height], to: 40)

        container.axis = .horizontal
        container.spacing = 5
        container.addArrangedSubview(recordingIndicator)
        container.addArrangedSubview(durationLabel)

        embed(container, insets: .zero)
    }

    override open func setUpAppearance() {
        super.setUpAppearance()
        recordingIndicator.contentMode = .center
        recordingIndicator.image = appearance.images.mic.tinted(with: appearance.colorPalette.alert)
        durationLabel.textColor = appearance.colorPalette.textLowEmphasis
        durationLabel.font = .monospacedDigitSystemFont(ofSize: appearance.fonts.footnote.pointSize, weight: .medium)
    }

    override open func updateContent() {
        durationLabel.text = appearance.formatters.videoDuration.format(content)
    }
}
