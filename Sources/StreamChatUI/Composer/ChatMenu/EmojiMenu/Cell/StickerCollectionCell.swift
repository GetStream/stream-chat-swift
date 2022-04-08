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
        embed(imgSticker,insets: .init(top: 15, leading: 15, bottom: 15, trailing: 15))
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    func configureSticker(sticker: Sticker) {
        imgSticker.setSticker(((sticker.stickerImg ?? "").addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""), sizeOptimized: true)
        imgSticker.backgroundColor = .clear
    }
}
