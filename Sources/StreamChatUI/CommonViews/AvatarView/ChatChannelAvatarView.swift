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
        NukeImageLoader()
    }()
    
    /// Object responsible for providing functionality of merging images.
    /// Used when creating compound avatars from channel members individual avatars
    open lazy var imageMerger: ImageMerging = {
        DefaultImageMerger()
    }()
    
    /// Object responsible for providing functionality of merging images.
    /// Used when creating compound avatars from channel members individual avatars
    open lazy var imageProcessor: StreamImageProcessor = {
        StreamImageProcessor()
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
        presenceAvatarView.avatarView.imageView.loadImage(
            from: url,
            placeholder: appearance.images.userAvatarPlaceholder4,
            preferredSize: .avatarThumbnailSize,
            components: components
        )
    }
    
    /// Loads avatar for a directMessageChannel
    /// - Parameter channel: The channel
    open func loadDirectMessageChannelAvatar(channel: ChatChannel) {
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
        
        let otherMember = lastActiveMembers.first
        let isOnlineIndicatorVisible = otherMember?.isOnline ?? false
        
        presenceAvatarView.avatarView.imageView.loadImage(
            from: otherMember?.imageURL,
            placeholder: appearance.images.userAvatarPlaceholder3,
            preferredSize: .avatarThumbnailSize,
            components: components
        )
        
        presenceAvatarView.isOnlineIndicatorVisible = isOnlineIndicatorVisible
    }
    
    /// Loads an avatar which is merged (tiled) version of the first four active members of the channel
    /// - Parameter channel: The channel
    open func loadMergedAvatars(channel: ChatChannel) {
        // The channel is a non-DM channel, hide the online indicator
        presenceAvatarView.isOnlineIndicatorVisible = false
        
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
           
            let combinedImage = createMergedAvatar(from: images) ?? appearance.images.userAvatarPlaceholder2
            
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
            
            let combinedImage = self.createMergedAvatar(from: avatars) ?? self.appearance.images.userAvatarPlaceholder2
            
            self.presenceAvatarView.avatarView.imageView.loadImage(
                from: nil,
                placeholder: combinedImage,
                preferredSize: .avatarThumbnailSize,
                components: self.components
            )
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
            
            let thumbnailUrl = components.imageCDN.thumbnailURL(originalURL: avatarUrl, preferredSize: .avatarThumbnailSize)
            let imageRequest = components.imageCDN.urlRequest(forImage: thumbnailUrl)
            let cachingKey = components.imageCDN.cachingKey(forImage: avatarUrl)

            imageLoader.loadImage(using: imageRequest, cachingKey: cachingKey) { result in
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
    
    /// Creates a merged avatar from the given images
    /// - Parameter avatars: The individual avatars
    /// - Returns: The merged avatar
    open func createMergedAvatar(from avatars: [UIImage]) -> UIImage? {
        guard !avatars.isEmpty else {
            return appearance.images.userAvatarPlaceholder1
        }
        
        var combinedImage: UIImage?
        
        let images = avatars.map {
            imageProcessor.scale(image: $0, to: .avatarThumbnailSize)
        }
        
        // The half of the width of the avatar
        let halfContainerSize = CGSize(width: CGSize.avatarThumbnailSize.width / 2, height: CGSize.avatarThumbnailSize.height)
        
        if images.count == 1 {
            combinedImage = images[0]
        } else if images.count == 2 {
            let leftImage = imageProcessor.crop(image: images[0], to: halfContainerSize)
                ?? appearance.images.userAvatarPlaceholder1
            let rightImage = imageProcessor.crop(image: images[1], to: halfContainerSize)
                ?? appearance.images.userAvatarPlaceholder1
            combinedImage = imageMerger.merge(
                images: [
                    leftImage,
                    rightImage
                ],
                orientation: .horizontal
            )
        } else if images.count == 3 {
            let leftImage = imageProcessor.crop(image: images[0], to: halfContainerSize)

            let rightCollage = imageMerger.merge(
                images: [
                    images[1],
                    images[2]
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
        } else if images.count == 4 {
            let leftCollage = imageMerger.merge(
                images: [
                    images[0],
                    images[2]
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
                    images[1],
                    images[3]
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
}
