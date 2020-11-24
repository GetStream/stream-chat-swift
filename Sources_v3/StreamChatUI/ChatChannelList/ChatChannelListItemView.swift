//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

open class ChatChannelListItemView<ExtraData: UIExtraDataTypes>: UIView, AppearanceSetting {
    // MARK: - Default Appearance
    
    public class func initialAppearanceSetup(_ view: ChatChannelListItemView<ExtraData>) {
        if #available(iOS 13, *) {
            view.backgroundColor = .systemBackground
        } else {
            view.backgroundColor = .white // Should be add custom support for dark theme?
        }
    }
    
    // MARK: - Properties
    
    public let uiConfig: UIConfig<ExtraData>
    
    public var channel: _ChatChannel<ExtraData>? {
        didSet {
            updateContent()
        }
    }

    public var currentUserId: UserId?
    
    // MARK: - Subviews
    
    private lazy var uiConfigSubviews = uiConfig.channelList.channelListItemSubviews
    
    public private(set) lazy var container = ContainerStackView().withoutAutoresizingMaskConstraints
    
    public private(set) lazy var avatarView: ChatChannelAvatarView<ExtraData> = {
        uiConfigSubviews.avatarView.init().withoutAutoresizingMaskConstraints
    }()
    
    public private(set) lazy var titleLabel = UILabel().withoutAutoresizingMaskConstraints
    
    public private(set) lazy var subtitleLabel = UILabel().withoutAutoresizingMaskConstraints
    
    public private(set) lazy var unreadCountView: ChatUnreadCountView = {
        uiConfigSubviews.unreadCountView.init().withoutAutoresizingMaskConstraints
    }()
    
    public private(set) lazy var readStatusView: ChatReadStatusCheckmarkView = {
        uiConfigSubviews.readStatusView.init().withoutAutoresizingMaskConstraints
    }()
    
    public private(set) lazy var timestampLabel = UILabel().withoutAutoresizingMaskConstraints
    
    // MARK: - Init
    
    public required init(
        channel: _ChatChannel<ExtraData>? = nil,
        currentUserId: UserId? = nil,
        uiConfig: UIConfig<ExtraData> = .default
    ) {
        self.channel = channel
        self.uiConfig = uiConfig
        self.currentUserId = currentUserId
        
        super.init(frame: .zero)
        
        commonInit()
    }
    
    public required init?(coder: NSCoder) {
        uiConfig = .default
        channel = nil
        currentUserId = nil
        
        super.init(coder: coder)
        
        commonInit()
    }
    
    public func commonInit() {
        embed(container)
        
        applyDefaultAppearance()
        setupAppearance()
        setupLayout()
        updateContent()
    }
    
    // MARK: - Public
    
    open func setupAppearance() {
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.font = .preferredFont(forTextStyle: .headline)
        
        subtitleLabel.textColor = .systemGray
        subtitleLabel.adjustsFontForContentSizeCategory = true
        subtitleLabel.font = .preferredFont(forTextStyle: .subheadline)
        
        timestampLabel.textColor = .systemGray
        timestampLabel.adjustsFontForContentSizeCategory = true
        timestampLabel.font = .preferredFont(forTextStyle: .subheadline)
    }
    
    open func setupLayout() {
        container.preservesSuperviewLayoutMargins = true
        container.isLayoutMarginsRelativeArrangement = true
                
        container.leftStackView.isHidden = false
        container.leftStackView.alignment = .center
        container.leftStackView.isLayoutMarginsRelativeArrangement = true
        container.leftStackView.directionalLayoutMargins = .init(
            top: 0,
            leading: 0,
            bottom: 0,
            trailing: avatarView.directionalLayoutMargins.trailing
        )
        
        container.leftStackView.addArrangedSubview(avatarView)
        
        // UIStackView embedded in UIView with flexible top and bottom constraints to make
        // containing UIStackView centred and preserving content size.
        let containerCenterView = UIView()
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = UIStackView.spacingUseSystem
        
        containerCenterView.addSubview(stackView)
        stackView.topAnchor.constraint(greaterThanOrEqualTo: containerCenterView.topAnchor, constant: 0).isActive = true
        stackView.bottomAnchor.constraint(lessThanOrEqualTo: containerCenterView.bottomAnchor, constant: 0).isActive = true
        stackView.pin(anchors: [.leading, .trailing, .centerY], to: containerCenterView)
        
        // Top part of centerStackView.
        let topCenterStackView = UIStackView()
        topCenterStackView.alignment = .top
        topCenterStackView.addArrangedSubview(titleLabel)
        topCenterStackView.addArrangedSubview(unreadCountView)
        
        // Bottom part of centerStackView.
        let bottomCenterStackView = UIStackView()
        bottomCenterStackView.spacing = UIStackView.spacingUseSystem
        
        subtitleLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        subtitleLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        timestampLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        
        bottomCenterStackView.addArrangedSubview(subtitleLabel)
        bottomCenterStackView.addArrangedSubview(readStatusView)
        bottomCenterStackView.addArrangedSubview(timestampLabel)
        
        stackView.addArrangedSubview(topCenterStackView)
        stackView.addArrangedSubview(bottomCenterStackView)
        
        container.centerStackView.isHidden = false
        container.centerStackView.addArrangedSubview(containerCenterView)
    
        avatarView.widthAnchor.constraint(equalToConstant: avatarView.intrinsicContentSize.width).isActive = true
    }
    
    open func updateContent() {
        // Title
        
        titleLabel.text = channel?.displayName
        
        // Subtitle
        
        subtitleLabel.text = typingMemberOrLastMessageString
        
        // Avatar
        
        avatarView.channel = channel
        avatarView.currentUserId = currentUserId
        
        // UnreadCount
        
        // Mock test code
        unreadCountView.unreadCount = channel?.unreadCount ?? .noUnread
        unreadCountView.invalidateIntrinsicContentSize()
        
        // Timestamp
        
        timestampLabel.text = channel?.lastMessageAt?.getFormattedDate(format: "hh:mm a")
        
        // TODO: ReadStatusView
        // Missing LLC API
    }
    
    open func resetContent() {
        titleLabel.text = ""
        subtitleLabel.text = ""
        avatarView.channel = nil
        unreadCountView.unreadCount = .noUnread
        timestampLabel.text = ""
        readStatusView.status = .empty
    }
}

extension ChatChannelListItemView {
    var typingMemberString: String? {
        guard let members = channel?.currentlyTypingMembers, !members.isEmpty else { return nil }
        let names = members.map(\.displayName).sorted()
        return names.joined(separator: ", ") + " \(names.count == 1 ? "is" : "are") typing..."
    }
    
    var typingMemberOrLastMessageString: String? {
        guard let channel = channel else { return nil }
        if let typingMembersInfo = typingMemberString {
            return typingMembersInfo
        } else if let latestMessage = channel.latestMessages.first {
            return "\(latestMessage.author.displayName): \(latestMessage.text)"
        } else {
            return "No messages"
        }
    }
}
