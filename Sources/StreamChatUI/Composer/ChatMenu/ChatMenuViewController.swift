//
//  ChatMenuViewController.swift
//  StreamChat
//
//  Created by Parth Kshatriya on 24/01/22.
//  Copyright © 2022 Stream.io Inc. All rights reserved.
//

import UIKit
import StreamChat
import SwiftUI

class ChatMenuViewController: UIViewController {
    // MARK: - Outlets
    @IBOutlet weak var imgMedia: UIImageView!
    @IBOutlet weak var imgContact: UIImageView!
    @IBOutlet weak var imgRequest: UIImageView!
    @IBOutlet weak var imgSend: UIImageView!
    @IBOutlet weak var img1n: UIImageView!
    @IBOutlet weak var imgNft: UIImageView!
    @IBOutlet weak var imgRedPacket: UIImageView!
    @IBOutlet weak var imgDao: UIImageView!
    @IBOutlet weak var lblDaoTitle: UILabel!

    // MARK: - Variables
    var didTapAction:((_ type: MenuType) -> Void)?
    var extraData = [String: RawJSON]()
    var menus = [MenuType]()

    override func viewDidLoad() {
        super.viewDidLoad()
        configureView(with: extraData)
        if #available(iOS 14.0.0, *) {
            self.children.forEach { vc in
                vc.removeFromParent()
            }
            if (extraData.signers.contains(ChatClient.shared.currentUserId ?? "")) {
                menus = MenuType.getDaoMenu()
            } else {
                menus = MenuType.getNonDaoMenu()
            }
            var chatMenuView = ChatMenuView(menus: menus)
            chatMenuView.didTapAction = didTapAction
            let controller = UIHostingController(rootView: chatMenuView)
            addChild(controller)
            controller.view.translatesAutoresizingMaskIntoConstraints = false
            self.view.addSubview(controller.view)
            controller.didMove(toParent: self)

            NSLayoutConstraint.activate([
                controller.view.widthAnchor.constraint(equalTo: self.view.widthAnchor),
                controller.view.heightAnchor.constraint(equalTo: self.view.heightAnchor),
                controller.view.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
                controller.view.centerYAnchor.constraint(equalTo: self.view.centerYAnchor)
            ])
        } else {
            // Fallback on earlier versions
        }
    }

    func setupUI(isDao: Bool = false) {
        imgMedia.image = Appearance.default.images.menuMedia
        if isDao {
            imgContact.image = Appearance.default.images.disburseFund
            lblDaoTitle.text = "Disburse Fund"
        } else {
            imgContact.image = Appearance.default.images.menuContact
            lblDaoTitle.text = "Contact"
        }
        imgRequest.image = Appearance.default.images.menuWeather
        imgSend.image = Appearance.default.images.menuCrypto
        img1n.image = Appearance.default.images.menu1n
        imgNft.image = Appearance.default.images.menuNft
        imgRedPacket.image = Appearance.default.images.menuRedPacket
        imgDao.image = Appearance.default.images.menuDao
    }

    func configureView(with data: [String: RawJSON]?) {
        if data?.daoGroupCreator?.isEmpty ?? false {
            setupUI(isDao: true)
        } else {
            setupUI(isDao: false)
        }
    }

}

enum MenuType: Int, CaseIterable {
    case media = 1
    case disburseFund = 2
    case weather = 3
    case crypto = 4
    case oneN = 5
    case nft = 6
    case redPacket = 7
    case dao = 8
    case contributeToFund = 9
    case polling = 10
    case contact = 11

    func getTitle() -> String {
        switch self {
        case .media:
            return "Media"
        case .disburseFund:
            return "Disburse Fund"
        case .weather:
            return "Weather"
        case .crypto:
            return "Crypto"
        case .oneN:
            return "1/N"
        case .nft:
            return "NFT"
        case .redPacket:
            return "Red Packet"
        case .dao:
            return "DAO"
        case .contributeToFund:
            return "Contribute to Fund"
        case .polling:
            return "Polling"
        case .contact:
            return "Contact"
        }
    }

    func getImage() -> UIImage {
        switch self {
        case .media:
            return Appearance.default.images.menuWeather
        case .disburseFund:
            return Appearance.default.images.disburseFund
        case .weather:
            return Appearance.default.images.menuContact
        case .crypto:
            return Appearance.default.images.menuCrypto
        case .oneN:
            return Appearance.default.images.menu1n
        case .nft:
            return Appearance.default.images.menuNft
        case .redPacket:
            return Appearance.default.images.menuRedPacket
        case .dao:
            return Appearance.default.images.menuDao
        case .contributeToFund:
            return Appearance.default.images.polling
        case .polling:
            return Appearance.default.images.contributeToFund
        case .contact:
            return Appearance.default.images.menuContact
        }
    }

    static func getDaoMenu() -> [MenuType] {
        return [.media, .disburseFund, .contributeToFund, .polling, .weather, .nft, .contact]
    }

    static func getNonDaoMenu() -> [MenuType] {
        return [.media, .contact, .weather, .crypto, .oneN, .nft, .redPacket, .dao]
    }
}

@available(iOS 14.0.0, *)
struct ChatMenuView: View {
    var gridItemLayout = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]
    var menus: [MenuType]
    var didTapAction:((_ type: MenuType) -> Void)?

    var body: some View {
        ZStack {
            Color(UIColor(rgb: 0x1E1F1F))
            VStack {
                LazyVGrid(columns: gridItemLayout, spacing: 0) {
                    ForEach(menus, id: \.self) { type  in
                        VStack(spacing: 5) {
                            Image(uiImage: type.getImage())
                                .frame(width: 55, height: 55)
                                .foregroundColor(Color(UIColor(rgb: 0x9A9A9A)))
                                .background(Color(UIColor(rgb: 0x2E2E2E)))
                                .cornerRadius(16)
                            Text(type.getTitle())
                                .multilineTextAlignment(.center)
                                .font(.system(size: 14))
                                .foregroundColor(Color(UIColor(rgb: 0x9A9A9A)))
                                .frame(maxWidth: .infinity, alignment: .center)
                                .fixedSize(horizontal: false, vertical: true)
                                .lineLimit(2)
                            Spacer()
                        }
                        .frame(height: 115)
                        .onTapGesture {
                            didTapAction?(type)
                        }
                    }
                }
                .padding(.horizontal, 25)
                .padding(.vertical, 15)
                .padding(.top, 30)
                Spacer()
            }
        }
    }
}
