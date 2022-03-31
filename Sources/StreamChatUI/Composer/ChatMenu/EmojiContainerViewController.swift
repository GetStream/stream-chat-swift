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
    private var collectionEmoji: UICollectionView!
    private var giphy: GiphyViewController!
    private var loadingIndicator: UIActivityIndicatorView!
    private var imgSticker: UIImageView!
    private var lblStickerName: UILabel!
    private var btnDownload: UIButton!
    private var vStack: UIStackView!
    private var hStack: UIStackView!
    private var gifView: UIView!
    private var stickerCalls = Set<AnyCancellable>()
    var stickers = [Sticker]()
    var didSelectSticker: ((Sticker) -> ())?
    var menu: StickerMenu?

    init(with menu: StickerMenu) {
        super.init(nibName: nil, bundle: nil)
        self.menu = menu
        self.setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    private func setup() {
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

        imgSticker = UIImageView()
        imgSticker.translatesAutoresizingMaskIntoConstraints = false
        imgSticker.clipsToBounds = true
        imgSticker.heightAnchor.constraint(equalToConstant: 70).isActive = true
        imgSticker.widthAnchor.constraint(equalToConstant: 70).isActive = true
        imgSticker.contentMode = .scaleAspectFit

        lblStickerName = UILabel()
        lblStickerName.text = menu?.name
        lblStickerName.font = UIFont.systemFont(ofSize: 15, weight: .regular)
        lblStickerName.translatesAutoresizingMaskIntoConstraints = false

        btnDownload = UIButton()
        btnDownload.backgroundColor = UIColor(rgb: 0x767680).withAlphaComponent(0.25)
        btnDownload.setTitle("Download", for: .normal)
        btnDownload.addTarget(self, action: #selector(downloadSticker), for: .touchUpInside)
        btnDownload.setTitleColor(.white, for: .normal)
        btnDownload.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .medium)
        btnDownload.translatesAutoresizingMaskIntoConstraints = false
        btnDownload.widthAnchor.constraint(equalToConstant: 111).isActive = true
        btnDownload.heightAnchor.constraint(equalToConstant: 44).isActive = true
        btnDownload.cornerRadius = 22

        vStack = UIStackView(arrangedSubviews: [lblStickerName, btnDownload])
        vStack.axis = .vertical

        hStack = UIStackView(arrangedSubviews: [imgSticker, vStack])
        hStack.axis = .horizontal
        vStack.alignment = .leading
        hStack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(hStack)
        hStack.alignment = .center
        hStack.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        hStack.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -15).isActive = true
        hStack.isHidden = true
        hStack.spacing = 10
        vStack.spacing = 10
        collectionEmoji.isHidden = true
        vStack.widthAnchor.constraint(equalToConstant: 130).isActive = true
        view.layoutIfNeeded()
        imgSticker.layer.cornerRadius = imgSticker.bounds.width / 2

        loadingIndicator = UIActivityIndicatorView()
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(loadingIndicator)
        loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        loadingIndicator.style = .whiteLarge
        loadingIndicator.startAnimating()
        loadingIndicator.isHidden = true
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
        StickerApi.downloadStickers(packageId: menu?.menuId ?? 0)
            .sink { [weak self] finish in
                guard let `self` = self else { return }
                self.updateLoadingView(isHidden: true)
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
                    guard let `self` = self else { return }
                    self.loadSticker(stickerId: "\(self.menu?.menuId ?? 0)")
                }
            } receiveValue: { _ in }
            .store(in: &stickerCalls)

    }

    override func viewDidLoad() {
        super.viewDidLoad()
        guard let stickerId = menu?.menuId else {
            return
        }
        if stickerId == -1 {
            loadRecentSticker()
        } else {
            loadSticker(stickerId: "\(stickerId)")
        }
    }

    deinit {
        print(#function)
    }

    func loadSticker(stickerId: String) {
        StickerApi.stickerInfo(id: stickerId)
            .sink { error in
                // TODO: Handle error state
                print(error)
            } receiveValue: { [weak self] result in
                guard let `self` = self else { return }
                self.stickers = result.body?.package?.stickers ?? []
                if result.body?.package?.isDownload == "N" {
                    self.hStack.isHidden = false
                    self.collectionEmoji.isHidden = true
                    self.configureDownloadOption()
                } else {
                    self.hStack.isHidden = true
                    self.collectionEmoji.isHidden = false
                }
                self.collectionEmoji.reloadData()
            }
            .store(in: &stickerCalls)
    }

    private func loadRecentSticker() {
        StickerApi.recentSticker()
            .sink { finish in
                print(finish)
            } receiveValue: { [weak self] result in
                guard let self = self else { return }
                self.stickers = result.body?.stickerList ?? []
                if self.stickers.isEmpty {
                    self.showNoStickerView()
                } else {

                }
                self.collectionEmoji.reloadData()
                self.collectionEmoji.isHidden = false
            }
            .store(in: &stickerCalls)
    }

    private func updateLoadingView(isHidden: Bool) {
        collectionEmoji.isHidden = !isHidden
        loadingIndicator.isHidden = isHidden
        hStack.isHidden = !isHidden
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
        StickerApi.stickerSend(stickerId: stickers[indexPath.row].stickerID ?? 0)
            .sink { success in
                print(success)
            } receiveValue: { result in
                print(result)
            }
            .store(in: &stickerCalls)
    }

}

class StickerCollectionCell: UICollectionViewCell {

    // MARK: Variables
    private var imgSticker: SPUIStickerView!

    override init(frame: CGRect) {
        super.init(frame: frame)
        imgSticker = SPUIStickerView()
        imgSticker.translatesAutoresizingMaskIntoConstraints = false
        embed(imgSticker,insets: .init(top: 10, leading: 10, bottom: 10, trailing: 10))
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)

    }

    func configureSticker(sticker: Sticker) {
        imgSticker.setSticker(sticker.stickerImg ?? "", sizeOptimized: true)
        imgSticker.backgroundColor = .clear
    }
}

class StickerMenuCollectionCell: UICollectionViewCell {

    @IBOutlet weak var imgMenu: UIImageView!
    @IBOutlet weak var bgView: UIView!

    func configureMenu(menu: StickerMenu, selectedId: Int) {
        if menu.menuId == -1 {
            imgMenu.image = Appearance.default.images.clock
        } else {
            Nuke.loadImage(with: menu.image, into: imgMenu)
        }
        imgMenu.tintColor = .init(rgb: 0x343434)
        imgMenu.contentMode = .scaleAspectFill
        imgMenu.alpha = (menu.menuId == selectedId) ? 1 : 1
        bgView.backgroundColor = (menu.menuId == selectedId) ? .init(rgb: 0x0E0E0E) : .clear
        bgView.cornerRadius = bgView.bounds.width / 2
        imgMenu.cornerRadius = imgMenu.bounds.width / 2
    }
}

