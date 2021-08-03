//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// The cell that displays the message content of a dynamic type and layout.
/// Once the cell is set up it is expected to be dequeued for messages with
/// the same content and layout the cell has already been configured with.
public final class ChatMessageCell: _TableViewCell {
    public static var reuseId: String { "\(self)" }
    
    /// The message content view the cell is showing.
    public private(set) var messageContentView: ChatMessageContentView?
    
    /// The minimum spacing below the cell.
    public var minimumSpacingBelow: CGFloat = 2 {
        didSet { updateBottomSpacing() }
    }
    
    override public func setUp() {
        super.setUp()
        
        selectionStyle = .none
    }
    
    override public func setUpAppearance() {
        super.setUpAppearance()
        
        backgroundColor = .clear
        backgroundView = nil
    }

    override public func prepareForReuse() {
        super.prepareForReuse()

        messageContentView?.prepareForReuse()
    }

    /// Creates a message content view
    /// - Parameters:
    ///   - contentViewClass: The type of message content view.
    ///   - attachmentViewInjectorType: The type of attachment injector.
    ///   - options: The layout options describing the message content view layout.
    public func setMessageContentIfNeeded(
        contentViewClass: ChatMessageContentView.Type,
        attachmentViewInjectorType: AttachmentViewInjector.Type?,
        options: ChatMessageLayoutOptions
    ) {
        guard messageContentView == nil else {
            log.assert(type(of: messageContentView!) == contentViewClass, """
            Attempt to setup different content class: ("\(contentViewClass)")
            """)
            return
        }

        messageContentView = contentViewClass.init().withoutAutoresizingMaskConstraints
        // We add the content view to the view hierarchy before invoking `setUpLayoutIfNeeded`
        // (where the subviews are instantiated and configured) to use `components` and `appearance`
        // taken from the responder chain.
        contentView.addSubview(messageContentView!)
        messageContentView!.pin(anchors: [.leading, .top, .trailing, .bottom], to: contentView)
        messageContentView!.setUpLayoutIfNeeded(options: options, attachmentViewInjectorType: attachmentViewInjectorType)
        updateBottomSpacing()
    }
    
    private func updateBottomSpacing() {
        guard let contentView = messageContentView else { return }
        
        contentView.mainContainer.layoutMargins.bottom = max(
            contentView.mainContainer.layoutMargins.bottom,
            minimumSpacingBelow
        )
    }
}
