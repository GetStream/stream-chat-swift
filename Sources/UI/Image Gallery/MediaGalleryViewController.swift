//
//  MediaGalleryViewController.swift
//  StreamChat
//
//  Created by Alexey Bukhtin on 15/04/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import UIKit
import SnapKit
import SwiftyGif
import Nuke
import StreamChatClient

/// A media gallery to show images or gifs.
public class MediaGalleryViewController: UIViewController {
    fileprivate static let closeButtonWidth: CGFloat = 44
    
    /// A scroll view to dismiss the gellary by pull down.
    public let scrollView = UIScrollView(frame: .zero)
    /// A horizontal collection view with images.
    public let collectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())
    
    /// A page controler for several item.
    public lazy var pageControl: UIPageControl = {
        let pageControl = UIPageControl(frame: .zero)
        view.addSubview(pageControl)
        
        pageControl.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(CGFloat.messageEdgePadding)
            make.right.equalToSuperview().offset(-CGFloat.messageEdgePadding)
            make.bottom.equalToSuperview().offset(-CGFloat.messageInnerPadding)
        }
        
        return pageControl
    }()
    
    /// An image URL's.
    public var items: [MediaGalleryItem] = []
    public var selected: Int = 0
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        ImagePipeline.Configuration.isAnimatedImageDataEnabled = true
        view.backgroundColor = .chatSuperDarkGray
        setupScrollView()
        setupCollectionView()
        addCloseButton()
        
        if items.count > 1 {
            pageControl.pageIndicatorTintColor = .chatGray
            pageControl.numberOfPages = items.count
            pageControl.currentPage = selected
            pageControl.hidesForSinglePage = true
        }
    }
    
    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if selected > 0, selected < items.count {
            DispatchQueue.main.async { [weak self] in
                if let self = self {
                    self.collectionView.scrollToItem(at: .item(self.selected), at: .centeredHorizontally, animated: false)
                }
            }
        }
    }
    
    override public var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }
    
    private func addCloseButton() {
        let closeButton = UIButton(frame: .zero)
        closeButton.setImage(UIImage.Icons.close, for: .normal)
        closeButton.tintColor = .white
        closeButton.contentMode = .center
        closeButton.addTarget(self, action: #selector(close), for: .touchUpInside)
        closeButton.backgroundColor = UIColor.chatSuperDarkGray.withAlphaComponent(0.5)
        closeButton.layer.cornerRadius = MediaGalleryViewController.closeButtonWidth / 2
        view.addSubview(closeButton)
        
        closeButton.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.topMargin).offset(CGFloat.messageSpacing)
            make.right.equalToSuperview().offset(-CGFloat.messageSpacing)
            make.width.height.equalTo(MediaGalleryViewController.closeButtonWidth)
        }
    }
    
    @objc func close() {
        dismiss(animated: true)
    }
}

// MARK: - Scroll View

extension MediaGalleryViewController: UIScrollViewDelegate {
    
    private func setupScrollView() {
        view.addSubview(scrollView)
        scrollView.delegate = self
        scrollView.backgroundColor = .chatSuperDarkGray
        scrollView.alwaysBounceVertical = true
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.makeEdgesEqualToSafeAreaSuperview()
    }
    
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard scrollView == self.scrollView else {
            return
        }
        
        collectionView.alpha = 1 - scrollView.contentOffset.y / -120
        
        if scrollView.contentOffset.y < -100 {
            dismiss(animated: true)
        }
    }
    
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if scrollView == collectionView {
            pageControl.currentPage = Int(scrollView.contentOffset.x) / Int(scrollView.frame.width)
        }
    }
}

// MARK: - Collection View

extension MediaGalleryViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    
    private func setupCollectionView() {
        collectionView.backgroundColor = .chatSuperDarkGray
        collectionView.isPagingEnabled = true
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(cellType: MediaGalleryCollectionViewCell.self)
        scrollView.addSubview(collectionView)
        
        let itemSize = CGSize(width: UIScreen.main.bounds.width,
                              height: UIScreen.main.bounds.height - .safeAreaTop - .safeAreaBottom)
        
        collectionView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.size.equalTo(itemSize)
        }
        
        if let flow = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            flow.scrollDirection = .horizontal
            flow.itemSize = itemSize
            flow.minimumLineSpacing = 0
            flow.minimumInteritemSpacing = 0
        }
        
        collectionView.reloadData()
    }
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        items.count
    }
    
    public func collectionView(_ collectionView: UICollectionView,
                               cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(for: indexPath) as MediaGalleryCollectionViewCell
        
        cell.activityIndicatorView.startAnimating()
        
        if indexPath.item < items.count {
            let item = items[indexPath.item]
            cell.titleLabel.text = item.title
            
            cell.loadImage(item.url) { [weak self] in
                if $0 != nil, let badIndex = self?.items.firstIndex(of: item) {
                    self?.items.remove(at: badIndex)
                    self?.collectionView.reloadData()
                }
            }
            
            if let logoImage = item.logoImage {
                cell.addLogo(image: logoImage)
            }
        }
        
        return cell
    }
}

// MARK: - Cell

/// A media gallery item.
public struct MediaGalleryItem: Equatable {
    /// A title of the item.
    public let title: String?
    /// An URL.
    public let url: URL
    /// A copyright logo of the item.
    public let logoImage: UIImage?
    
    /// Init a media gallery item.
    ///
    /// - Parameters:
    ///   - title: a title.
    ///   - url: an URL.
    ///   - logoImage: a copyright logo of the item.
    public init?(title: String?, url: URL?, logoImage: UIImage? = nil) {
        guard let url = url else {
            return nil
        }
        
        self.title = title
        self.url = url
        self.logoImage = logoImage
    }
}

// MARK: - Cell

/// An image gallery collection view cell.
fileprivate final class MediaGalleryCollectionViewCell: UICollectionViewCell, UIScrollViewDelegate, Reusable {
    /// A scroll view for image view.
    fileprivate let scrollView = UIScrollView(frame: .zero)
    /// An image view.
    fileprivate let imageView = UIImageView(frame: .zero)
    /// An activity indicator.
    fileprivate let activityIndicatorView = UIActivityIndicatorView(style: .white)
    
    fileprivate lazy var titleLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.textColor = .chatGray
        label.textAlignment = .center
        label.font = .chatSmall
        addSubview(label)
        
        label.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(CGFloat.messageSpacing)
            let offset: CGFloat = MediaGalleryViewController.closeButtonWidth + 2 * .messageSpacing
            make.left.equalToSuperview().offset(offset)
            make.right.equalToSuperview().offset(-offset)
            make.height.equalTo(MediaGalleryViewController.closeButtonWidth)
        }
        
        return label
    }()
    
    private var logoImageView: UIImageView?
    private var imageTask: ImageTask?
    
    private lazy var doubleTap: UITapGestureRecognizer = {
        let tap = UITapGestureRecognizer(target: self, action: #selector(zoomByTap))
        tap.numberOfTapsRequired = 2
        tap.numberOfTouchesRequired = 1
        return tap
    }()
    
    override fileprivate init(frame: CGRect) {
        super.init(frame: frame)
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.alwaysBounceVertical = false
        scrollView.alwaysBounceHorizontal = false
        scrollView.flashScrollIndicators()
        scrollView.minimumZoomScale = 1
        scrollView.maximumZoomScale = 1
        scrollView.delegate = self
        scrollView.decelerationRate = .fast
        scrollView.makeEdgesEqualToSuperview(superview: self)
        scrollView.addGestureRecognizer(doubleTap)
        
        scrollView.addSubview(imageView)
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .white
        
        imageView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalToSuperview()
        }
        
        activityIndicatorView.makeCenterEqualToSuperview(superview: self)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override fileprivate func prepareForReuse() {
        reset()
        super.prepareForReuse()
    }
    
    func reset() {
        scrollView.maximumZoomScale = 1
        imageView.image = nil
        imageView.gifImage = nil
        imageView.contentMode = .scaleAspectFit
        activityIndicatorView.stopAnimating()
        imageTask?.cancel()
        imageTask = nil
        titleLabel.text = nil
        logoImageView?.removeFromSuperview()
    }
    
    fileprivate  func addLogo(image: UIImage) {
        let logoImageView = UIImageView(image: image)
        imageView.addSubview(logoImageView)
        logoImageView.snp.makeConstraints { $0.right.bottom.equalToSuperview().offset(CGFloat.messageCornerRadius / -2) }
        self.logoImageView = logoImageView
    }
    
    /// Loads the image by a given URL.
    fileprivate func loadImage(_ url: URL, completion: @escaping (_ error: Error?) -> Void) {
        imageTask?.cancel()
        activityIndicatorView.startAnimating()
        
        let modes = ImageLoadingOptions.ContentModes(success: .scaleAspectFit, failure: .center, placeholder: .center)
        let options = ImageLoadingOptions(failureImage: UIImage.Icons.close, contentModes: modes)
        
        let urlRequest = Client.config.attachmentImageURLRequestPrepare(url)
        let imageRequest = ImageRequest(urlRequest: urlRequest)
        imageTask = Nuke.loadImage(with: imageRequest, options: options, into: imageView) { [weak self] result in
            if let self = self {
                if self.imageView.frame.width > 0, self.imageView.frame.height > 0 {
                    self.parse(result, completion: completion)
                } else {
                    DispatchQueue.main.async { [weak self] in self?.parse(result, completion: completion) }
                }
            }
        }
    }
    
    private func parse(_ imageResult: Result<ImageResponse, ImagePipeline.Error>, completion: @escaping (_ error: Error?) -> Void) {
        activityIndicatorView.stopAnimating()
        
        guard let image = try? imageResult.get().image, image.size.width > 0 else {
            completion(imageResult.error)
            return
        }
        
        let scale = max(image.size.width / imageView.frame.width, image.size.height / imageView.frame.height)
        scrollView.maximumZoomScale = min(5, max(1, scale))
        
        if let animatedImageData = image.animatedImageData,
            let animatedImage = try? UIImage(gifData: animatedImageData, levelOfIntegrity: .highestNoFrameSkipping) {
            imageView.setGifImage(animatedImage)
            
        } else if scale < 1 {
            imageView.contentMode = .center
            scrollView.maximumZoomScale = 1 / scale
        }
        
        completion(nil)
    }
    
    fileprivate func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        imageView
    }
    
    @objc func zoomByTap() {
        if scrollView.maximumZoomScale > 1 {
            if scrollView.zoomScale == 1 {
                scrollView.setZoomScale(scrollView.maximumZoomScale, animated: true)
            } else {
                scrollView.setZoomScale(1, animated: true)
            }
        }
    }
}

// MARK: - Routing to the Gallery

extension UIViewController {
    
    /// Presents the image gallery with a given image URL's.
    ///
    /// - Parameters:
    ///   - items: a list of media gallery items.
    ///   - selectedIndex: a selected item by default.
    ///   - animated: present animated.
    public func showMediaGallery(with items: [MediaGalleryItem]?, selectedIndex: Int = 0, animated: Bool = true) {
        guard let items = items, !items.isEmpty else {
            return
        }
        
        let imageGalleryViewController = MediaGalleryViewController()
        imageGalleryViewController.items = items
        imageGalleryViewController.selected = selectedIndex
        present(imageGalleryViewController, animated: animated)
    }
}
