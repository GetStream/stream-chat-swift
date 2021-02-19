//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

internal typealias СhatMessageCollectionViewCell = _СhatMessageCollectionViewCell<NoExtraData>

internal class _СhatMessageCollectionViewCell<ExtraData: ExtraDataTypes>: _CollectionViewCell, UIConfigProvider {
    // MARK: - Reuse identifiers

    class var reuseId: String { String(describing: self) + String(describing: Self.messageContentViewClass) }
    
    internal static var incomingMessage2ReuseId: String { "incoming_2_\(reuseId)" }
    internal static var incomingMessage3ReuseId: String { "incoming_3_\(reuseId)" }
    internal static var incomingMessage6ReuseId: String { "incoming_6_\(reuseId)" }
    internal static var incomingMessage7ReuseId: String { "incoming_7_\(reuseId)" }
    internal static var incomingMessage1ReuseId: String { "incoming_1_\(reuseId)" }
    internal static var incomingMessage4ReuseId: String { "incoming_4_\(reuseId)" }
    internal static var incomingMessage9ReuseId: String { "incoming_9_\(reuseId)" }
    internal static var incomingMessage5ReuseId: String { "incoming_5_\(reuseId)" }
    internal static var incomingMessage13ReuseId: String { "incoming_13_\(reuseId)" }
    
    internal static var outgoingMessage2ReuseId: String { "outgoing_2_\(reuseId)" }
    internal static var outgoingMessage3ReuseId: String { "outgoing_3_\(reuseId)" }
    internal static var outgoingMessage6ReuseId: String { "outgoing_6_\(reuseId)" }
    internal static var outgoingMessage7ReuseId: String { "outgoing_7_\(reuseId)" }
    internal static var outgoingMessage1ReuseId: String { "outgoing_1_\(reuseId)" }
    internal static var outgoingMessage4ReuseId: String { "outgoing_4_\(reuseId)" }
    internal static var outgoingMessage9ReuseId: String { "outgoing_9_\(reuseId)" }
    internal static var outgoingMessage5ReuseId: String { "outgoing_5_\(reuseId)" }
    internal static var outgoingMessage13ReuseId: String { "outgoing_13_\(reuseId)" }
    
    // MARK: - Properties

    internal var message: _ChatMessageGroupPart<ExtraData>? {
        didSet { updateContentIfNeeded() }
    }

    // MARK: - Subviews

    internal class var messageContentViewClass: _ChatMessageContentView<ExtraData>.Type { _ChatMessageContentView<ExtraData>.self }

    internal private(set) lazy var messageView: _ChatMessageContentView<ExtraData> = Self.messageContentViewClass.init()
        .withoutAutoresizingMaskConstraints
    
    private var messageViewLeadingConstraint: NSLayoutConstraint?
    private var messageViewTrailingConstraint: NSLayoutConstraint?

    private var hasCompletedStreamSetup = false

    // MARK: - Lifecycle

    override internal func setUpLayout() {
        contentView.addSubview(messageView)

        NSLayoutConstraint.activate([
            messageView.topAnchor.pin(equalTo: contentView.topAnchor),
            messageView.bottomAnchor.pin(equalTo: contentView.bottomAnchor),
            messageView.widthAnchor.pin(lessThanOrEqualTo: contentView.widthAnchor, multiplier: 0.75)
        ])
    }

    override internal func updateContent() {
        messageView.message = message

        switch message?.isSentByCurrentUser {
        case true?:
            assert(messageViewLeadingConstraint == nil, "The cell was already used for incoming message")
            if messageViewTrailingConstraint == nil {
                messageViewTrailingConstraint = messageView.trailingAnchor
                    .pin(equalTo: contentView.layoutMarginsGuide.trailingAnchor)
                messageViewTrailingConstraint!.isActive = true
            }

        case false?:
            assert(messageViewTrailingConstraint == nil, "The cell was already used for outgoing message")
            if messageViewLeadingConstraint == nil {
                messageViewLeadingConstraint = messageView.leadingAnchor
                    .pin(equalTo: contentView.layoutMarginsGuide.leadingAnchor)
                messageViewLeadingConstraint!.isActive = true
            }

        case nil:
            break
        }
    }

    // MARK: - Overrides

    override internal func prepareForReuse() {
        super.prepareForReuse()

        message = nil
    }

    override internal func preferredLayoutAttributesFitting(
        _ layoutAttributes: UICollectionViewLayoutAttributes
    ) -> UICollectionViewLayoutAttributes {
        let preferredAttributes = super.preferredLayoutAttributesFitting(layoutAttributes)

        let targetSize = CGSize(
            width: layoutAttributes.frame.width,
            height: UIView.layoutFittingCompressedSize.height
        )

        preferredAttributes.frame.size = contentView.systemLayoutSizeFitting(
            targetSize,
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        )

        return preferredAttributes
    }
}
