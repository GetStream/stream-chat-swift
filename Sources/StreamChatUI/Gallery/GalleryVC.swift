//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChat
import UIKit

/// A view controller to showcase and slide through multiple attachments
/// (images and videos by default).
public typealias GalleryVC = _GalleryVC<NoExtraData>

/// A viewcontroller to showcase and slide through multiple attachments
/// (images and videos by default).
open class _GalleryVC<ExtraData: ExtraDataTypes>:
    _ViewController,
    UIGestureRecognizerDelegate,
    AppearanceProvider,
    UICollectionViewDataSource,
    UICollectionViewDelegate,
    UICollectionViewDelegateFlowLayout,
    ComponentsProvider {
    /// The content of gallery view controller.
    public struct Content {
        /// The message which attachments are displayed by the gallery.
        public var message: _ChatMessage<ExtraData>
        /// The index of currently visible gallery item.
        public var currentPage: Int
        
        public init(
            message: _ChatMessage<ExtraData>,
            currentPage: Int = 0
        ) {
            self.message = message
            self.currentPage = currentPage
        }
    }
    
    /// Content to display.
    open var content: Content! {
        didSet {
            updateContentIfNeeded()
        }
    }
    
    /// Items to display.
    open var items: [AnyChatMessageAttachment] {
        let videos = content.message.videoAttachments.map(\.asAnyAttachment)
        let images = content.message.imageAttachments.map(\.asAnyAttachment)
        return videos + images
    }
    
    /// Controller for handling the transition for dismissal
    open var transitionController: ZoomTransitionController!
    
    /// `DateComponentsFormatter` for showing when the message was sent.
    open private(set) lazy var dateFormatter: DateComponentsFormatter = {
        let df = DateComponentsFormatter()
        df.allowedUnits = [.minute]
        df.unitsStyle = .full
        return df
    }()
    
    /// `UICollectionViewFlowLayout` instance for `attachmentsCollectionView`.
    open private(set) lazy var attachmentsFlowLayout: UICollectionViewFlowLayout = .init()
    
    /// `UICollectionView` instance to display attachments.
    open private(set) lazy var attachmentsCollectionView: UICollectionView = UICollectionView(
        frame: .zero,
        collectionViewLayout: attachmentsFlowLayout
    )
    .withoutAutoresizingMaskConstraints
    
    /// Bar view displayed at the top.
    open private(set) lazy var topBarView: UIView = UIView()
        .withoutAutoresizingMaskConstraints
    
    /// Label to show information about the user that sent the message.
    open private(set) lazy var userLabel: UILabel = UILabel()
        .withoutAutoresizingMaskConstraints
        .withBidirectionalLanguagesSupport
        .withAdjustingFontForContentSizeCategory
    
    /// Label to show information about the date the message was sent at.
    open private(set) lazy var dateLabel: UILabel = UILabel()
        .withoutAutoresizingMaskConstraints
        .withBidirectionalLanguagesSupport
        .withAdjustingFontForContentSizeCategory
    
    /// Bar view displayed at the bottom.
    open private(set) lazy var bottomBarView: UIView = UIView()
        .withoutAutoresizingMaskConstraints
    
    /// Label to show which photo is currently being displayed.
    open private(set) lazy var currentPhotoLabel: UILabel = UILabel()
        .withoutAutoresizingMaskConstraints
        .withBidirectionalLanguagesSupport
        .withAdjustingFontForContentSizeCategory
    
    /// Button for closing this view controller.
    open private(set) lazy var closeButton: UIButton = components
        .closeButton.init()
        .withoutAutoresizingMaskConstraints
    
    /// View that controls the video player of currently visible cell.
    open private(set) lazy var videoPlaybackBar: _VideoPlaybackControlView<ExtraData> = components
        .videoPlaybackControlView.init()
        .withoutAutoresizingMaskConstraints
    
    /// Button for sharing content.
    open private(set) lazy var shareButton: UIButton = components
        .shareButton.init()
        .withoutAutoresizingMaskConstraints
    
    /// A constaint between `topBarView.topAnchor` and `view.topAnchor`.
    open private(set) var topBarTopConstraint: NSLayoutConstraint?
    
    /// A constaint between `bottomBarView.bottomAnchor` and `view.bottomAnchor`.
    open private(set) var bottomBarBottomConstraint: NSLayoutConstraint?

    override open func setUpAppearance() {
        super.setUpAppearance()
        
        view.backgroundColor = appearance.colorPalette.background
        
        attachmentsCollectionView.backgroundColor = .clear
        attachmentsCollectionView.showsHorizontalScrollIndicator = false
        attachmentsCollectionView.showsVerticalScrollIndicator = false
        
        topBarView.backgroundColor = appearance.colorPalette.popoverBackground
        bottomBarView.backgroundColor = appearance.colorPalette.popoverBackground
        videoPlaybackBar.backgroundColor = appearance.colorPalette.popoverBackground
        
        userLabel.font = appearance.fonts.bodyBold
        userLabel.textColor = appearance.colorPalette.text
        userLabel.adjustsFontForContentSizeCategory = true
        userLabel.textAlignment = .center
        
        dateLabel.font = appearance.fonts.footnote
        dateLabel.textColor = appearance.colorPalette.subtitleText
        dateLabel.adjustsFontForContentSizeCategory = true
        dateLabel.textAlignment = .center
        
        currentPhotoLabel.font = appearance.fonts.bodyBold
        currentPhotoLabel.textColor = appearance.colorPalette.text
        currentPhotoLabel.adjustsFontForContentSizeCategory = true
        currentPhotoLabel.textAlignment = .center
    }
    
    override open func setUp() {
        super.setUp()
        attachmentsFlowLayout.scrollDirection = .horizontal
        attachmentsFlowLayout.minimumInteritemSpacing = 0
        attachmentsFlowLayout.minimumLineSpacing = 0
                
        attachmentsCollectionView.register(
            _ImageAttachmentGalleryCell<ExtraData>.self,
            forCellWithReuseIdentifier: _ImageAttachmentGalleryCell<ExtraData>.reuseId
        )
        attachmentsCollectionView.register(
            _VideoAttachmentGalleryCell<ExtraData>.self,
            forCellWithReuseIdentifier: _VideoAttachmentGalleryCell<ExtraData>.reuseId
        )
        attachmentsCollectionView.contentInsetAdjustmentBehavior = .never
        attachmentsCollectionView.isPagingEnabled = true
        attachmentsCollectionView.alwaysBounceVertical = false
        attachmentsCollectionView.alwaysBounceHorizontal = true
        attachmentsCollectionView.dataSource = self
        attachmentsCollectionView.delegate = self
        
        closeButton.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
        shareButton.addTarget(self, action: #selector(shareButtonTapped), for: .touchUpInside)
        
        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePan))
        panGestureRecognizer.delegate = self
        view.addGestureRecognizer(panGestureRecognizer)
    }
    
    override open func setUpLayout() {
        super.setUpLayout()
        
        view.embed(attachmentsCollectionView)
        
        view.addSubview(topBarView)
        topBarView.pin(anchors: [.leading, .trailing], to: view)
        topBarTopConstraint = topBarView.topAnchor.constraint(equalTo: view.topAnchor)
        topBarTopConstraint?.isActive = true
        
        let topBarContainerStackView = ContainerStackView()
            .withoutAutoresizingMaskConstraints
        topBarView.embed(topBarContainerStackView)
        topBarContainerStackView.preservesSuperviewLayoutMargins = true
        topBarContainerStackView.isLayoutMarginsRelativeArrangement = true
        
        topBarContainerStackView.addArrangedSubview(closeButton)
        
        let infoContainerStackView = ContainerStackView()
        infoContainerStackView.axis = .vertical
        infoContainerStackView.alignment = .center
        infoContainerStackView.spacing = 4
        topBarContainerStackView.addArrangedSubview(infoContainerStackView)
        infoContainerStackView.pin(anchors: [.centerX], to: view)
        
        userLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        infoContainerStackView.addArrangedSubview(userLabel)
        
        infoContainerStackView.addArrangedSubview(dateLabel)
        
        topBarContainerStackView.addArrangedSubview(UIView.spacer(axis: .horizontal))
        
        view.addSubview(bottomBarView)
        bottomBarView.pin(anchors: [.leading, .trailing], to: view)
        bottomBarBottomConstraint = bottomBarView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        bottomBarBottomConstraint?.isActive = true
        
        let bottomBarContainerStackView = ContainerStackView()
            .withoutAutoresizingMaskConstraints
        bottomBarContainerStackView.preservesSuperviewLayoutMargins = true
        bottomBarContainerStackView.isLayoutMarginsRelativeArrangement = true
        bottomBarView.embed(bottomBarContainerStackView)
        
        shareButton.setContentHuggingPriority(.streamRequire, for: .horizontal)
        bottomBarContainerStackView.addArrangedSubview(shareButton)

        currentPhotoLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        bottomBarContainerStackView.addArrangedSubview(currentPhotoLabel)
        currentPhotoLabel.pin(anchors: [.centerX], to: view)
        
        bottomBarContainerStackView.addArrangedSubview(.spacer(axis: .horizontal))
        
        view.addSubview(videoPlaybackBar)
        videoPlaybackBar.pin(anchors: [.leading, .trailing], to: view)
        videoPlaybackBar.bottomAnchor.constraint(equalTo: bottomBarView.topAnchor).isActive = true
    }
    
    override open func viewDidLoad() {
        super.viewDidLoad()
                
        attachmentsCollectionView.reloadData()
        DispatchQueue.main.async {
            self.attachmentsCollectionView.performBatchUpdates(nil) { _ in
                self.updateContent()
                self.attachmentsCollectionView.scrollToItem(
                    at: .init(item: self.content.currentPage, section: 0),
                    at: .centeredHorizontally,
                    animated: false
                )
            }
        }
    }
    
    override open func viewWillDisappear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        videoPlaybackBar.player?.pause()
    }
    
    override open func updateContent() {
        super.updateContent()

        if content.message.author.isOnline {
            dateLabel.text = L10n.Message.Title.online
        } else {
            if
                let lastActive = content.message.author.lastActiveAt,
                let minutes = dateFormatter.string(from: lastActive, to: Date()) {
                dateLabel.text = L10n.Message.Title.seeMinutesAgo(minutes)
            } else {
                dateLabel.text = L10n.Message.Title.offline
            }
        }
        
        userLabel.text = content.message.author.name

        currentPhotoLabel.text = L10n.currentSelection(content.currentPage + 1, items.count)
        
        let videoCell = attachmentsCollectionView.cellForItem(
            at: currentItemIndexPath
        ) as? _VideoAttachmentGalleryCell<ExtraData>
        
        videoPlaybackBar.player = videoCell?.player
        videoPlaybackBar.isHidden = videoPlaybackBar.player == nil
    }
    
    /// Called whenever user pans with a given `gestureRecognizer`.
    @objc
    open func handlePan(with gestureRecognizer: UIPanGestureRecognizer) {
        switch gestureRecognizer.state {
        case .began:
            transitionController.isInteractive = true
            dismiss(animated: true, completion: nil)
        case .ended:
            guard transitionController.isInteractive else { return }
            transitionController.isInteractive = false
            transitionController.handlePan(with: gestureRecognizer)
        default:
            guard transitionController.isInteractive else { return }
            transitionController.handlePan(with: gestureRecognizer)
        }
    }
    
    /// Called when `closeButton` is tapped.
    @objc
    open func closeButtonTapped() {
        dismiss(animated: true, completion: nil)
    }
    
    /// Called when `shareButton` is tapped.
    @objc
    open func shareButtonTapped() {
        guard let shareItem = shareItem(at: currentItemIndexPath) else {
            log.assertionFailure("Share item is missing for item at \(currentItemIndexPath).")
            return
        }
        
        let activityViewController = UIActivityViewController(
            activityItems: [shareItem],
            applicationActivities: nil
        )
        present(activityViewController, animated: true)
    }
    
    /// Updates `currentPage`.
    open func updateCurrentPage() {
        content.currentPage = Int(attachmentsCollectionView.contentOffset.x + attachmentsCollectionView.bounds.width / 2) /
            Int(attachmentsCollectionView.bounds.width)
    }
    
    open func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        items.count
    }
    
    open func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let reuseIdentifier = cellReuseIdentifierForItem(at: indexPath) else {
            log.assertionFailure("Reuse identifier is missing for item at \(indexPath)")
            return UICollectionViewCell()
        }
        
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: reuseIdentifier,
            for: indexPath
        ) as! _GalleryCollectionViewCell<ExtraData>
        
        cell.content = items[indexPath.item]
        
        cell.didTapOnce = { [weak self] in
            self?.handleSingleTapOnCell(at: indexPath)
        }
        
        return cell
    }
    
    open func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        collectionView.bounds.size
    }
    
    open func collectionView(
        _ collectionView: UICollectionView,
        targetContentOffsetForProposedContentOffset proposedContentOffset: CGPoint
    ) -> CGPoint {
        CGPoint(
            x: CGFloat(content.currentPage) * collectionView.bounds.width,
            y: proposedContentOffset.y
        )
    }
    
    open func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        updateCurrentPage()
    }
    
    open func scrollViewDidScroll(_ scrollView: UIScrollView) {
        videoPlaybackBar.player?.pause()
    }
    
    override open func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        attachmentsFlowLayout.invalidateLayout()
        super.viewWillTransition(to: size, with: coordinator)
    }
    
    /// An index path for the currently visible cell.
    open var currentItemIndexPath: IndexPath {
        .init(item: content.currentPage, section: 0)
    }
    
    /// A currently visible gallery item.
    open var currentItem: AnyChatMessageAttachment {
        items[currentItemIndexPath.item]
    }
    
    /// Returns a share item for the gallery item at given index path.
    /// - Parameter indexPath: An index path.
    /// - Returns: An item to share.
    open func shareItem(at indexPath: IndexPath) -> Any? {
        let item = items[indexPath.item]
        
        if let image = item.attachment(payloadType: ImageAttachmentPayload.self) {
            return image.imageURL
        } else if let video = item.attachment(payloadType: VideoAttachmentPayload.self) {
            return video.videoURL
        } else {
            return nil
        }
    }
    
    /// Returns cell reuse identifier for a gallery item at given index path.
    /// - Parameter indexPath: An index path.
    /// - Returns: A cell reuse identifier.
    open func cellReuseIdentifierForItem(at indexPath: IndexPath) -> String? {
        let item = items[indexPath.item]
        
        switch item.type {
        case .image:
            return _ImageAttachmentGalleryCell<ExtraData>.reuseId
        case .video:
            return _VideoAttachmentGalleryCell<ExtraData>.reuseId
        default:
            return nil
        }
    }
    
    /// Triggered when the current image is single tapped.
    open func handleSingleTapOnCell(at indexPath: IndexPath) {
        let areBarsHidden = bottomBarBottomConstraint?.constant != 0
        
        topBarTopConstraint?.constant = areBarsHidden ? 0 : -topBarView.frame.height
        bottomBarBottomConstraint?.constant = areBarsHidden ? 0 : bottomBarView.frame.height

        Animate {
            self.topBarView.alpha = areBarsHidden ? 1 : 0
            self.bottomBarView.alpha = areBarsHidden ? 1 : 0
            self.videoPlaybackBar.backgroundColor = areBarsHidden ? self.bottomBarView.backgroundColor : .clear
            self.view.layoutIfNeeded()
        }
    }
    
    /// Returns an image view to animate during interactive dismissing.
    open var imageViewToAnimateWhenDismissing: UIImageView? {
        let indexPath = currentItemIndexPath
        
        switch items[indexPath.item].type {
        case .image:
            let cell = attachmentsCollectionView
                .cellForItem(at: indexPath) as? _ImageAttachmentGalleryCell<ExtraData>
            return cell?.imageView
        case .video:
            let cell = attachmentsCollectionView
                .cellForItem(at: indexPath) as? _VideoAttachmentGalleryCell<ExtraData>
            return cell?.animationPlaceholderImageView
        default:
            return nil
        }
    }
}
