//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import StreamChat
import StreamChatUI
import UIKit

class LocationSharingStatusView: _View, ThemeProvider {
    private lazy var statusLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = appearance.fonts.footnote
        label.textColor = appearance.colorPalette.subtitleText
        return label
    }()

    private var activeSharingImage: UIImage? = UIImage(
        systemName: "location.fill",
        withConfiguration: UIImage.SymbolConfiguration(scale: .medium)
    )

    private var inactiveSharingImage: UIImage? = UIImage(
        systemName: "location.slash.fill",
        withConfiguration: UIImage.SymbolConfiguration(scale: .medium)
    )

    private lazy var iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.image = activeSharingImage
        return imageView
    }()
    
    override func setUpLayout() {
        super.setUpLayout()
        
        HContainer(spacing: 4, alignment: .center) {
            iconImageView
                .width(16)
                .height(16)
            statusLabel
        }.embed(in: self)
    }

    func updateStatus(location: SharedLocation) {
        guard let endAt = location.endAt else { return }
        let endAtText = appearance.formatters.channelListMessageTimestamp.format(endAt)
        statusLabel.text = location.isLiveSharingActive ? "Live until \(endAtText)" : "Live location ended"
        iconImageView.image = location.isLiveSharingActive ? activeSharingImage : inactiveSharingImage
        iconImageView.tintColor = location.isLiveSharingActive
            ? appearance.colorPalette.accentPrimary
            : appearance.colorPalette.subtitleText
    }
}
