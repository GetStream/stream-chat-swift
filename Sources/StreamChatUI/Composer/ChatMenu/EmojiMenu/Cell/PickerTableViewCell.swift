//
//  PickerTableViewCell.swift
//  StreamChatUI
//
//  Created by Parth Kshatriya on 01/04/22.
//

import Foundation
import StreamChat
import Nuke

class PickerTableViewCell: UITableViewCell {
    //MARK: Outlets
    @IBOutlet private weak var lblPackName: UILabel!
    @IBOutlet private weak var lblArtistName: UILabel!
    @IBOutlet private weak var imgPack: UIImageView!
    @IBOutlet private weak var btnDownload: UIButton!

    func configure(with package: PackageList, downloadedPackage: [Int]) {
        lblPackName.text = package.packageName ?? ""
        lblArtistName.text = package.artistName ?? ""
        Nuke.loadImage(with: URL(string: package.packageImg ?? ""), into: imgPack)
        selectionStyle = .none
        if !downloadedPackage.contains(package.packageID ?? 0) {
            btnDownload.setImage(Appearance.default.images.downloadSticker, for: .normal)
        } else {
            btnDownload.setImage(Appearance.default.images.downloadStickerFill, for: .normal)
        }
    }
}
