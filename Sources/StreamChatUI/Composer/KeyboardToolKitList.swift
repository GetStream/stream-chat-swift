//
//  KeyboardToolKitList.swift
//  StreamChat
//
//  Created by Ajay Ghodadra on 11/11/21.
//  Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChatUI
import UIKit

struct KeyboardToolKit {
    func getList() -> [ToolKit] {
        return [ToolKit(image: Appearance.default.images.photoPicker, type: .photoPicker),
                ToolKit(image: Appearance.default.images.sendMoney, type: .sendOneDollar),
                ToolKit(image: Appearance.default.images.redPacket, type: .sendRedPacket),
                ToolKit(image: Appearance.default.images.nftGallery, type: .shareNFTGalllery),
                ToolKit(image: Appearance.default.images.nftGallery, type: .pay)
        ]
    }
}

struct ToolKit {

    // MARK: - Variables
    var image: UIImage?
    var type: ToolKitType

    // MARK: - enums
    enum ToolKitType {
        case photoPicker
        case sendOneDollar
        case sendRedPacket
        case shareNFTGalllery
        case pay
    }
}
