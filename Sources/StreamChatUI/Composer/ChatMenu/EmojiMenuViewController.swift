//
//  EmojiMenuViewController.swift
//  StreamChatUI
//
//  Created by Parth Kshatriya on 25/03/22.
//

import UIKit
import SwiftUI
import StreamChat
import Combine
import Nuke

@available(iOS 13.0, *)
class EmojiMenuViewController: UIViewController {

    // MARK: Outlets
    @IBOutlet weak var collectionEmoji: UICollectionView!
    @IBOutlet weak var collectionMenu: UICollectionView!

    // MARK: Variables
    var viewModel: EmojiMenuViewModel?
    private var stickerCalls = Set<AnyCancellable>()
    var stickers = [Sticker]()
    var packageList = [PackageList]()
    var didSelectSticker: ((Sticker) -> ())?
    var didSelectMarketPlace: (() -> ())?

    //MARK: Override
    override func viewDidLoad() {
        super.viewDidLoad()
        StickerApi.mySticker()
            .sink { error in
                print(error)
            } receiveValue: { [weak self] result in
                guard let `self` = self else { return }
                self.packageList = result.body?.packageList ?? []
                self.collectionMenu.reloadData()
                guard let packageId = self.packageList.first?.packageID else { return }
                self.loadSticker(stickerId: "\(packageId)")
            }
            .store(in: &stickerCalls)
    }

    private func loadSticker(stickerId: String) {
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

    @IBAction func btnShowPackage(_ sender: Any) {
        didSelectMarketPlace?()
    }
}

@available(iOS 13.0, *)
extension EmojiMenuViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == collectionEmoji {
            return stickers.count
        } else {
            return packageList.count
        }
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView == collectionEmoji {
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "StickerCollectionCell", for: indexPath) as? StickerCollectionCell else {
                return UICollectionViewCell()
            }
            cell.configureSticker(sticker: stickers[indexPath.row])
            return cell
        } else {
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "StickerMenuCollectionCell", for: indexPath) as? StickerMenuCollectionCell else {
                return UICollectionViewCell()
            }
            cell.configureMenu(package: packageList[indexPath.row])
            return cell
        }
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if collectionView == collectionEmoji {
            let width = collectionView.bounds.width / 4
            return .init(width: width, height: width)
        } else {
            return .init(width: 30, height: 30)
        }
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionView == collectionEmoji {
            didSelectSticker?(stickers[indexPath.row])
            StickerApi.stickerSend(stickerId: stickers[indexPath.row].stickerID ?? 0)
                .sink { success in
                    print(success)
                } receiveValue: { result in
                    print(result)
                }
                .store(in: &stickerCalls)
        } else {
            loadSticker(stickerId: "\(packageList[indexPath.row].packageID ?? 0)")
        }
    }
    
}

class StickerCollectionCell: UICollectionViewCell {
    @IBOutlet weak var imgSticker: UIImageView!

    func configureSticker(sticker: Sticker) {
        if let stickerUrl = URL(string: sticker.stickerImg ?? "") {
            if stickerUrl.pathExtension == "gif" {
                imgSticker.setGifFromURL(stickerUrl)
            } else {
                Nuke.loadImage(with: stickerUrl, into: imgSticker)
            }
        } else {
            imgSticker = nil
        }
        imgSticker.backgroundColor = .clear
    }
}

class StickerMenuCollectionCell: UICollectionViewCell {
    @IBOutlet weak var imgMenu: UIImageView!

    func configureMenu(package: PackageList) {
        Nuke.loadImage(with: package.packageImg, into: imgMenu)
    }
}


enum EmojiType: CaseIterable {
    case activity
    case animalsNature
    case objects
    case shape
    case smileysPeople
    case travelPlaces
    case add

    func emojiImage() -> UIImage {
        switch self {
        case .activity:
            return Appearance.default.images.activity
        case .animalsNature:
            return Appearance.default.images.animals_Nature
        case .objects:
            return Appearance.default.images.objects
        case .shape:
            return Appearance.default.images.shape
        case .smileysPeople:
            return Appearance.default.images.smileys_People
        case .travelPlaces:
            return Appearance.default.images.travel_Places
        case .add:
            return Appearance.default.images.addIcon ?? .init()
        }
    }
}
