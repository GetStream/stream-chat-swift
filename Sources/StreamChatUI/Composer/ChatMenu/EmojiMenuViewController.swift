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

    // MARK: Variables
    @IBOutlet weak var collectionEmoji: UICollectionView!
    var viewModel: EmojiMenuViewModel?
    private var stickerCalls = Set<AnyCancellable>()
    var stickers = [Sticker]()

    //MARK: Override
    override func viewDidLoad() {
        super.viewDidLoad()
        viewModel = EmojiMenuViewModel()
        viewModel?.getPackageInfo("445")

        viewModel?.$stickers
            .sink { [weak self ] stickers in
                guard let `self` = self else { return }
                self.stickers = stickers
                self.collectionEmoji.reloadData()
            }
            .store(in: &stickerCalls)


    }
//
//    override func viewWillAppear(_ animated: Bool) {
//        super.viewWillAppear(animated)
//        if #available(iOS 14.0.0, *) {
//            self.children.forEach { vc in
//                vc.removeFromParent()
//            }
//            var chatMenuView = EmojiMenuView()
//            let controller = UIHostingController(rootView: chatMenuView)
//            addChild(controller)
//            controller.view.translatesAutoresizingMaskIntoConstraints = false
//            controller.view.clipsToBounds = true
//            self.view.addSubview(controller.view)
//            controller.didMove(toParent: self)
//            self.view.clipsToBounds = true
//            NSLayoutConstraint.activate([
//                controller.view.widthAnchor.constraint(equalTo: self.view.widthAnchor),
//                controller.view.heightAnchor.constraint(equalTo: self.view.heightAnchor),
//                controller.view.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
//                controller.view.centerYAnchor.constraint(equalTo: self.view.centerYAnchor)
//            ])
//        } else {
//            // Fallback on earlier versions
//        }
//    }
}

@available(iOS 13.0, *)
extension EmojiMenuViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return stickers.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "StickerCollectionCell", for: indexPath) as? StickerCollectionCell else {
            return UICollectionViewCell()
        }
        if let stickerUrl = URL(string: stickers[indexPath.row].stickerImg ?? "") {
            if stickerUrl.pathExtension == "gif" {
                cell.imgSticker.setGifFromURL(stickerUrl)
            } else {
                Nuke.loadImage(with: stickerUrl, into: cell.imgSticker)
            }
        } else {
            cell.imgSticker = nil
        }
        cell.imgSticker.backgroundColor = .clear
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = collectionView.bounds.width / 4
        return .init(width: width, height: width)
    }

    
}

@available(iOS 14.0.0, *)
struct EmojiMenuView: View {
    let rows = [
        GridItem(.flexible())
    ]
    var viewModel = EmojiMenuViewModel()
    let emojiType = EmojiType.allCases

    let stickerColumns = [
        GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())
    ]
    
    var body: some View {
        ZStack {
            VStack{
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHGrid(rows: rows, alignment: .center) {
                        ForEach(emojiType, id: \.self) { type  in
                            ZStack(alignment: .topLeading) {
                                Button(action: {

                                }, label: {
                                    Image(uiImage: type.emojiImage())
                                        .foregroundColor(.white)
                                })
                            }
                            .frame(height: 30)
                            .padding(.horizontal, 15)
                        }
                    }
                }
                .frame(height: 30)
                Spacer()
                emojiView
                    .padding()
            }
        }
        .background(Color(UIColor(rgb: 0x1E1F1F)))
        .onAppear {
            viewModel.getPackageInfo("550")
        }
    }
}

@available(iOS 14.0.0, *)
extension EmojiMenuView {
    var emojiView: some View {
        return GeometryReader { proxy in
            ScrollView(.vertical, showsIndicators: false) {
                LazyVGrid(columns: stickerColumns) {
                    ForEach(viewModel.stickers, id: \.stickerID) { sticker  in
                        VStack {
                            if let imageUrl = URL(string: sticker.stickerImg ?? "") {
                                RemoteImageView(url: imageUrl)
                            }
                        }
                        .frame(width: proxy.size.width / 4, height: proxy.size.width / 4)
                    }
                }
            }
        }
    }
}

class StickerCollectionCell: UICollectionViewCell {
    @IBOutlet weak var imgSticker: UIImageView!
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
