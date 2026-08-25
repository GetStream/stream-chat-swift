//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamChat
import StreamChatCommonUI
import StreamChatUI
import UIKit

/// The grid of the images and videos shared in a channel.
final class DemoChannelMediaAttachmentsVC: UIViewController,
    ThemeProvider,
    ChatMessageSearchControllerDelegate,
    UICollectionViewDataSource,
    UICollectionViewDelegateFlowLayout {
    private struct MediaItem {
        let message: ChatMessage
        let attachmentId: AttachmentId
        let previewURL: URL?
        let videoAttachment: ChatMessageVideoAttachment?
    }

    private static let itemSpacing: CGFloat = 2

    private let channel: ChatChannel
    private let messageSearchController: ChatMessageSearchController

    private var mediaItems: [MediaItem] = []
    private var isLoadingNextMessages = false

    private lazy var zoomTransitionController = ZoomTransitionController()

    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = Self.itemSpacing
        layout.minimumLineSpacing = Self.itemSpacing

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.backgroundColor = appearance.colorPalette.backgroundCoreApp
        collectionView.register(
            DemoMediaAttachmentCell.self,
            forCellWithReuseIdentifier: DemoMediaAttachmentCell.reuseIdentifier
        )
        return collectionView
    }()

    private lazy var loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.hidesWhenStopped = true
        return indicator
    }()

    private lazy var emptyStateView = DemoChannelInfoEmptyStateView(
        icon: appearance.images.imagePlaceholder,
        title: "No media",
        subtitle: "Photos or videos sent in this chat will appear here."
    )

    init(channel: ChatChannel, client: ChatClient) {
        self.channel = channel
        messageSearchController = client.messageSearchController()
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Photos & Videos"
        view.backgroundColor = appearance.colorPalette.backgroundCoreApp

        emptyStateView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(collectionView)
        view.addSubview(emptyStateView)
        view.addSubview(loadingIndicator)
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            emptyStateView.topAnchor.constraint(equalTo: view.topAnchor),
            emptyStateView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            emptyStateView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            emptyStateView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])

        messageSearchController.delegate = self
        loadingIndicator.startAnimating()
        emptyStateView.isHidden = true
        messageSearchController.search(
            query: .init(
                channelFilter: .equal(.cid, to: channel.cid),
                messageFilter: .withAttachments([.image, .video])
            )
        ) { [weak self] _ in
            self?.loadingIndicator.stopAnimating()
            self?.updateContent()
        }
    }

    private func updateContent() {
        mediaItems = messageSearchController.messages.flatMap { message -> [MediaItem] in
            let images = message.imageAttachments.map { attachment in
                MediaItem(
                    message: message,
                    attachmentId: attachment.id,
                    previewURL: attachment.imageURL,
                    videoAttachment: nil
                )
            }
            let videos = message.videoAttachments.map { attachment in
                MediaItem(
                    message: message,
                    attachmentId: attachment.id,
                    previewURL: attachment.payload.thumbnailURL,
                    videoAttachment: attachment
                )
            }
            return images + videos
        }

        emptyStateView.isHidden = !mediaItems.isEmpty || loadingIndicator.isAnimating
        collectionView.reloadData()
    }

    private func showGallery(for item: MediaItem, from imageView: UIImageView?) {
        let galleryVC = components.galleryVC.init()
        galleryVC.modalPresentationStyle = .overFullScreen
        galleryVC.transitioningDelegate = zoomTransitionController
        galleryVC.transitionController = zoomTransitionController
        galleryVC.content = .init(
            message: item.message,
            currentPage: (item.message.videoAttachments.map(\.id) + item.message.imageAttachments.map(\.id))
                .firstIndex(of: item.attachmentId) ?? 0
        )

        zoomTransitionController.fromImageView = imageView
        zoomTransitionController.presentedVCImageView = { [weak galleryVC] in
            galleryVC?.imageViewToAnimateWhenDismissing
        }
        zoomTransitionController.presentingImageView = { [weak imageView] in imageView }

        present(galleryVC, animated: true)
    }

    // MARK: - UICollectionViewDataSource

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        mediaItems.count
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: DemoMediaAttachmentCell.reuseIdentifier,
            for: indexPath
        )
        guard let cell = cell as? DemoMediaAttachmentCell else { return cell }

        let item = mediaItems[indexPath.item]
        if let videoAttachment = item.videoAttachment {
            cell.configureVideo(with: videoAttachment, previewURL: item.previewURL)
        } else {
            cell.configureImage(with: item.previewURL)
        }
        return cell
    }

    // MARK: - UICollectionViewDelegateFlowLayout

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        let numberOfColumns: CGFloat = 3
        let spacing = Self.itemSpacing * (numberOfColumns - 1)
        let availableWidth = collectionView.bounds.width - collectionView.adjustedContentInset.left
            - collectionView.adjustedContentInset.right
        let itemWidth = ((availableWidth - spacing) / numberOfColumns).rounded(.down)
        return CGSize(width: itemWidth, height: itemWidth)
    }

    func collectionView(
        _ collectionView: UICollectionView,
        willDisplay cell: UICollectionViewCell,
        forItemAt indexPath: IndexPath
    ) {
        guard indexPath.item >= mediaItems.count - 10, !isLoadingNextMessages else { return }

        isLoadingNextMessages = true
        messageSearchController.loadNextMessages { [weak self] _ in
            self?.isLoadingNextMessages = false
        }
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath) as? DemoMediaAttachmentCell
        showGallery(for: mediaItems[indexPath.item], from: cell?.imageView)
    }

    // MARK: - ChatMessageSearchControllerDelegate

    func controller(_ controller: ChatMessageSearchController, didChangeMessages changes: [ListChange<ChatMessage>]) {
        updateContent()
    }
}

/// A cell of the media grid, showing the preview of an image or a video attachment.
final class DemoMediaAttachmentCell: UICollectionViewCell, ThemeProvider {
    static let reuseIdentifier = String(describing: DemoMediaAttachmentCell.self)

    private static let previewSize = CGSize(width: 200, height: 200)

    private(set) lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.backgroundColor = appearance.colorPalette.backgroundCoreSurfaceSubtle
        return imageView
    }()

    private lazy var videoIconView: UIImageView = {
        let imageView = UIImageView(image: UIImage(systemName: "play.circle.fill"))
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .white
        imageView.isHidden = true
        return imageView
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setUpLayout()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.image = nil
        videoIconView.isHidden = true
    }

    func configureImage(with url: URL?) {
        videoIconView.isHidden = true
        loadPreview(from: url)
    }

    func configureVideo(with attachment: ChatMessageVideoAttachment, previewURL: URL?) {
        videoIconView.isHidden = false

        if previewURL != nil {
            loadPreview(from: previewURL)
            return
        }

        components.mediaLoader.loadVideoPreview(with: attachment) { [weak self] result in
            self?.imageView.image = try? result.get().image
        }
    }

    private func loadPreview(from url: URL?) {
        components.mediaLoader.loadImage(
            into: imageView,
            from: url,
            with: ImageLoaderOptions(resize: ImageResize(Self.previewSize))
        )
    }

    private func setUpLayout() {
        contentView.addSubview(imageView)
        contentView.addSubview(videoIconView)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        videoIconView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            videoIconView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            videoIconView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            videoIconView.widthAnchor.constraint(equalToConstant: 28),
            videoIconView.heightAnchor.constraint(equalToConstant: 28)
        ])
    }
}
