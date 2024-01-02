//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// The cell that displays the message content of a dynamic type and layout.
/// Once the cell is set up it is expected to be dequeued for messages with
/// the same content and layout the cell has already been configured with.
public class ChatMessageCell: _TableViewCell, ThemeProvider {
    public static var reuseId: String { "\(self)" }

    /// The container that holds the header, footer and the message content view.
    internal lazy var containerStackView = UIStackView()
        .withoutAutoresizingMaskConstraints
        .withAccessibilityIdentifier(identifier: "containerStackView")

    /// The header View of the cell. It can be used to display additional information
    /// about the message above the message's content.
    internal lazy var headerContainerView: UIView = .init()
        .withoutAutoresizingMaskConstraints
        .withAccessibilityIdentifier(identifier: "headerContainerView")

    /// The message content view the cell is showing.
    public private(set) var messageContentView: ChatMessageContentView?

    /// The footer View of the cell. It can be used to display additional information
    /// about the message below the message's content.
    internal lazy var footerContainerView: UIView = .init()
        .withoutAutoresizingMaskConstraints
        .withAccessibilityIdentifier(identifier: "footerContainerView")

    /// The minimum spacing below the cell.
    public var minimumSpacingBelow: CGFloat = 2 {
        didSet { updateBottomSpacing() }
    }

    /// The spacing between the header, content and footer
    public var spacingBetween: CGFloat = 8 {
        didSet { updateSpacingBetween() }
    }

    override public func setUp() {
        super.setUp()
        selectionStyle = .none
    }

    override public func setUpLayout() {
        super.setUpLayout()

        containerStackView.axis = .vertical
        containerStackView.alignment = .center

        containerStackView.addArrangedSubview(headerContainerView)
        messageContentView.map { containerStackView.addArrangedSubview($0) }
        containerStackView.addArrangedSubview(footerContainerView)
        contentView.addSubview(containerStackView)

        containerStackView.pin(
            anchors: [.leading, .top, .trailing, .bottom],
            to: contentView
        )

        headerContainerView.pin(
            anchors: [.leading, .trailing],
            to: containerStackView
        )

        messageContentView?.pin(
            anchors: [.leading, .trailing],
            to: containerStackView
        )

        footerContainerView.pin(
            anchors: [.leading, .trailing],
            to: containerStackView
        )

        updateBottomSpacing()
    }

    override public func setUpAppearance() {
        super.setUpAppearance()

        backgroundColor = .clear
        backgroundView = nil

        headerContainerView.backgroundColor = nil
        footerContainerView.backgroundColor = nil
    }

    override public func prepareForReuse() {
        super.prepareForReuse()

        messageContentView?.prepareForReuse()

        headerContainerView.subviews.forEach { $0.removeFromSuperview() }
        footerContainerView.subviews.forEach { $0.removeFromSuperview() }

        headerContainerView.isHidden = true
        footerContainerView.isHidden = true
    }

    /// Sets a decoration surrounding the content view
    /// - Parameters:
    /// - decorationType: The type of the decoration to set. Currently supporting header and footer
    /// - decorationView: The view to use as decoration. If nil, the UI space will be released
    public func setDecoration(
        for decorationType: ChatMessageDecorationType,
        decorationView: ChatMessageDecorationView?
    ) {
        let container = decorationType == .header ? headerContainerView : footerContainerView

        container.subviews.forEach { $0.removeFromSuperview() }

        guard let decorationView = decorationView else {
            container.isHidden = true
            return
        }

        decorationView.translatesAutoresizingMaskIntoConstraints = false
        switch decorationType {
        case .header:
            container.embed(decorationView, insets: .init(top: 0, leading: 0, bottom: spacingBetween, trailing: 0))
            containerStackView.insertArrangedSubview(container, at: 0)
        case .footer:
            container.embed(decorationView, insets: .init(top: spacingBetween, leading: 0, bottom: 0, trailing: 0))
            containerStackView.addArrangedSubview(container)
        }

        container.isHidden = false
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

        // Instantiate message content view of the given type
        messageContentView = contentViewClass.init()
            .withoutAutoresizingMaskConstraints
            .withAccessibilityIdentifier(identifier: "messageContentView")
        messageContentView!.setUpLayoutIfNeeded(
            options: options,
            attachmentViewInjectorType: attachmentViewInjectorType
        )
    }

    private func updateBottomSpacing() {
        guard let contentView = messageContentView else { return }

        contentView.mainContainer.layoutMargins.bottom = max(
            contentView.mainContainer.layoutMargins.bottom,
            minimumSpacingBelow
        )
    }

    private func updateSpacingBetween() {
        if let headerDecorationView = headerContainerView.subviews.first as? ChatMessageDecorationView {
            setDecoration(for: .header, decorationView: headerDecorationView)
        }

        if let footerDecorationView = footerContainerView.subviews.first as? ChatMessageDecorationView {
            setDecoration(for: .footer, decorationView: footerDecorationView)
        }
    }
}
