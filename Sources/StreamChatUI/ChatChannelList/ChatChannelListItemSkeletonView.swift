//
//  ChatChannelListItemSkeletonView.swift
//  StreamChat
//
//  Created by Hugo Bernal on 18/07/22.
//  Copyright © 2022 Stream.io Inc. All rights reserved.
//

import UIKit

open class ChatChannelListItemSkeletonView: /*ChatChannelListItemView,*/ _View, ThemeProvider, SkeletonLoadable {

    open private(set) lazy var avatarView: ChatChannelAvatarView = components
        .channelAvatarView
        .init()
        .withoutAutoresizingMaskConstraints

    open private(set) lazy var titleLabel: UILabel = UILabel()
        .withoutAutoresizingMaskConstraints

    open private(set) lazy var subtitleLabel: UILabel = UILabel()
        .withoutAutoresizingMaskConstraints

    open private(set) lazy var timestampLabel: UILabel = UILabel()
        .withoutAutoresizingMaskConstraints
    
    open private(set) lazy var mainContainer: ContainerStackView = ContainerStackView()
        .withoutAutoresizingMaskConstraints
    
    open private(set) lazy var rightContainer: ContainerStackView = ContainerStackView(
        axis: .vertical,
        spacing: 4
    )
    .withoutAutoresizingMaskConstraints

    open private(set) lazy var topContainer: ContainerStackView = ContainerStackView()
        .withoutAutoresizingMaskConstraints

    open private(set) lazy var bottomContainer: ContainerStackView = ContainerStackView(alignment: .center, spacing: 8)
        .withoutAutoresizingMaskConstraints
    
    private let avatarViewLayer = CAGradientLayer()
    private let titleLabelLayer = CAGradientLayer()
    private let subtitleLabelLayer = CAGradientLayer()
    private let timestampLabelLayer = CAGradientLayer()
    
    override open func setUp() {
        super.setUp()
        
        titleLabel.text = "Placeholder"
        subtitleLabel.text = "subtitle placeholder"
        timestampLabel.text = "00:00"
        
        avatarViewLayer.startPoint = CGPoint(x: 0, y: 0.5)
        avatarViewLayer.endPoint = CGPoint(x: 1, y: 0.5)
        avatarView.presenceAvatarView.avatarView.imageView.layer.addSublayer(avatarViewLayer)
        
        titleLabelLayer.startPoint = CGPoint(x: 0, y: 0.5)
        titleLabelLayer.endPoint = CGPoint(x: 1, y: 0.5)
        titleLabel.layer.addSublayer(titleLabelLayer)
        
        subtitleLabelLayer.startPoint = CGPoint(x: 0, y: 0.5)
        subtitleLabelLayer.endPoint = CGPoint(x: 1, y: 0.5)
        subtitleLabel.layer.addSublayer(subtitleLabelLayer)
        
        timestampLabelLayer.startPoint = CGPoint(x: 0, y: 0.5)
        timestampLabelLayer.endPoint = CGPoint(x: 1, y: 0.5)
        timestampLabel.layer.addSublayer(timestampLabelLayer)

        let avatarGroup = makeAnimationGroup()
        avatarGroup.beginTime = 0.0
        avatarViewLayer.add(avatarGroup, forKey: "backgroundColor")
        
        let titleGroup = makeAnimationGroup(previousGroup: avatarGroup)
        titleLabelLayer.add(titleGroup, forKey: "backgroundColor")
        
        let subtitleGroup = makeAnimationGroup(previousGroup: avatarGroup)
        subtitleLabelLayer.add(subtitleGroup, forKey: "backgroundColor")
        
        let timestampGroup = makeAnimationGroup(previousGroup: subtitleGroup)
        timestampLabelLayer.add(timestampGroup, forKey: "backgroundColor")
    }
    
    override open func setUpLayout() {
        super.setUpLayout()
        
        topContainer.addArrangedSubviews([
            titleLabel.flexible(axis: .horizontal)
        ])

        bottomContainer.addArrangedSubviews([
            subtitleLabel.flexible(axis: .horizontal), timestampLabel
        ])
        
        rightContainer.addArrangedSubviews([
            topContainer, bottomContainer
        ])

        NSLayoutConstraint.activate([
            avatarView.heightAnchor.pin(equalToConstant: 48),
            avatarView.widthAnchor.pin(equalTo: avatarView.heightAnchor)
        ])

        mainContainer.addArrangedSubviews([
            avatarView,
            rightContainer
        ])
        
        mainContainer.alignment = .center
        mainContainer.isLayoutMarginsRelativeArrangement = true
        
        timestampLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        
        embed(mainContainer)
    }
    
    override open func layoutSubviews() {
        super.layoutSubviews()
        
        avatarViewLayer.frame = avatarView.bounds
        avatarViewLayer.cornerRadius = titleLabel.bounds.height / 2

        titleLabelLayer.frame = titleLabel.textRect(forBounds: titleLabel.bounds, limitedToNumberOfLines: 1)
        titleLabelLayer.cornerRadius = titleLabel.bounds.height / 2

        subtitleLabelLayer.frame = subtitleLabel.bounds
        subtitleLabelLayer.cornerRadius = subtitleLabel.bounds.height / 2

        timestampLabelLayer.frame = timestampLabel.bounds
        timestampLabelLayer.cornerRadius = timestampLabel.bounds.height / 2
    }
}
