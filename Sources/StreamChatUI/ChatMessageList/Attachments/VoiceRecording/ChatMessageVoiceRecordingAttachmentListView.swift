//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// View which holds one or more voice recording attachment views in a message or composer attachment view
open class ChatMessageVoiceRecordingAttachmentListView: _View, ComponentsProvider {
    /// Content of the attachment list - Array of `ChatMessageVoiceRecordingAttachment`
    open var content: [ChatMessageVoiceRecordingAttachment] = [] {
        didSet { updateContentIfNeeded() }
    }

    // MARK: - UI Components

    /// Container which holds one or multiple attachment views in self.
    open private(set) lazy var containerStackView: UIStackView = .init()
        .withoutAutoresizingMaskConstraints
        .withAccessibilityIdentifier(identifier: "containerStackView")

    // MARK: - Configuration properties

    /// Closure what should happen on tapping the given attachment.
    open weak var playbackDelegate: VoiceRecordingAttachmentPresentationViewDelegate?

    // MARK: - Lifecycle

    override open func setUpLayout() {
        directionalLayoutMargins = .init(top: 4, leading: 4, bottom: 4, trailing: 4)
        addSubview(containerStackView)
        containerStackView.pin(to: layoutMarginsGuide)

        containerStackView.axis = .vertical
        containerStackView.spacing = 4
    }

    override open func updateContent() {
        containerStackView.subviews.forEach { $0.removeFromSuperview() }

        content.enumerated().forEach { index, attachment in
            let item = components.voiceRecordingAttachmentView.init()
            item.presenter.delegate = playbackDelegate
            item.content = attachment
            item.indexProvider = { index }
            containerStackView.addArrangedSubview(item)
        }
    }
}
