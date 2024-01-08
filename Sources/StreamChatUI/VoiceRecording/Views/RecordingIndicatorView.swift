//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
import UIKit

/// A component that presents the active recording time during a recording flow.
open class RecordingIndicatorView: _View, ThemeProvider {
    public var content: TimeInterval = 0 {
        didSet { updateContentIfNeeded() }
    }

    // MARK: - UI Components

    /// The main container where all components will be added into.
    open private(set) lazy var container: UIStackView = .init()
        .withoutAutoresizingMaskConstraints

    /// The imageView that shows by default a mic image, to indicate to the user we are currently
    /// recording audio.
    open private(set) lazy var recordingIndicator: UIImageView = .init()
        .withoutAutoresizingMaskConstraints

    /// The label that shows the duration of the active recording.
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
