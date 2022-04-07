//
//  EmojiContainerViewController.swift
//  StreamChatUI
//
//  Created by Parth Kshatriya on 30/03/22.
//

import UIKit
import StreamChat
import Combine
import Nuke
import Stipop
import GiphyUISDK

@available(iOS 13.0, *)
class EmojiContainerViewController: UIViewController {

    // MARK: Variables
    open private(set) lazy var giphy = GiphyGridController
        .init()

    open private(set) lazy var imgSticker = UIImageView
        .init()
        .withoutAutoresizingMaskConstraints

    open private(set) lazy var searchView = UISearchBar
        .init()
        .withoutAutoresizingMaskConstraints

    open private(set) lazy var loadingIndicator = UIActivityIndicatorView
        .init()
        .withoutAutoresizingMaskConstraints

    open private(set) lazy var lblStickerName = UILabel
        .init()
        .withoutAutoresizingMaskConstraints

    open private(set) lazy var lblStream = UILabel
        .init()
        .withoutAutoresizingMaskConstraints

    open private(set) lazy var btnDownload = UIButton
        .init()
        .withoutAutoresizingMaskConstraints

    open private(set) lazy var vStack = UIStackView
        .init()
        .withoutAutoresizingMaskConstraints

    open private(set) lazy var hStack = UIStackView
        .init()
        .withoutAutoresizingMaskConstraints

    open private(set) lazy var nameStack = UIStackView
        .init()
        .withoutAutoresizingMaskConstraints

    open private(set) lazy var gifView = UIView
        .init()
        .withoutAutoresizingMaskConstraints

    private var collectionEmoji: UICollectionView!

    var stickers = [Sticker]()
    var didSelectSticker: ((Sticker) -> ())?
    var menu: StickerMenu?
    private var visibleSticker: [Int]  {
        let walletStickerKey = UserdefaultKey.visibleSticker + StickerApi.userId
        return UserDefaults.standard.value(forKey: walletStickerKey) as? [Int] ?? []
    }

    init(with menu: StickerMenu) {
        super.init(nibName: nil, bundle: nil)
        self.menu = menu
        if menu.menuId == -2 {
            setupGifLayout()
        } else {
            setupSticker()
            loadStickerView()
        }
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    private func setupSticker() {
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.minimumLineSpacing = 0
        flowLayout.minimumInteritemSpacing = 0
        flowLayout.itemSize = .init(width: 40, height: 40)
        collectionEmoji = UICollectionView(frame: view.bounds, collectionViewLayout: flowLayout)
        collectionEmoji.register(StickerCollectionCell.self, forCellWithReuseIdentifier: "StickerCollectionCell")
        collectionEmoji.delegate = self
        collectionEmoji.dataSource = self
        collectionEmoji.translatesAutoresizingMaskIntoConstraints = false
        view.embed(collectionEmoji)
        collectionEmoji.backgroundColor = Appearance.default.colorPalette.stickerBg
        view.backgroundColor = Appearance.default.colorPalette.stickerBg
        
        imgSticker.clipsToBounds = true
        imgSticker.heightAnchor.constraint(equalToConstant: 70).isActive = true
        imgSticker.widthAnchor.constraint(equalToConstant: 70).isActive = true
        imgSticker.contentMode = .scaleAspectFit

        lblStickerName.text = menu?.name
        lblStickerName.numberOfLines = 2
        lblStickerName.font = UIFont.systemFont(ofSize: 18, weight: .regular)
        lblStickerName.translatesAutoresizingMaskIntoConstraints = false

        lblStream.text = "STREAM"
        lblStream.font = UIFont.systemFont(ofSize: 13, weight: .regular)
        lblStream.textColor = .white.withAlphaComponent(0.4)

        btnDownload.backgroundColor = UIColor(rgb: 0x767680).withAlphaComponent(0.25)
        btnDownload.setTitle("Download", for: .normal)
        btnDownload.addTarget(self, action: #selector(downloadSticker), for: .touchUpInside)
        btnDownload.setTitleColor(.white, for: .normal)
        btnDownload.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .medium)
        btnDownload.translatesAutoresizingMaskIntoConstraints = false
        btnDownload.widthAnchor.constraint(equalToConstant: self.view.bounds.width * 0.7).isActive = true
        btnDownload.heightAnchor.constraint(equalToConstant: 36).isActive = true
        btnDownload.cornerRadius = 18

        nameStack = UIStackView(arrangedSubviews: [lblStickerName, lblStream])
        nameStack.axis = .vertical
        nameStack.alignment = .leading
        nameStack.spacing = 2

        hStack = UIStackView(arrangedSubviews: [imgSticker, nameStack])
        hStack.axis = .horizontal
        hStack.alignment = .top
        vStack = UIStackView(arrangedSubviews: [hStack, btnDownload])
        vStack.axis = .vertical
        vStack.alignment = .leading
        vStack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(vStack)
        hStack.alignment = .center
        vStack.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        vStack.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -10).isActive = true
        hStack.isHidden = true
        hStack.spacing = 10
        vStack.spacing = 10
        collectionEmoji.isHidden = true
        vStack.widthAnchor.constraint(equalToConstant: self.view.bounds.width * 0.7).isActive = true
        view.layoutIfNeeded()
        imgSticker.layer.cornerRadius = 8

        view.addSubview(loadingIndicator)
        loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        loadingIndicator.style = .whiteLarge
        loadingIndicator.startAnimating()
        loadingIndicator.isHidden = true
    }

    private func setupGifLayout() {
        view.insertSubview(gifView, at: 0)
        gifView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        gifView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        gifView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        gifView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true

        giphy.clipsPreviewRenditionType = .preview
        addChild(giphy)
        gifView.addSubview(giphy.view)
        searchView.placeholder = "Search Gif"
        gifView.addSubview(searchView)
        searchView.pin(anchors: [.top, .leading, .trailing], to: gifView)
        searchView.searchBarStyle = .prominent
        searchView.delegate = self
        giphy.view.translatesAutoresizingMaskIntoConstraints = false
        giphy.view.leftAnchor.constraint(equalTo: gifView.safeLeftAnchor).isActive = true
        giphy.view.rightAnchor.constraint(equalTo: gifView.safeRightAnchor).isActive = true
        giphy.view.topAnchor.constraint(equalTo: searchView.bottomAnchor).isActive = true
        giphy.view.bottomAnchor.constraint(equalTo: gifView.safeBottomAnchor).isActive = true
        giphy.didMove(toParent: self)
        let trendingGIFs = GPHContent.trending(mediaType: .gif)
        giphy.content = trendingGIFs
        giphy.delegate = self
        giphy.update()
    }

    private func showNoStickerView() {
        imgSticker.isHidden = true
        btnDownload.isHidden = true
        lblStickerName.text = "No recent stickers."
        hStack.isHidden = false
        collectionEmoji.isHidden = true
    }

    private func configureDownloadOption() {
        Nuke.loadImage(with: menu?.image ?? "", into: imgSticker)
        lblStickerName.text = menu?.name ?? ""
    }

    @objc private func downloadSticker() {
        updateLoadingView(isHidden: false)
        StickerApiClient.downloadStickers(packageId: menu?.menuId ?? 0) { [weak self] in
            guard let `self` = self else { return }
            self.loadingIndicator.isHidden = true
            self.loadSticker(stickerId: "\(self.menu?.menuId ?? 0)")
            var visibleSticker = self.visibleSticker
            visibleSticker.append(self.menu?.menuId ?? 0)
            let walletStickerKey = UserdefaultKey.visibleSticker + StickerApi.userId
            UserDefaults.standard.set(visibleSticker, forKey: walletStickerKey)
            UserDefaults.standard.synchronize()
            self.collectionEmoji.isHidden = false
        }
    }

    private func loadStickerView() {
        guard let stickerId = menu?.menuId else {
            return
        }
        if stickerId == -1 {
            loadRecentSticker()
        } else if stickerId != -2 {
            if StickerMenu.getDefaultStickerIds().contains(stickerId) && !visibleSticker.contains(stickerId) {
                self.hStack.isHidden = false
                self.vStack.isHidden = false
                self.collectionEmoji.isHidden = true
                self.configureDownloadOption()
            } else {
                self.hStack.isHidden = true
                self.vStack.isHidden = true
                self.collectionEmoji.isHidden = false
                self.loadSticker(stickerId: "\(stickerId)")
            }
        }
    }

    private func loadSticker(stickerId: String) {
        // Retrieve from userdefault
        if let stickers = UserDefaults.standard.retrieve(object: [Sticker].self, fromKey: stickerId) {
            self.stickers = stickers
            self.collectionEmoji.reloadData()
        } else {
            StickerApiClient.stickerInfo(stickerId: stickerId) { [weak self] result in
                guard let `self` = self else { return }
                self.stickers = result.body?.package?.stickers ?? []
                // Cache sticker in userdefault
                UserDefaults.standard.save(customObject: self.stickers, inKey: stickerId)
                UserDefaults.standard.synchronize()
                self.collectionEmoji.reloadData()
            }
        }
    }

    private func recentStickers() {
        StickerApiClient.recentSticker { [weak self] result in
            guard let self = self else { return }
            self.stickers = result.body?.stickerList ?? []
            if self.stickers.isEmpty {
                self.showNoStickerView()
            }
            UserDefaults.standard.save(customObject: self.stickers, inKey: UserdefaultKey.recentSticker)
            UserDefaults.standard.synchronize()
            self.collectionEmoji.reloadData()
            self.collectionEmoji.isHidden = false
        }
    }

    private func loadRecentSticker() {
        vStack.isHidden = true
        hStack.isHidden = true
        // Retrieve from userdefault
        if let stickers = UserDefaults.standard.retrieve(object: [Sticker].self, fromKey: UserdefaultKey.recentSticker) {
            self.stickers = stickers
            collectionEmoji.reloadData()
            collectionEmoji.isHidden = false
            recentStickers()
        } else {
            recentStickers()
        }

    }

    private func updateLoadingView(isHidden: Bool) {
        collectionEmoji.isHidden = !isHidden
        loadingIndicator.isHidden = isHidden
        hStack.isHidden = !isHidden
        btnDownload.isHidden = !isHidden
    }

}

@available(iOS 13.0, *)
extension EmojiContainerViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return stickers.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "StickerCollectionCell", for: indexPath) as? StickerCollectionCell else {
            return UICollectionViewCell()
        }
        cell.configureSticker(sticker: stickers[indexPath.row])
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = collectionView.bounds.width / 4
        return .init(width: width, height: width)
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        NotificationCenter.default.post(name: .sendSticker, object: nil, userInfo: ["sticker": stickers[indexPath.row]])
        StickerApiClient.stickerSend(stickerId: stickers[indexPath.row].stickerID ?? 0, nil)
        HapticFeedbackGenerator.softHaptic()
    }

}

@available(iOS 13.0, *)
extension EmojiContainerViewController: GPHGridDelegate {
    func contentDidUpdate(resultCount: Int, error: Error?) { }

    func didSelectMedia(media: GPHMedia, cell: UICollectionViewCell) {
        NotificationCenter.default.post(name: .sendSticker, object: nil, userInfo: ["giphyUrl": media.url(rendition: .downsized, fileType: .gif)])
    }

    func didSelectMoreByYou(query: String) { }

    func didScroll(offset: CGFloat) { }
}

@available(iOS 13.0, *)
extension EmojiContainerViewController: UISearchBarDelegate {
    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
        var giphyPicker = GiphyViewController()
        giphyPicker.mediaTypeConfig = [.gifs]
        giphyPicker.delegate = self
        UIApplication.shared.keyWindow?.rootViewController?.present(giphyPicker, animated: true, completion: nil)
        return false
    }
}

@available(iOS 13.0, *)
extension EmojiContainerViewController: GiphyDelegate {
    func didDismiss(controller: GiphyViewController?) {
        debugPrint("deinit", controller)
    }

    func didSelectMedia(giphyViewController: GiphyViewController, media: GPHMedia) {
        giphyViewController.dismiss(animated: true, completion: nil)
        NotificationCenter.default.post(name: .sendSticker, object: nil, userInfo: ["giphyUrl": media.url(rendition: .downsized, fileType: .gif)])
    }
}
