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
    
    /// A scroll view to dismiss the gellary by pull down.
    public let scrollView = UIScrollView(frame: .zero)
    /// A horizontal collection view with images.
    public let collectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())
    /// An image URL's.
    public var imageURLs: [URL] = []
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        ImagePipeline.Configuration.isAnimatedImageDataEnabled = true
        view.backgroundColor = .chatSuperDarkGray
        setupScrollView()
        setupCollectionView()
        addCloseButton()
    }
    
    public override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    private func addCloseButton() {
        let closeButton = UIButton(frame: .zero)
        closeButton.setImage(UIImage.Icons.close, for: .normal)
        closeButton.tintColor = .white
        closeButton.contentMode = .center
        closeButton.addTarget(self, action: #selector(close), for: .touchUpInside)
        view.addSubview(closeButton)
        
        closeButton.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(CGFloat.safeAreaTop)
            make.right.equalToSuperview()
            make.width.height.equalTo(44)
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
        collectionView.register(cellType: MediaGalleryImageCollectionViewCell.self)
        scrollView.addSubview(collectionView)
        
        collectionView.snp.makeConstraints {
            $0.edges.equalToSuperview()
            $0.size.equalToSuperview()
        }
        
        if let flow = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            flow.scrollDirection = .horizontal
            flow.itemSize = UIScreen.main.bounds.size
            flow.minimumLineSpacing = 0
            flow.minimumInteritemSpacing = 0
        }
        
        collectionView.reloadData()
    }
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return imageURLs.count
    }
    
    public func collectionView(_ collectionView: UICollectionView,
                               cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(for: indexPath) as MediaGalleryImageCollectionViewCell
        
        cell.activityIndicatorView.startAnimating()
        
        if indexPath.item < imageURLs.count {
            let url = imageURLs[indexPath.item]
            
            cell.loadImage(url) { [weak self] in
                if $0 != nil, let badIndex = self?.imageURLs.firstIndex(of: url) {
                    self?.imageURLs.remove(at: badIndex)
                    self?.collectionView.reloadData()
                }
            }
        }
        
        return cell
    }
}

// MARK: - Cell

/// An image gallery collection view cell.
public final class MediaGalleryImageCollectionViewCell: UICollectionViewCell, UIScrollViewDelegate, Reusable {
    /// A scroll view for image view.
    public let scrollView = UIScrollView(frame: .zero)
    /// An image view.
    public let imageView = UIImageView(frame: .zero)
    /// An activity indicator.
    public let activityIndicatorView = UIActivityIndicatorView(style: .white)
    
    private var imageTask: ImageTask?
    
    private lazy var doubleTap: UITapGestureRecognizer = {
        let tap = UITapGestureRecognizer(target: self, action: #selector(zoomByTap))
        tap.numberOfTapsRequired = 2
        tap.numberOfTouchesRequired = 1
        return tap
    }()
    
    public override init(frame: CGRect) {
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
        
        imageView.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.size.equalToSuperview()
        }
        
        addSubview(activityIndicatorView)
        activityIndicatorView.snp.makeConstraints { $0.center.equalToSuperview() }
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    public override func prepareForReuse() {
        scrollView.maximumZoomScale = 1
        imageView.image = nil
        imageView.contentMode = .scaleAspectFit
        activityIndicatorView.stopAnimating()
        imageTask?.cancel()
        imageTask = nil
    }
    
    /// Loads the image by a given URL.
    public func loadImage(_ url: URL, completion: @escaping (_ error: Error?) -> Void) {
        imageTask?.cancel()
        activityIndicatorView.startAnimating()
        
        let modes = ImageLoadingOptions.ContentModes(success: .scaleAspectFit, failure: .center, placeholder: .center)
        let options = ImageLoadingOptions(failureImage: UIImage.Icons.close, contentModes: modes)
        
        imageTask = Nuke.loadImage(with: url, options: options, into: imageView) { [weak self] imageResponse, error in
            if let self = self {
                self.activityIndicatorView.stopAnimating()
                
                if let image = imageResponse?.image, image.size.width > 0 {
                    self.scrollView.maximumZoomScale = min(5, max(1, max(image.size.width / self.imageView.frame.width,
                                                                         image.size.height / self.imageView.frame.height)))
                    
                    if let animatedImageData = image.animatedImageData,
                        let animatedImage = try? UIImage(gifData: animatedImageData) {
                        self.imageView.setGifImage(animatedImage)
                    }
                }
            }
            
            completion(error)
        }
    }
    
    public func viewForZooming(in scrollView: UIScrollView) -> UIView? {
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
    public func showImageGallery(with imageURLs: [URL]?, animated: Bool = true) {
        guard let imageURLs = imageURLs, !imageURLs.isEmpty else {
            return
        }
        
        let imageGalleryViewController = MediaGalleryViewController()
        imageGalleryViewController.imageURLs = imageURLs
        present(imageGalleryViewController, animated: animated)
    }
}
