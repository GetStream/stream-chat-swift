//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamChat
import StreamChatCommonUI
import StreamChatUI
import UIKit

/// The information about a channel member shown in the channel info screens.
struct DemoParticipantInfo {
    let chatUser: ChatUser
    let displayName: String
    let onlineInfoText: String
    let isDeactivated: Bool
    let isMuted: Bool

    var id: UserId { chatUser.id }

    var isAdminOrOwner: Bool {
        guard let member = chatUser as? ChatChannelMember else { return false }
        return member.memberRole == .admin || member.memberRole == .owner || member.memberRole == .moderator
    }

    static func make(
        for user: ChatUser,
        currentUserId: UserId?,
        mutedUserIds: Set<UserId>
    ) -> DemoParticipantInfo {
        DemoParticipantInfo(
            chatUser: user,
            displayName: user.id == currentUserId ? L10n.you : (user.name ?? user.id),
            onlineInfoText: onlineInfo(for: user),
            isDeactivated: user.isDeactivated,
            isMuted: mutedUserIds.contains(user.id)
        )
    }

    static func onlineInfo(for user: ChatUser) -> String {
        if user.isOnline {
            return L10n.Message.Title.online
        }
        if let lastActiveAt = user.lastActiveAt, let timeAgo = DateUtils.timeAgo(relativeTo: lastActiveAt) {
            return timeAgo
        }
        return L10n.Message.Title.offline
    }
}

// MARK: - Avatar

/// The channel avatar shown in the header of the channel info screen.
///
/// It loads the avatar in the size it is rendered, instead of the thumbnail size used in lists.
final class DemoChannelInfoAvatarView: ChatChannelAvatarView {
    static let size: CGFloat = 80

    override func loadIntoAvatarImageView(from url: URL?, placeholder: UIImage?) {
        components.mediaLoader.loadImage(
            into: presenceAvatarView.avatarView.imageView,
            from: url,
            with: ImageLoaderOptions(
                resize: ImageResize(CGSize(width: Self.size, height: Self.size)),
                placeholder: placeholder
            )
        )
    }
}

// MARK: - Header

/// The header of the channel info screen, showing the channel avatar, its name and a subtitle.
final class DemoChannelInfoHeaderView: UIView, ThemeProvider {
    struct Content {
        let channel: ChatChannel
        let currentUserId: UserId?
        let title: String
        let subtitle: String
    }

    var content: Content? {
        didSet { updateContent() }
    }

    private lazy var avatarView = DemoChannelInfoAvatarView()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = appearance.fonts.title3
        label.textColor = appearance.colorPalette.textPrimary
        label.textAlignment = .center
        label.numberOfLines = 2
        label.adjustsFontForContentSizeCategory = true
        return label
    }()

    private lazy var subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = appearance.fonts.footnote
        label.textColor = appearance.colorPalette.textSecondary
        label.textAlignment = .center
        label.adjustsFontForContentSizeCategory = true
        return label
    }()

    private lazy var avatarContainer: UIView = {
        let container = UIView()
        container.addSubview(avatarView)
        avatarView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            avatarView.topAnchor.constraint(equalTo: container.topAnchor),
            avatarView.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            avatarView.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            avatarView.widthAnchor.constraint(equalToConstant: DemoChannelInfoAvatarView.size),
            avatarView.heightAnchor.constraint(equalToConstant: DemoChannelInfoAvatarView.size)
        ])
        return container
    }()

    init() {
        super.init(frame: .zero)
        setUpLayout()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setUpLayout() {
        VContainer(spacing: appearance.tokens.spacingXs) {
            avatarContainer
            titleLabel
            subtitleLabel
        }.embed(
            in: self,
            insets: .init(
                top: appearance.tokens.spacingXl,
                leading: appearance.tokens.spacingMd,
                bottom: appearance.tokens.spacingXl,
                trailing: appearance.tokens.spacingMd
            )
        )
    }

    private func updateContent() {
        guard let content else { return }
        avatarView.content = (content.channel, content.currentUserId)
        titleLabel.text = content.title
        subtitleLabel.text = content.subtitle
    }
}

// MARK: - Item Cell

/// A row of the channel info screen showing an icon, a title and an optional accessory.
final class DemoChannelInfoItemCell: UITableViewCell, ThemeProvider {
    static let reuseIdentifier = String(describing: DemoChannelInfoItemCell.self)

    enum Accessory {
        case none
        case disclosure
        case toggle(isOn: Bool)
    }

    var onToggle: ((Bool) -> Void)?

    private lazy var iconView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = appearance.fonts.body
        label.adjustsFontForContentSizeCategory = true
        return label
    }()

    private lazy var disclosureView: UIImageView = {
        let imageView = UIImageView(image: appearance.images.chevronRight.withRenderingMode(.alwaysTemplate))
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = appearance.colorPalette.textSecondary
        return imageView
    }()

    private lazy var toggleView: UISwitch = {
        let toggle = UISwitch()
        toggle.addTarget(self, action: #selector(toggleValueChanged), for: .valueChanged)
        return toggle
    }()

    convenience init() {
        self.init(style: .default, reuseIdentifier: Self.reuseIdentifier)
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setUpLayout()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        onToggle = nil
    }

    func configure(icon: UIImage?, title: String, accessory: Accessory, isDestructive: Bool = false) {
        let tintColor = isDestructive ? appearance.colorPalette.accentError : appearance.colorPalette.textSecondary
        iconView.image = icon?.withRenderingMode(.alwaysTemplate)
        iconView.tintColor = tintColor
        titleLabel.text = title
        titleLabel.textColor = isDestructive ? appearance.colorPalette.accentError : appearance.colorPalette.textPrimary

        switch accessory {
        case .none:
            disclosureView.isHidden = true
            toggleView.isHidden = true
        case .disclosure:
            disclosureView.isHidden = false
            toggleView.isHidden = true
        case let .toggle(isOn):
            disclosureView.isHidden = true
            toggleView.isHidden = false
            toggleView.isOn = isOn
        }

        if case .toggle = accessory {
            selectionStyle = .none
        } else {
            selectionStyle = .default
        }
    }

    private func setUpLayout() {
        HContainer(spacing: appearance.tokens.spacingMd, alignment: .center) {
            iconView
                .width(appearance.tokens.spacingLg)
                .height(appearance.tokens.spacingLg)
            titleLabel
            Spacer()
            disclosureView
                .width(appearance.tokens.iconSizeSm)
            toggleView
        }.embed(
            in: contentView,
            insets: .init(
                top: appearance.tokens.spacingSm,
                leading: appearance.tokens.spacingMd,
                bottom: appearance.tokens.spacingSm,
                trailing: appearance.tokens.spacingMd
            )
        )
    }

    @objc private func toggleValueChanged() {
        onToggle?(toggleView.isOn)
    }
}

// MARK: - Member Cell

/// A row of the members section, showing the avatar, name and online status of a member.
final class DemoChannelInfoMemberCell: UITableViewCell, ThemeProvider {
    static let reuseIdentifier = String(describing: DemoChannelInfoMemberCell.self)

    private lazy var avatarView = components.userAvatarView.init()

    private lazy var nameLabel: UILabel = {
        let label = UILabel()
        label.font = appearance.fonts.bodyBold
        label.textColor = appearance.colorPalette.textPrimary
        label.adjustsFontForContentSizeCategory = true
        return label
    }()

    private lazy var onlineInfoLabel: UILabel = {
        let label = UILabel()
        label.font = appearance.fonts.footnote
        label.textColor = appearance.colorPalette.textSecondary
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

    private lazy var roleLabel: UILabel = {
        let label = UILabel()
        label.font = appearance.fonts.footnote
        label.textColor = appearance.colorPalette.textSecondary
        label.adjustsFontForContentSizeCategory = true
        return label
    }()

    convenience init() {
        self.init(style: .default, reuseIdentifier: Self.reuseIdentifier)
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setUpLayout()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with participant: DemoParticipantInfo) {
        avatarView.content = participant.chatUser
        nameLabel.text = participant.displayName
        onlineInfoLabel.text = participant.onlineInfoText
        mutedIconView.isHidden = !participant.isMuted
        roleLabel.isHidden = !participant.isAdminOrOwner
        roleLabel.text = participant.isAdminOrOwner ? "Admin" : nil
    }

    private func setUpLayout() {
        HContainer(spacing: appearance.tokens.spacingSm, alignment: .center) {
            avatarView
                .width(components.avatarThumbnailSize.width)
                .height(components.avatarThumbnailSize.height)
            VContainer(spacing: appearance.tokens.spacingXxxs) {
                nameLabel
                onlineInfoLabel
            }
            Spacer()
            mutedIconView
                .width(appearance.tokens.iconSizeSm)
                .height(appearance.tokens.iconSizeSm)
            roleLabel
        }.embed(
            in: contentView,
            insets: .init(
                top: appearance.tokens.spacingXs,
                leading: appearance.tokens.spacingMd,
                bottom: appearance.tokens.spacingXs,
                trailing: appearance.tokens.spacingMd
            )
        )
    }
}

// MARK: - Centered Button Cell

/// A row rendered as a centered button, used for the "View All" action of the members section.
final class DemoChannelInfoButtonCell: UITableViewCell, ThemeProvider {
    static let reuseIdentifier = String(describing: DemoChannelInfoButtonCell.self)

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = appearance.fonts.bodyBold
        label.textColor = appearance.colorPalette.buttonSecondaryText
        label.textAlignment = .center
        label.adjustsFontForContentSizeCategory = true
        return label
    }()

    convenience init() {
        self.init(style: .default, reuseIdentifier: Self.reuseIdentifier)
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setUpLayout()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(title: String) {
        titleLabel.text = title
    }

    private func setUpLayout() {
        HContainer(alignment: .center) {
            titleLabel
        }.embed(
            in: contentView,
            insets: .init(
                top: appearance.tokens.spacingSm,
                leading: appearance.tokens.spacingMd,
                bottom: appearance.tokens.spacingSm,
                trailing: appearance.tokens.spacingMd
            )
        )
    }
}

// MARK: - Members Section Header

/// The header of the members section, showing the member count and the button to add new members.
final class DemoChannelInfoMembersHeaderView: UITableViewHeaderFooterView, ThemeProvider {
    static let reuseIdentifier = String(describing: DemoChannelInfoMembersHeaderView.self)

    var onAddTapped: (() -> Void)?

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = appearance.fonts.headline
        label.textColor = appearance.colorPalette.textPrimary
        label.adjustsFontForContentSizeCategory = true
        return label
    }()

    private lazy var addButton: UIButton = {
        var titleAttributes = AttributeContainer()
        titleAttributes.font = appearance.fonts.bodyBold

        var configuration = UIButton.Configuration.plain()
        configuration.attributedTitle = AttributedString("Add", attributes: titleAttributes)
        configuration.baseForegroundColor = appearance.colorPalette.buttonSecondaryText
        configuration.contentInsets = .init(
            top: 0,
            leading: appearance.tokens.buttonPaddingXWithLabelXs,
            bottom: 0,
            trailing: appearance.tokens.buttonPaddingXWithLabelXs
        )

        let button = UIButton(type: .system)
        button.configuration = configuration
        button.layer.borderWidth = 1
        button.layer.borderColor = appearance.colorPalette.buttonSecondaryBorder.cgColor
        button.layer.cornerRadius = appearance.tokens.buttonVisualHeightXs / 2
        button.addTarget(self, action: #selector(addTapped), for: .touchUpInside)
        return button
    }()

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        setUpLayout()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        guard previousTraitCollection?.userInterfaceStyle != traitCollection.userInterfaceStyle else { return }
        addButton.layer.borderColor = appearance.colorPalette.buttonSecondaryBorder.cgColor
    }

    func configure(title: String, showsAddButton: Bool) {
        titleLabel.text = title
        addButton.isHidden = !showsAddButton
    }

    private func setUpLayout() {
        HContainer(spacing: appearance.tokens.spacingXs, alignment: .center) {
            titleLabel
            Spacer()
            addButton
                .height(appearance.tokens.buttonVisualHeightXs)
        }.embed(
            in: contentView,
            insets: .init(
                top: appearance.tokens.spacingXs,
                leading: appearance.tokens.spacingMd,
                bottom: appearance.tokens.spacingXxs,
                trailing: appearance.tokens.spacingMd
            )
        )
    }

    @objc private func addTapped() {
        onAddTapped?()
    }
}

// MARK: - Empty State

/// The placeholder shown by the channel info sub-screens when they have no content.
final class DemoChannelInfoEmptyStateView: UIView, ThemeProvider {
    private lazy var iconView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = appearance.colorPalette.textTertiary
        return imageView
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = appearance.fonts.bodyBold
        label.textColor = appearance.colorPalette.textPrimary
        label.textAlignment = .center
        label.adjustsFontForContentSizeCategory = true
        return label
    }()

    private lazy var subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = appearance.fonts.footnote
        label.textColor = appearance.colorPalette.textSecondary
        label.textAlignment = .center
        label.numberOfLines = 0
        label.adjustsFontForContentSizeCategory = true
        return label
    }()

    init(icon: UIImage?, title: String, subtitle: String) {
        super.init(frame: .zero)

        iconView.image = icon?.withRenderingMode(.alwaysTemplate)
        titleLabel.text = title
        subtitleLabel.text = subtitle
        setUpLayout()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setUpLayout() {
        let iconContainer = UIView()
        iconContainer.addSubview(iconView)
        iconView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            iconView.topAnchor.constraint(equalTo: iconContainer.topAnchor),
            iconView.bottomAnchor.constraint(equalTo: iconContainer.bottomAnchor),
            iconView.centerXAnchor.constraint(equalTo: iconContainer.centerXAnchor),
            iconView.widthAnchor.constraint(equalToConstant: appearance.tokens.iconSizeLg),
            iconView.heightAnchor.constraint(equalToConstant: appearance.tokens.iconSizeLg)
        ])

        let container = VContainer(spacing: appearance.tokens.spacingXs) {
            iconContainer
            titleLabel
            subtitleLabel
        }
        addSubview(container)
        NSLayoutConstraint.activate([
            container.centerYAnchor.constraint(equalTo: centerYAnchor),
            container.leadingAnchor.constraint(equalTo: leadingAnchor, constant: appearance.tokens.spacing2xl),
            container.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -appearance.tokens.spacing2xl)
        ])
    }
}
