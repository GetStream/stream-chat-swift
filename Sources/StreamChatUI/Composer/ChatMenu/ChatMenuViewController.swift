//
//  ChatMenuViewController.swift
//  StreamChat
//
//  Created by Parth Kshatriya on 24/01/22.
//  Copyright © 2022 Stream.io Inc. All rights reserved.
//

import UIKit

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

    enum MenuType: Int {
        case media = 1
        case contact = 2
        case request = 3
        case send = 4
        case oneN = 5
        case nft = 6
        case redPacket = 7
        case dao = 8
    }

    // MARK: - Variables
    var didTapAction:((_ type: MenuType) -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    func setupUI() {
        imgMedia.image = Appearance.default.images.menuMedia
        imgContact.image = Appearance.default.images.menuContact
        imgRequest.image = Appearance.default.images.menuRequest
        imgSend.image = Appearance.default.images.menuSend
        img1n.image = Appearance.default.images.menu1n
        imgNft.image = Appearance.default.images.menuNft
        imgRedPacket.image = Appearance.default.images.menuRedPacket
        imgDao.image = Appearance.default.images.menuDao
    }

    @IBAction func menuTapAction(_ sender: UIButton) {
        didTapAction?(MenuType(rawValue: sender.tag) ?? .media)
    }

}
