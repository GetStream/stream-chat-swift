//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// A view that shows a channel avatar including an online indicator if any user is online.
open class ChatChannelAvatarView: _View, ThemeProvider, SwiftUIRepresentable {
    /// A view that shows the avatar image
    open private(set) lazy var presenceAvatarView: ChatPresenceAvatarView = components
        .presenceAvatarView.init()
        .withoutAutoresizingMaskConstraints

    /// The data this view component shows.
    open var content: (channel: ChatChannel?, currentUserId: UserId?) {
        didSet { updateContentIfNeeded() }
    }
    
    /// Object responsible for loading images.
    open lazy var imageLoader: ImageLoading = {
        DefaultImageLoader(imageCDN: components.imageCDN)
    }()
    
    /// Object responsible for providing functionality of merging images.
    /// Used when creating compound avatars from channel members individual avatars
    open lazy var imageMerger: ImageMerging = {
        DefaultImageMerger()
    }()

    override open func setUpLayout() {
        super.setUpLayout()
        embed(presenceAvatarView)
    }

    override open func updateContent() {
        guard let channel = content.channel else {
            presenceAvatarView.avatarView.imageView.loadImage(
                from: nil,
                placeholder: appearance.images.userAvatarPlaceholder3,
                preferredSize: .avatarThumbnailSize,
                components: components
            )
            return
        }

        loadAvatar(for: channel)
    }
        
    open func loadAvatar(for channel: ChatChannel) {
        // If the channel has an avatar set, load that avatar
        if let channelAvatarUrl = channel.imageURL {
            presenceAvatarView.avatarView.imageView.loadImage(
                from: channelAvatarUrl,
                placeholder: appearance.images.userAvatarPlaceholder4,
                preferredSize: .avatarThumbnailSize,
                components: components
            )
            return
        }
        
        let lastActiveMembers = channel.lastActiveMembers
            .sorted { $0.memberCreatedAt < $1.memberCreatedAt }
            .filter { $0.id != content.currentUserId }
        
        // If there are no members other than the current user in the channel, load a placeholder
        if lastActiveMembers.isEmpty {
            presenceAvatarView.avatarView.imageView.loadImage(
                from: nil,
                placeholder: appearance.images.userAvatarPlaceholder4,
                preferredSize: .avatarThumbnailSize,
                components: components
            )
            return
        }
        
        // If the channel is a direct message channel, load the other user's avatar
        // and also set the online indicator visible
        if channel.isDirectMessageChannel {
            let otherMember = lastActiveMembers.first
            let isOnlineIndicatorVisible = otherMember?.isOnline ?? false
            
            presenceAvatarView.avatarView.imageView.loadImage(
                from: otherMember?.imageURL,
                placeholder: appearance.images.userAvatarPlaceholder3,
                preferredSize: .avatarThumbnailSize,
                components: components
            )
            
            presenceAvatarView.isOnlineIndicatorVisible = isOnlineIndicatorVisible
            return
        }
        
        // The channel is a non-DM channel, hide the online indicator
        presenceAvatarView.isOnlineIndicatorVisible = false
        
        var urls = lastActiveMembers.map(\.imageURL)
        
        if urls.isEmpty {
            presenceAvatarView.avatarView.imageView.loadImage(
                from: nil,
                placeholder: appearance.images.userAvatarPlaceholder3,
                preferredSize: .avatarThumbnailSize,
                components: components
            )
            return
        }
        
        // We show a combination of at max 4 images combined
        urls = Array(urls.prefix(4))
        
        guard !SystemEnvironment.isTests else {
            // When running tests, we load the images synchronously
            let images = urls.map { UIImage(data: try! Data(contentsOf: $0!))! }
           
            let combinedImage = getCombinedAvatarImage(from: images) ?? appearance.images.userAvatarPlaceholder2
            
            presenceAvatarView.avatarView.imageView.loadImage(
                from: nil,
                placeholder: combinedImage,
                preferredSize: .avatarThumbnailSize,
                components: components
            )
            return
        }
        
        loadAvatarsFrom(urls: urls, channelId: channel.cid) { [weak self] avatars, channelId in
            guard let self = self, channelId == self.content.channel?.cid else { return }
            
            let combinedImage = self.getCombinedAvatarImage(from: avatars) ?? self.appearance.images.userAvatarPlaceholder2
            
            self.presenceAvatarView.avatarView.imageView.loadImage(
                from: nil,
                placeholder: combinedImage,
                preferredSize: .avatarThumbnailSize,
                components: self.components
            )
        }
    }
    
    open func loadAvatarsFrom(
        urls: [URL?],
        channelId: ChannelId,
        completion: @escaping ([UIImage], ChannelId)
            -> Void
    ) {
        var placeholderAvatars: [UIImage] = []
        
        var placeholderImages = [
            appearance.images.userAvatarPlaceholder1,
            appearance.images.userAvatarPlaceholder2,
            appearance.images.userAvatarPlaceholder3,
            appearance.images.userAvatarPlaceholder4
        ]
        
        var avatarUrls: [URL] = []
        
        for url in urls.prefix(4) {
            if let avatarUrl = url {
                avatarUrls.append(avatarUrl)
            } else {
                placeholderAvatars.append(placeholderImages.removeFirst())
            }
        }
        
        let group = DispatchGroup()
        var images: [UIImage] = []
        
        for avatarUrl in avatarUrls {
            var placeholderIndex = 0
            group.enter()
            imageLoader.loadImage(
                from: avatarUrl,
                resize: true,
                preferredSize: .avatarThumbnailSize
            ) { result in
                switch result {
                case let .success(image):
                    images.append(image)
                case .failure:
                    if !placeholderImages.isEmpty {
                        // Rotationally use the placeholders
                        images.append(placeholderImages[placeholderIndex])
                        placeholderIndex += 1
                        if placeholderIndex == placeholderImages.count {
                            placeholderIndex = 0
                        }
                    }
                }
                group.leave()
            }
            
            group.notify(queue: .main) {
                completion(images, channelId)
            }
        }
    }
    
    open func getCombinedAvatarImage(from avatars: [UIImage]) -> UIImage? {
        var combinedImage: UIImage?
        
        let images = avatars.map { $0.scaled(to: .avatarThumbnailSize) }
        
        // The half of the width of the avatar
        let halfContainerSize = CGSize(width: CGSize.avatarThumbnailSize.width / 2, height: CGSize.avatarThumbnailSize.height)
        
        if images.count == 1 {
            combinedImage = images[0]
        } else if images.count == 2 {
            let leftImage = images[0].cropped(to: halfContainerSize)
                ?? appearance.images.userAvatarPlaceholder1
            let rightImage = images[1].cropped(to: halfContainerSize)
                ?? appearance.images.userAvatarPlaceholder1
            combinedImage = imageMerger.merge(
                images: [
                    leftImage,
                    rightImage
                ],
                orientation: .horizontal
            )
        } else if images.count == 3 {
            let leftImage = images[0].cropped(to: halfContainerSize)
            let rightImage = imageMerger.merge(
                images: [
                    images[1],
                    images[2]
                ],
                orientation: .vertical
            )?
                .scaled(to: .avatarThumbnailSize)
                .cropped(to: halfContainerSize)
                ?? appearance.images.userAvatarPlaceholder3
                .cropped(to: halfContainerSize)
            
            combinedImage = imageMerger.merge(
                images:
                [
                    leftImage ?? appearance.images.userAvatarPlaceholder1,
                    rightImage ?? appearance.images.userAvatarPlaceholder2
                ],
                orientation: .horizontal
            )
        } else if images.count == 4 {
            let leftImage = imageMerger.merge(
                images: [
                    images[0],
                    images[2]
                ],
                orientation: .vertical
            )?
                .scaled(to: .avatarThumbnailSize)
                .cropped(to: halfContainerSize)
                ?? appearance.images.userAvatarPlaceholder1
                .cropped(to: halfContainerSize)
            
            let rightImage = imageMerger.merge(
                images: [
                    images[1],
                    images[3]
                ],
                orientation: .vertical
            )?
                .scaled(to: .avatarThumbnailSize)
                .cropped(to: halfContainerSize)
                ?? appearance.images.userAvatarPlaceholder2
                .cropped(to: halfContainerSize)
            
            combinedImage = imageMerger.merge(
                images: [
                    leftImage ?? appearance.images.userAvatarPlaceholder1,
                    rightImage ?? appearance.images.userAvatarPlaceholder2
                ],
                orientation: .horizontal
            )
        }
        
        return combinedImage
    }
}
