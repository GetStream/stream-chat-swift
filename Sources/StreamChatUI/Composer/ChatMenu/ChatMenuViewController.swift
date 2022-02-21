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

    override func viewDidLoad() {
        super.viewDidLoad()
        configureView(with: extraData)
        if #available(iOS 14.0.0, *) {
            self.children.forEach { vc in
                vc.removeFromParent()
            }
            var paymentSelection = ChatMenuView()
            paymentSelection.didTapAction = didTapAction
            let controller = UIHostingController(rootView: paymentSelection)
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

    @IBAction func menuTapAction(_ sender: UIButton) {
//        didTapAction?(MenuType(rawValue: sender.tag) ?? .media)
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
        }
    }
}

@available(iOS 14.0.0, *)
struct ChatMenuView: View {
    var gridItemLayout = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]

    // MARK: - Variables
    var didTapAction:((_ type: MenuType) -> Void)?

    var body: some View {
        ZStack {
            Color(UIColor(rgb: 0x1E1F1F))
            Spacer()
                .frame(height: 15)
            LazyVGrid(columns: gridItemLayout, spacing: 15) {
                ForEach(MenuType.allCases, id: \.self) { type  in
                    ZStack(alignment: .topLeading) {
                        VStack {
                            Image(uiImage: type.getImage())
                                .frame(width: 55, height: 55)
                                .background(Color(UIColor(rgb: 0x2E2E2E)))
                            Text(type.getTitle())
                                .font(.system(size: 14))
                                .foregroundColor(Color.white)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .lineLimit(2)
                        }
                    }
                    .onTapGesture {
                        didTapAction?(type)
                    }
                    .cornerRadius(4)
                    .padding(5)
                }
            }
            .padding(15)
        }
    }
}

@available(iOS 14.0.0, *)
struct ChatMenuViewProvider_Previews: PreviewProvider {
    static var previews: some View {
        ChatMenuView()
    }
}
