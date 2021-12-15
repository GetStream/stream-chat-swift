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
    
    /// The maximum number of images that combine to form a single avatar
    private let maxNumberOfImagesInCombinedAvatar = 4
    
    /// Object responsible for providing functionality of merging images.
    /// Used when creating compound avatars from channel members individual avatars
    open var imageMerger: ImageMerging = {
        DefaultImageMerger()
    }()

    override open func setUpLayout() {
        super.setUpLayout()
        embed(presenceAvatarView)
    }

    override open func updateContent() {
        guard let channel = content.channel else {
            loadIntoAvatarImageView(from: nil, placeholder: appearance.images.userAvatarPlaceholder3)
            presenceAvatarView.isOnlineIndicatorVisible = false
            return
        }

        loadAvatar(for: channel)
    }
    
    open func loadAvatar(for channel: ChatChannel) {
        // If the channel has an avatar set, load that avatar
        if let channelAvatarUrl = channel.imageURL {
            loadChannelAvatar(from: channelAvatarUrl)
            return
        }
      
        // Use the appropriate method to load avatar based on channel type
        if channel.isDirectMessageChannel {
            loadDirectMessageChannelAvatar(channel: channel)
        } else {
            loadMergedAvatars(channel: channel)
        }
    }
    
    /// Loads the avatar from the URL. This function is used when the channel has a non-nil `imageURL`
    /// - Parameter url: The `imageURL` of the channel
    open func loadChannelAvatar(from url: URL) {
        loadIntoAvatarImageView(from: url, placeholder: appearance.images.userAvatarPlaceholder4)
    }
    
    /// Loads avatar for a directMessageChannel
    /// - Parameter channel: The channel
    open func loadDirectMessageChannelAvatar(channel: ChatChannel) {
        let lastActiveMembers = self.lastActiveMembers()
        
        // If there are no members other than the current user in the channel, load a placeholder
        guard !lastActiveMembers.isEmpty, let otherMember = lastActiveMembers.first else {
            presenceAvatarView.isOnlineIndicatorVisible = false
            loadIntoAvatarImageView(from: nil, placeholder: appearance.images.userAvatarPlaceholder4)
            return
        }
        
        loadIntoAvatarImageView(from: otherMember.imageURL, placeholder: appearance.images.userAvatarPlaceholder3)
        presenceAvatarView.isOnlineIndicatorVisible = otherMember.isOnline
    }
    
    /// Loads an avatar which is merged (tiled) version of the first four active members of the channel
    /// - Parameter channel: The channel
    open func loadMergedAvatars(channel: ChatChannel) {
        // The channel is a non-DM channel, hide the online indicator
        presenceAvatarView.isOnlineIndicatorVisible = false
        
        let lastActiveMembers = self.lastActiveMembers()
        
        // If there are no members other than the current user in the channel, load a placeholder
        guard !lastActiveMembers.isEmpty else {
            loadIntoAvatarImageView(from: nil, placeholder: appearance.images.userAvatarPlaceholder4)
            return
        }
        
        var urls = lastActiveMembers.map(\.imageURL)
        
        if urls.isEmpty {
            loadIntoAvatarImageView(from: nil, placeholder: appearance.images.userAvatarPlaceholder3)
            return
        }
        
        // We show a combination of at max 4 images combined
        urls = Array(urls.prefix(maxNumberOfImagesInCombinedAvatar))
        
        loadAvatarsFrom(urls: urls, channelId: channel.cid) { [weak self] avatars, channelId in
            guard let self = self, channelId == self.content.channel?.cid else { return }
            
            let combinedImage = self.createMergedAvatar(from: avatars) ?? self.appearance.images.userAvatarPlaceholder2
            self.loadIntoAvatarImageView(from: nil, placeholder: combinedImage)
        }
    }
    
    /// Loads avatars for the given URLs
    /// - Parameters:
    ///   - urls: The avatar urls
    ///   - channelId: The channelId of the channel
    ///   - completion: Completion that gets called with an array of `UIImage`s when all the avatars are loaded
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
        
        for url in urls.prefix(maxNumberOfImagesInCombinedAvatar) {
            if let avatarUrl = url {
                avatarUrls.append(avatarUrl)
            } else {
                placeholderAvatars.append(placeholderImages.removeFirst())
            }
        }
        
        components.imageLoader.loadImages(
            from: avatarUrls,
            placeholders: placeholderImages,
            imageCDN: components.imageCDN
        ) { images in
            completion(images, channelId)
        }
    }
    
    /// Creates a merged avatar from the given images
    /// - Parameter avatars: The individual avatars
    /// - Returns: The merged avatar
    open func createMergedAvatar(from avatars: [UIImage]) -> UIImage? {
        guard !avatars.isEmpty else {
            return nil
        }
        
        var combinedImage: UIImage?
        
        let imageProcessor = components.imageProcessor
        
        let images = avatars.map {
            imageProcessor.scale(image: $0, to: .avatarThumbnailSize)
        }
        
        // The half of the width of the avatar
        let halfContainerSize = CGSize(width: CGSize.avatarThumbnailSize.width / 2, height: CGSize.avatarThumbnailSize.height)
        
        if images.count == 1, let image = images.first {
            combinedImage = image
        } else if images.count == 2, let firstImage = images.first, let secondImage = images.last {
            let leftImage = imageProcessor.crop(image: firstImage, to: halfContainerSize)
                ?? appearance.images.userAvatarPlaceholder1
            let rightImage = imageProcessor.crop(image: secondImage, to: halfContainerSize)
                ?? appearance.images.userAvatarPlaceholder1
            combinedImage = imageMerger.merge(
                images: [
                    leftImage,
                    rightImage
                ],
                orientation: .horizontal
            )
        } else if images.count == 3,
                let firstImage = images[safe: 0],
                let secondImage = images[safe: 1],
                let thirdImage = images[safe: 2] {
            let leftImage = imageProcessor.crop(image: firstImage, to: halfContainerSize)

            let rightCollage = imageMerger.merge(
                images: [
                    secondImage,
                    thirdImage
                ],
                orientation: .vertical
            )
            
            let rightImage = imageProcessor.crop(
                image: imageProcessor
                    .scale(image: rightCollage ?? appearance.images.userAvatarPlaceholder3, to: .avatarThumbnailSize),
                to: halfContainerSize
            )
            
            combinedImage = imageMerger.merge(
                images:
                [
                    leftImage ?? appearance.images.userAvatarPlaceholder1,
                    rightImage ?? appearance.images.userAvatarPlaceholder2
                ],
                orientation: .horizontal
            )
        } else if images.count == 4,
                let firstImage = images[safe: 0],
                let secondImage = images[safe: 1],
                let thirdImage = images[safe: 2],
                let forthImage = images[safe: 3] {
            let leftCollage = imageMerger.merge(
                images: [
                    firstImage,
                    thirdImage
                ],
                orientation: .vertical
            )
            
            let leftImage = imageProcessor.crop(
                image: imageProcessor
                    .scale(image: leftCollage ?? appearance.images.userAvatarPlaceholder1, to: .avatarThumbnailSize),
                to: halfContainerSize
            )
            
            let rightCollage = imageMerger.merge(
                images: [
                    secondImage,
                    forthImage
                ],
                orientation: .vertical
            )
            
            let rightImage = imageProcessor.crop(
                image: imageProcessor
                    .scale(image: rightCollage ?? appearance.images.userAvatarPlaceholder2, to: .avatarThumbnailSize),
                to: halfContainerSize
            )
         
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

    open func lastActiveMembers() -> [ChatChannelMember] {
        guard let channel = content.channel else { return [] }
        return channel.lastActiveMembers
            .sorted { $0.memberCreatedAt < $1.memberCreatedAt }
            .filter { $0.id != content.currentUserId }
    }
    
    open func loadIntoAvatarImageView(from url: URL?, placeholder: UIImage?) {
        components.imageLoader.loadImage(
            into: presenceAvatarView.avatarView.imageView,
            url: url,
            imageCDN: components.imageCDN,
            placeholder: placeholder,
            preferredSize: .avatarThumbnailSize
        )
    }
}
