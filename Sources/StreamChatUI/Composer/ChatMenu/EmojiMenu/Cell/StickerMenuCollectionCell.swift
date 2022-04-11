//
//  StickerMenuCollectionCell.swift
//  StreamChatUI
//
//  Created by Parth Kshatriya on 01/04/22.
//

import Foundation
import StreamChat
import Nuke

class StickerMenuCollectionCell: UICollectionViewCell {

    @IBOutlet weak var imgMenu: UIImageView!
    @IBOutlet weak var bgView: UIView!

    func configureMenu(menu: StickerMenu, selectedId: Int) {
        if menu.menuId == -1 {
            imgMenu.image = (selectedId == -1 ? Appearance.default.images.clock : Appearance.default.images.clock?.noir)
        } else if menu.menuId == -2 {
            imgMenu.image = (selectedId == -2 ? Appearance.default.images.gif : Appearance.default.images.gif.noir)
        } else {
            Nuke.loadImage(with: menu.image, into: imgMenu) { [weak self] result in
                guard let `self` = self else { return }
                switch result {
                case .success(let imageResult):
                    self.imgMenu.image = (menu.menuId == selectedId) ? imageResult.image : imageResult.image.noir
                case .failure(let error):
                    debugPrint(error)
                }
            }
        }
        imgMenu.tintColor = .init(rgb: 0x343434)
        imgMenu.contentMode = .scaleAspectFill
        imgMenu.alpha = (menu.menuId == selectedId) ? 1 : 1
        bgView.backgroundColor = (menu.menuId == selectedId) ? .init(rgb: 0x0E0E0E) : .clear
        bgView.cornerRadius = bgView.bounds.width / 2
        imgMenu.cornerRadius = imgMenu.bounds.width / 2
    }
}
