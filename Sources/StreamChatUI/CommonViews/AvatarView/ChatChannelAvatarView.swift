//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamChat
import StreamChatCommonUI
import UIKit

/// A view that shows a channel avatar including an online indicator if any user is online.
open class ChatChannelAvatarView: _View, ThemeProvider {
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

    /// The queue used for merged avatar image processing.
    /// Set to `nil` to perform processing synchronously on the calling thread.
    open var imageProcessingQueue: DispatchQueue? = .global(qos: .userInitiated)

    /// The cached merged avatar together with the channel id, the ids of the members shown in it, and
    /// the channel's member count at the time it was rendered.
    ///
    /// The merged avatar is computed once and then reused while it's still valid. This keeps the avatar
    /// stable while it's displayed when the channel's last active members are reordered (e.g. due to
    /// member activity updates) or when members that aren't shown change. It's recomputed when the view
    /// is bound to a different channel (e.g. on cell reuse), when one of the shown members leaves or is
    /// replaced, or — while it shows fewer than the maximum number of members — when the member count
    /// changes, so that a newly added member is shown.
    private var cachedMergedAvatar: (channelId: ChannelId, memberIds: Set<UserId>, memberCount: Int, image: UIImage)?

    override open func setUpLayout() {
        super.setUpLayout()
        embed(presenceAvatarView)
    }

    override open func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        if previousTraitCollection?.userInterfaceStyle != traitCollection.userInterfaceStyle {
            // The merged avatar can include appearance-dependent initials placeholders, so the
            // cache must be invalidated when the interface style changes to re-render it.
            cachedMergedAvatar = nil
        }
        super.traitCollectionDidChange(previousTraitCollection)
    }

    override open func updateContent() {
        guard let channel = content.channel else {
            loadIntoAvatarImageView(from: nil, placeholder: initialsPlaceholder(name: ""))
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
        if channel.memberCount == 2 {
            loadDirectMessageChannelAvatar(channel: channel)
        } else {
            loadMergedAvatars(channel: channel)
        }
    }

    /// Loads the avatar from the URL. This function is used when the channel has a non-nil `imageURL`
    /// - Parameter url: The `imageURL` of the channel
    open func loadChannelAvatar(from url: URL) {
        loadIntoAvatarImageView(from: url, placeholder: initialsPlaceholder(name: ""))
    }

    /// Loads avatar for a directMessageChannel
    /// - Parameter channel: The channel
    open func loadDirectMessageChannelAvatar(channel: ChatChannel) {
        let lastActiveMembers = self.lastActiveMembers()

        // If there are no members other than the current user in the channel, load a placeholder
        guard !lastActiveMembers.isEmpty, let otherMember = lastActiveMembers.first else {
            presenceAvatarView.isOnlineIndicatorVisible = false
            loadIntoAvatarImageView(from: nil, placeholder: initialsPlaceholder(name: ""))
            return
        }

        let placeholder = UserAvatarInitialsImage.image(
            name: otherMember.name ?? "",
            size: components.avatarThumbnailSize,
            appearance: appearance
        )
        loadIntoAvatarImageView(from: otherMember.imageURL, placeholder: placeholder)
        presenceAvatarView.isOnlineIndicatorVisible = otherMember.isOnline
    }

    /// Loads an avatar which is merged (tiled) version of the first four active members of the channel
    /// - Parameter channel: The channel
    open func loadMergedAvatars(channel: ChatChannel) {
        // The channel is a non-DM channel, hide the online indicator
        presenceAvatarView.isOnlineIndicatorVisible = false

        // Reuse the previously rendered avatar while it's still valid. It stays valid as long as every
        // member it shows is still in the channel, so reordering and changes to members that aren't
        // shown don't recompute it. While it shows fewer than the maximum number of members it also
        // requires the member count to be unchanged, so that a newly added member gets shown. Only the
        // shown members (at most four) are checked, against the unsorted member list, so the sorting
        // done by `lastActiveMembers()` is skipped on this hot path while the avatar is still valid.
        if let cachedMergedAvatar, cachedMergedAvatar.channelId == channel.cid {
            let allShownMembersStillPresent = cachedMergedAvatar.memberIds.allSatisfy { memberId in
                channel.lastActiveMembers.contains { $0.id == memberId }
            }
            let showsMaximumMembers = cachedMergedAvatar.memberIds.count >= maxNumberOfImagesInCombinedAvatar
            let memberCountUnchanged = cachedMergedAvatar.memberCount == channel.memberCount
            if allShownMembersStillPresent, showsMaximumMembers || memberCountUnchanged {
                loadIntoAvatarImageView(from: nil, placeholder: cachedMergedAvatar.image)
                return
            }
        }

        let lastActiveMembers = self.lastActiveMembers()

        // If there are no members other than the current user in the channel, load a placeholder
        guard !lastActiveMembers.isEmpty else {
            loadIntoAvatarImageView(from: nil, placeholder: initialsPlaceholder(name: ""))
            return
        }

        let members = Array(lastActiveMembers.prefix(maxNumberOfImagesInCombinedAvatar))
        let shownMemberIds = Set(members.map(\.id))
        let memberCount = channel.memberCount
        let urls = members.map(\.imageURL)
        let names = members.map { $0.name ?? "" }

        guard !urls.isEmpty else {
            loadIntoAvatarImageView(from: nil, placeholder: initialsPlaceholder(name: ""))
            return
        }

        // Capture @MainActor-isolated dependencies before dispatching to background
        let imageProcessor = components.imageProcessor
        let imageMerger = self.imageMerger
        let avatarThumbnailSize = components.avatarThumbnailSize
        let fallbackPlaceholder = initialsPlaceholder(name: "")
        let halfContainerSize = CGSize(width: avatarThumbnailSize.width / 2, height: avatarThumbnailSize.height)
        let halfFallback = initialsPlaceholder(name: "", size: halfContainerSize)

        let queue = imageProcessingQueue
        loadAvatarsFrom(urls: urls, names: names, channelId: channel.cid) { [weak self] avatars, channelId in
            let mergeAndApply: @Sendable () -> Void = { [weak self] in
                let combinedImage = MergedChannelAvatarRenderer.createMergedAvatarImage(
                    from: avatars,
                    imageProcessor: imageProcessor,
                    imageMerger: imageMerger,
                    avatarThumbnailSize: avatarThumbnailSize,
                    fallbackImage: halfFallback
                ) ?? fallbackPlaceholder

                StreamConcurrency.onMain {
                    guard let self, channelId == self.content.channel?.cid else { return }
                    // If an avatar showing the same members was already cached (e.g. by an earlier
                    // in-flight computation), keep it to avoid changing the avatar.
                    if let cachedMergedAvatar = self.cachedMergedAvatar,
                       cachedMergedAvatar.channelId == channelId,
                       cachedMergedAvatar.memberIds == shownMemberIds {
                        self.loadIntoAvatarImageView(from: nil, placeholder: cachedMergedAvatar.image)
                        return
                    }
                    self.cachedMergedAvatar = (channelId, shownMemberIds, memberCount, combinedImage)
                    self.loadIntoAvatarImageView(from: nil, placeholder: combinedImage)
                }
            }

            if let queue {
                queue.async(execute: mergeAndApply)
            } else {
                mergeAndApply()
            }
        }
    }

    /// Loads avatars for the given URLs
    /// - Parameters:
    ///   - urls: The avatar urls
    ///   - names: The display names corresponding to each URL, used to generate initials placeholders.
    ///   - channelId: The channelId of the channel
    ///   - completion: Completion that gets called with an array of `UIImage`s when all the avatars are loaded
    open func loadAvatarsFrom(
        urls: [URL?],
        names: [String] = [],
        channelId: ChannelId,
        completion: @escaping @Sendable ([UIImage], ChannelId)
            -> Void
    ) {
        let avatarSize = components.avatarThumbnailSize
        let imageProcessor = components.imageProcessor
        let currentAppearance = appearance
        nonisolated(unsafe) var memberNames = names
        let requests = urls.prefix(maxNumberOfImagesInCombinedAvatar)
            .compactMap { $0 }
            .map { ImageDownloadRequest(url: $0, options: ImageDownloadOptions(resize: .init(avatarSize))) }

        components.mediaLoader.downloadMultipleImages(with: requests) { results in
            // Scale only placeholders since images already have a correct size
            let imagesMapper = ImageResultsMapper(results: results)
            let images = imagesMapper.mapErrors {
                let name = memberNames.isEmpty ? "" : memberNames.removeFirst()
                let initialsImage = UserAvatarInitialsImage.image(
                    name: name,
                    size: avatarSize,
                    appearance: currentAppearance
                )
                return imageProcessor.scale(image: initialsImage, to: avatarSize)
            }
            completion(images, channelId)
        }
    }

    /// Creates a merged avatar from the given images
    /// - Parameter avatars: The individual avatars
    /// - Returns: The merged avatar
    open func createMergedAvatar(from avatars: [UIImage]) -> UIImage? {
        let size = components.avatarThumbnailSize
        let halfContainerSize = CGSize(width: size.width / 2, height: size.height)
        return MergedChannelAvatarRenderer.createMergedAvatarImage(
            from: avatars,
            imageProcessor: components.imageProcessor,
            imageMerger: imageMerger,
            avatarThumbnailSize: size,
            fallbackImage: initialsPlaceholder(name: "", size: halfContainerSize)
        )
    }

    open func lastActiveMembers() -> [ChatChannelMember] {
        guard let channel = content.channel else { return [] }
        return channel.lastActiveMembers
            .sorted { $0.memberCreatedAt < $1.memberCreatedAt }
            .filter { $0.id != content.currentUserId }
    }

    func initialsPlaceholder(name: String, size: CGSize? = nil) -> UIImage {
        UserAvatarInitialsImage.image(
            name: name,
            size: size ?? components.avatarThumbnailSize,
            appearance: appearance
        )
    }

    open func loadIntoAvatarImageView(from url: URL?, placeholder: UIImage?) {
        components.mediaLoader.loadImage(
            into: presenceAvatarView.avatarView.imageView,
            from: url,
            with: ImageLoaderOptions(
                resize: .init(components.avatarThumbnailSize),
                placeholder: placeholder
            )
        )
    }
}

private enum MergedChannelAvatarRenderer {
    /// Creates a merged avatar image from individual avatars. Thread-safe — can be called from any queue.
    static func createMergedAvatarImage(
        from avatars: [UIImage],
        imageProcessor: ImageProcessor,
        imageMerger: ImageMerging,
        avatarThumbnailSize: CGSize,
        fallbackImage: UIImage
    ) -> UIImage? {
        guard !avatars.isEmpty else {
            return nil
        }
        
        let images = avatars
        let halfContainerSize = CGSize(width: avatarThumbnailSize.width / 2, height: avatarThumbnailSize.height)
        
        if images.count == 1, let image = images.first {
            return image
        } else if images.count == 2, let firstImage = images.first, let secondImage = images.last {
            let leftImage = imageProcessor.crop(image: firstImage, to: halfContainerSize) ?? fallbackImage
            let rightImage = imageProcessor.crop(image: secondImage, to: halfContainerSize) ?? fallbackImage
            return imageMerger.merge(
                images: [leftImage, rightImage],
                orientation: .horizontal
            )
        } else if images.count == 3,
                  let firstImage = images[safe: 0],
                  let secondImage = images[safe: 1],
                  let thirdImage = images[safe: 2] {
            let leftImage = imageProcessor.crop(image: firstImage, to: halfContainerSize)
            
            let rightCollage = imageMerger.merge(
                images: [secondImage, thirdImage],
                orientation: .vertical
            )
            
            let rightImage = imageProcessor.crop(
                image: imageProcessor.scale(
                    image: rightCollage ?? fallbackImage,
                    to: avatarThumbnailSize
                ),
                to: halfContainerSize
            )
            
            return imageMerger.merge(
                images: [leftImage ?? fallbackImage, rightImage ?? fallbackImage],
                orientation: .horizontal
            )
        } else if images.count == 4,
                  let firstImage = images[safe: 0],
                  let secondImage = images[safe: 1],
                  let thirdImage = images[safe: 2],
                  let forthImage = images[safe: 3] {
            let leftCollage = imageMerger.merge(
                images: [firstImage, thirdImage],
                orientation: .vertical
            )
            
            let leftImage = imageProcessor.crop(
                image: imageProcessor.scale(
                    image: leftCollage ?? fallbackImage,
                    to: avatarThumbnailSize
                ),
                to: halfContainerSize
            )
            
            let rightCollage = imageMerger.merge(
                images: [secondImage, forthImage],
                orientation: .vertical
            )
            
            let rightImage = imageProcessor.crop(
                image: imageProcessor.scale(
                    image: rightCollage ?? fallbackImage,
                    to: avatarThumbnailSize
                ),
                to: halfContainerSize
            )
            
            return imageMerger.merge(
                images: [leftImage ?? fallbackImage, rightImage ?? fallbackImage],
                orientation: .horizontal
            )
        }
        
        return nil
    }
}
