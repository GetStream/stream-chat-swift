//
//  MediaGalleryViewController.swift
//  GetStreamChat
//
//  Created by Alexey Bukhtin on 15/04/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import UIKit
import SnapKit
import SwiftyGif
import Nuke

class MediaGalleryViewController: UIViewController {
    fileprivate static let closeButtonWidth: CGFloat = 44
    
    /// A scroll view to dismiss the gellary by pull down.
    public let scrollView = UIScrollView(frame: .zero)
    /// A horizontal collection view with images.
    public let collectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())
    /// An image URL's.
    public var items: [MediaGalleryItem] = []
    public var selected: Int = 0
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        ImagePipeline.Configuration.isAnimatedImageDataEnabled = true
        view.backgroundColor = .chatSuperDarkGray
        setupScrollView()
        setupCollectionView()
        addCloseButton()
        
        if selected > 0, selected < items.count {
            collectionView.scrollToItem(at: IndexPath(item: selected, section: 0), at: .centeredHorizontally, animated: false)
        }
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    private func addCloseButton() {
        let closeButton = UIButton(frame: .zero)
        closeButton.setImage(UIImage.Icons.close, for: .normal)
        closeButton.tintColor = .white
        closeButton.contentMode = .center
        closeButton.addTarget(self, action: #selector(close), for: .touchUpInside)
        closeButton.backgroundColor = UIColor.chatSuperDarkGray.withAlphaComponent(0.5)
        closeButton.layer.cornerRadius = .messageCornerRadius
        view.addSubview(closeButton)
        
        closeButton.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(CGFloat.messageSpacing)
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
        scrollView.snp.makeConstraints { $0.edges.equalToSuperview() }
        scrollView.contentSize = UIScreen.main.bounds.size
        scrollView.alwaysBounceVertical = true
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
    }
    
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        collectionView.alpha = CGFloat.maximum(0, 1 - scrollView.contentOffset.y / -150)
        
        if scrollView.contentOffset.y < -100 {
            dismiss(animated: true)
        }
    }
}

// MARK: - Collection View

extension MediaGalleryViewController: UICollectionViewDataSource {
    
    private func setupCollectionView() {
        collectionView.backgroundColor = .chatSuperDarkGray
        collectionView.isPagingEnabled = true
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.dataSource = self
        collectionView.register(cellType: MediaGalleryCollectionViewCell.self)
        scrollView.addSubview(collectionView)
        
        let itemSize = UIScreen.main.bounds.size
        
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
        return items.count
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
        }
        
        return cell
    }
}

// MARK: - Cell

public struct MediaGalleryItem: Equatable {
    public let title: String?
    public let url: URL
    
    init?(title: String?, url: URL?) {
        guard let url = url else {
            return nil
        }
        
        self.title = title
        self.url = url
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
    
    private var imageTask: ImageTask?
    
    private lazy var doubleTap: UITapGestureRecognizer = {
        let tap = UITapGestureRecognizer(target: self, action: #selector(zoomByTap))
        tap.numberOfTapsRequired = 2
        tap.numberOfTouchesRequired = 1
        return tap
    }()
    
    fileprivate override init(frame: CGRect) {
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
        addSubview(scrollView)
        scrollView.snp.makeConstraints { $0.edges.equalToSuperview() }
        scrollView.addGestureRecognizer(doubleTap)
        
        scrollView.addSubview(imageView)
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .white
        
        imageView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalToSuperview()
        }
        
        addSubview(activityIndicatorView)
        activityIndicatorView.snp.makeConstraints { $0.center.equalToSuperview() }
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    fileprivate override func prepareForReuse() {
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
    }
    
    /// Loads the image by a given URL.
    fileprivate func loadImage(_ url: URL, completion: @escaping (_ error: Error?) -> Void) {
        imageTask?.cancel()
        activityIndicatorView.startAnimating()
        
        let modes = ImageLoadingOptions.ContentModes(success: .scaleAspectFit, failure: .center, placeholder: .center)
        let options = ImageLoadingOptions(failureImage: UIImage.Icons.close, contentModes: modes)
        
        imageTask = Nuke.loadImage(with: url, options: options, into: imageView) { [weak self] imageResponse, error in
            if let self = self {
                if self.imageView.frame.width > 0, self.imageView.frame.height > 0 {
                    self.parse(imageResponse, error: error, completion: completion)
                } else {
                    DispatchQueue.main.async { self.parse(imageResponse, error: error, completion: completion) }
                }
            }
        }
    }
    
    private func parse(_ imageResponse: ImageResponse?, error: Error?, completion: @escaping (_ error: Error?) -> Void) {
        activityIndicatorView.stopAnimating()
        
        guard let image = imageResponse?.image, image.size.width > 0 else {
            completion(error)
            return
        }
        
        let scale = max(image.size.width / imageView.frame.width, image.size.height / imageView.frame.height)
        scrollView.maximumZoomScale = min(5, max(1, scale))
        
        if let animatedImageData = image.animatedImageData,
            let animatedImage = try? UIImage(gifData: animatedImageData) {
            imageView.setGifImage(animatedImage)
            
        } else if scale < 1 {
            imageView.contentMode = .center
            scrollView.maximumZoomScale = 1 / scale
        }
        
        completion(error)
    }
    
    fileprivate func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
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
