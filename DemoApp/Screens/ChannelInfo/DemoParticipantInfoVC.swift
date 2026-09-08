//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamChatUI
import UIKit

/// An action that can be performed on a channel member from the channel info screen.
struct DemoParticipantAction {
    struct Confirmation {
        let title: String
        let message: String
        let buttonTitle: String
    }

    let title: String
    /// The name of the SF Symbol shown next to the title.
    let iconName: String
    var isDestructive: Bool = false
    var confirmation: Confirmation?
    let action: () -> Void
}

/// The bottom sheet showing a channel member and the actions available for it.
///
/// It is the UIKit counterpart of the `ParticipantInfoView` from the SwiftUI SDK.
final class DemoParticipantInfoVC: UIViewController, ThemeProvider {
    /// The height the sheet uses until its content has been laid out.
    private static let estimatedContentHeight: CGFloat = 280
    private static let avatarSize: CGFloat = 48

    private let participant: DemoParticipantInfo
    private let actions: [DemoParticipantAction]

    private var contentHeight = DemoParticipantInfoVC.estimatedContentHeight

    private lazy var avatarView = components.userAvatarView.init()

    private lazy var nameLabel: UILabel = {
        let label = UILabel()
        label.font = appearance.fonts.title3
        label.textColor = appearance.colorPalette.textPrimary
        label.adjustsFontForContentSizeCategory = true
        return label
    }()

    private lazy var mutedIconView: UIImageView = {
        let imageView = UIImageView(image: appearance.images.muted.withRenderingMode(.alwaysTemplate))
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = appearance.colorPalette.textTertiary
        imageView.accessibilityLabel = "Muted"
        return imageView
    }()

    private lazy var onlineInfoLabel: UILabel = {
        let label = UILabel()
        label.font = appearance.fonts.footnote
        label.textColor = appearance.colorPalette.textSecondary
        label.adjustsFontForContentSizeCategory = true
        return label
    }()

    private lazy var contentContainer: UIStackView = {
        let container = VContainer(spacing: 0)
        container.addArrangedSubview(headerView)
        actions.forEach { action in
            container.addArrangedSubview(
                DemoParticipantActionRow(action: action) { [weak self] action in
                    self?.perform(action)
                }
            )
        }
        return container
    }()

    private lazy var headerView: UIView = {
        HContainer(spacing: appearance.tokens.spacingMd, alignment: .center) {
            avatarView
                .width(Self.avatarSize)
                .height(Self.avatarSize)
            VContainer(spacing: appearance.tokens.spacingXxxs) {
                HContainer(spacing: appearance.tokens.spacingXs, alignment: .center) {
                    nameLabel
                    mutedIconView
                        .width(appearance.tokens.iconSizeSm)
                        .height(appearance.tokens.iconSizeSm)
                    Spacer()
                }
                onlineInfoLabel
            }
            Spacer()
        }.padding(appearance.tokens.spacingMd)
    }()

    init(participant: DemoParticipantInfo, actions: [DemoParticipantAction]) {
        self.participant = participant
        self.actions = actions
        super.init(nibName: nil, bundle: nil)

        modalPresentationStyle = .pageSheet
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = appearance.colorPalette.backgroundCoreSurfaceCard
        view.addSubview(contentContainer)
        NSLayoutConstraint.activate([
            contentContainer.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            contentContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            contentContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])

        avatarView.content = participant.chatUser
        nameLabel.text = participant.displayName
        onlineInfoLabel.text = participant.onlineInfoText
        mutedIconView.isHidden = !participant.isMuted

        setUpSheet()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        let fittingHeight = contentContainer.systemLayoutSizeFitting(
            CGSize(width: view.bounds.width, height: UIView.layoutFittingCompressedSize.height),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        ).height + view.safeAreaInsets.top + view.safeAreaInsets.bottom

        guard abs(fittingHeight - contentHeight) > 1 else { return }
        contentHeight = fittingHeight

        if #available(iOS 16.0, *) {
            sheetPresentationController?.invalidateDetents()
        }
    }

    private func setUpSheet() {
        guard let sheet = sheetPresentationController else { return }

        sheet.prefersGrabberVisible = true
        sheet.preferredCornerRadius = appearance.tokens.radius2xl
        if #available(iOS 16.0, *) {
            sheet.detents = [
                .custom(identifier: .init("participantInfo")) { [weak self] context in
                    min(self?.contentHeight ?? Self.estimatedContentHeight, context.maximumDetentValue)
                },
                .medium()
            ]
        } else {
            sheet.detents = [.medium()]
        }
    }

    // MARK: - Actions

    private func perform(_ action: DemoParticipantAction) {
        guard let confirmation = action.confirmation else {
            dismiss(animated: true) { action.action() }
            return
        }

        presentAlert(
            title: confirmation.title,
            message: confirmation.message,
            actions: [
                .init(title: confirmation.buttonTitle, style: .destructive, handler: { [weak self] _ in
                    self?.dismiss(animated: true) { action.action() }
                })
            ]
        )
    }
}

/// A single action row of the participant info sheet.
private final class DemoParticipantActionRow: UIControl, ThemeProvider {
    private let action: DemoParticipantAction
    private let onTap: (DemoParticipantAction) -> Void

    override var isHighlighted: Bool {
        didSet {
            backgroundColor = isHighlighted ? appearance.colorPalette.backgroundCoreSurfaceSubtle : .clear
        }
    }

    private lazy var iconView: UIImageView = {
        let imageView = UIImageView(image: UIImage(systemName: action.iconName))
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = action.isDestructive
            ? appearance.colorPalette.accentError
            : appearance.colorPalette.textSecondary
        return imageView
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = action.title
        label.font = appearance.fonts.body
        label.textColor = action.isDestructive
            ? appearance.colorPalette.accentError
            : appearance.colorPalette.textPrimary
        label.adjustsFontForContentSizeCategory = true
        return label
    }()

    init(action: DemoParticipantAction, onTap: @escaping (DemoParticipantAction) -> Void) {
        self.action = action
        self.onTap = onTap
        super.init(frame: .zero)

        accessibilityLabel = action.title
        accessibilityTraits = .button
        addTarget(self, action: #selector(tapped), for: .touchUpInside)
        setUpLayout()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setUpLayout() {
        HContainer(spacing: appearance.tokens.spacingMd, alignment: .center) {
            iconView
                .width(appearance.tokens.spacingLg)
                .height(appearance.tokens.spacingLg)
            titleLabel
            Spacer()
        }
        .padding(appearance.tokens.spacingMd)
        .embed(in: self)
        // The stack must not swallow the touches the row itself handles.
        subviews.forEach { $0.isUserInteractionEnabled = false }
    }

    @objc private func tapped() {
        onTap(action)
    }
}
