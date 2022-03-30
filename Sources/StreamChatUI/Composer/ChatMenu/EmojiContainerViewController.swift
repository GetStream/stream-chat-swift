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

@available(iOS 13.0, *)
class EmojiContainerViewController: UIViewController {

    // MARK: Variables
    private var collectionEmoji: UICollectionView!
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

    func loadSticker(stickerId: String) {
        StickerApi.stickerInfo(id: stickerId)
            .sink { error in
                // TODO: Handle error state
                print(error)
            } receiveValue: { [weak self] result in
                guard let `self` = self else { return }
                self.stickers = result.body?.package?.stickers ?? []
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
                self.collectionEmoji.reloadData()
            }
            .store(in: &stickerCalls)
    }

    private func updateLoadingView() {
        collectionEmoji.isHidden = self.stickers.count != 0
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
        imgMenu.alpha = (menu.menuId == selectedId) ? 1 : 0.5
        bgView.backgroundColor = (menu.menuId == selectedId) ? .init(rgb: 0x0E0E0E) : .clear
        bgView.cornerRadius = bgView.bounds.width / 2
        imgMenu.cornerRadius = bgView.bounds.width / 2
    }
}

