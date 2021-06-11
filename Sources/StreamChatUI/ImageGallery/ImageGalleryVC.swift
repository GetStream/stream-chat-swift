//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChat
import UIKit

/// View controller to showcase and slide through multiple images.
typealias ImageGalleryVC = _ImageGalleryVC<NoExtraData>

/// View controller to showcase and slide through multiple images.
open class _ImageGalleryVC<ExtraData: ExtraDataTypes>:
    _ViewController,
    UIGestureRecognizerDelegate,
    AppearanceProvider,
    UICollectionViewDataSource,
    UICollectionViewDelegate,
    UICollectionViewDelegateFlowLayout {
    /// Content to display.
    open var content: _ChatMessage<ExtraData>! {
        didSet {
            updateContentIfNeeded()
        }
    }
    
    /// Images to display (`content.imageAttachments`).
    open var images: [ChatMessageImageAttachment] = []
    
    /// Currently displayed image (indexed from 0).
    open var currentPage: Int = 0 {
        didSet {
            updateContentIfNeeded()
        }
    }

    /// Attachment to be displayed initially.
    open var initialAttachment: ChatMessageImageAttachment!
    
    /// Controller for handling the transition for dismissal
    open var transitionController: ZoomTransitionController!
    
    /// `DateComponentsFormatter` for showing when the message was sent.
    public private(set) lazy var dateFormatter: DateComponentsFormatter = {
        let df = DateComponentsFormatter()
        df.allowedUnits = [.minute]
        df.unitsStyle = .full
        return df
    }()
    
    /// `UICollectionViewFlowLayout` instance for `attachmentsCollectionView`.
    public private(set) lazy var attachmentsFlowLayout = UICollectionViewFlowLayout()
    
    /// `UICollectionView` instance to display attachments.
    public private(set) lazy var attachmentsCollectionView: UICollectionView = UICollectionView(
        frame: .zero,
        collectionViewLayout: attachmentsFlowLayout
    )
    .withoutAutoresizingMaskConstraints
    
    /// Bar view displayed at the top.
    public private(set) lazy var topBarView = UIView()
        .withoutAutoresizingMaskConstraints
    
    /// Label to show information about the user that sent the message.
    public private(set) lazy var userLabel = UILabel()
        .withoutAutoresizingMaskConstraints
    
    /// Label to show information about the date the message was sent at.
    public private(set) lazy var dateLabel = UILabel()
        .withoutAutoresizingMaskConstraints
    
    /// Bar view displayed at the bottom.
    public private(set) lazy var bottomBarView = UIView()
        .withoutAutoresizingMaskConstraints
    
    /// Label to show which photo is currently being displayed.
    public private(set) lazy var currentPhotoLabel = UILabel()
        .withoutAutoresizingMaskConstraints
    
    /// Button for closing this view controller.
    public private(set) lazy var closeButton = CloseButton()
    
    /// Button for sharing content.
    public private(set) lazy var shareButton = ShareButton()
    
    override open func setUpAppearance() {
        super.setUpAppearance()
        
        topBarView.backgroundColor = appearance.colorPalette.popoverBackground
        bottomBarView.backgroundColor = appearance.colorPalette.popoverBackground
        
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
        
        attachmentsCollectionView.contentInsetAdjustmentBehavior = .never
        attachmentsCollectionView.isPagingEnabled = true
        attachmentsCollectionView.alwaysBounceVertical = false
        attachmentsCollectionView.alwaysBounceHorizontal = true
        attachmentsCollectionView.dataSource = self
        attachmentsCollectionView.delegate = self
        attachmentsCollectionView.register(
            _ImageCollectionViewCell<ExtraData>.self,
            forCellWithReuseIdentifier: _ImageCollectionViewCell<ExtraData>.reuseId
        )
        
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
        topBarView.pin(anchors: [.leading, .trailing, .top], to: view)
        
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
        bottomBarView.pin(anchors: [.leading, .trailing, .bottom], to: view)
        
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
    }
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        
        attachmentsCollectionView.layoutIfNeeded()

        let initialPage = images
            .firstIndex(where: { $0.id == initialAttachment.id }) ?? 0
        currentPage = initialPage
        let contentOffset = CGPoint(
            x: attachmentsCollectionView.bounds.width * CGFloat(currentPage),
            y: attachmentsCollectionView.contentOffset.y
        )
        attachmentsCollectionView.setContentOffset(contentOffset, animated: false)
    }
    
    override open func updateContent() {
        super.updateContent()

        if content.author.isOnline {
            dateLabel.text = L10n.Message.Title.online
        } else {
            if
                let lastActive = content.author.lastActiveAt,
                let minutes = dateFormatter.string(from: lastActive, to: Date()) {
                dateLabel.text = L10n.Message.Title.seeMinutesAgo(minutes)
            } else {
                dateLabel.text = L10n.Message.Title.offline
            }
        }
        
        images = content.imageAttachments

        userLabel.text = content.author.name

        currentPhotoLabel.text = L10n.currentSelection(currentPage + 1, images.count)
        
        attachmentsCollectionView.reloadData()
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
        let imageURL = images[currentPage].payload.imageURL
        let activityViewController = UIActivityViewController(
            activityItems: [imageURL],
            applicationActivities: nil
        )
        present(activityViewController, animated: true)
    }
    
    /// Updates `currentPage`.
    open func updateCurrentPage() {
        if attachmentsCollectionView.bounds.width != 0 {
            currentPage = Int(attachmentsCollectionView.contentOffset.x + attachmentsCollectionView.bounds.width / 2) /
                Int(attachmentsCollectionView.bounds.width)
                
        } else {
            currentPage = 0
        }
    }
    
    open func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        images.count
    }
    
    open func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let image = images[indexPath.item]
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: _ImageCollectionViewCell<ExtraData>.reuseId,
            for: indexPath
        ) as! _ImageCollectionViewCell<ExtraData>
        cell.content = image
        cell.imageSingleTapped = { [weak self] in
            self?.imageSingleTapped()
        }
        return cell
    }
    
    /// Triggered when the current image is single tapped.
    open func imageSingleTapped() {
        topBarView.setAnimatedly(hidden: !topBarView.isHidden)
        bottomBarView.setAnimatedly(hidden: !bottomBarView.isHidden)
    }
    
    override open func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        attachmentsFlowLayout.invalidateLayout()
        super.viewWillTransition(to: size, with: coordinator)
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
            x: CGFloat(currentPage) * collectionView.bounds.width,
            y: proposedContentOffset.y
        )
    }
    
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        updateCurrentPage()
    }
}
