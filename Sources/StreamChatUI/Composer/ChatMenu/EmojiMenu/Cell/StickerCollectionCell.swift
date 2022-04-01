//
//  StickerCollectionCell.swift
//  StreamChatUI
//
//  Created by Parth Kshatriya on 01/04/22.
//

import Foundation
import Stipop
import StreamChat

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
