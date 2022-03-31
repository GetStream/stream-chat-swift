//
//  ChatMessageStickerBubble.swift
//  StreamChatUI
//
//  Created by Parth Kshatriya on 25/03/22.
//

import Foundation
import StreamChat
import Nuke
import AVKit
import Stipop

class ChatMessageStickerBubble: _TableViewCell {

    public private(set) var viewContainer: UIView!
    public private(set) var subContainer: UIView!
    public private(set) var sentThumbStickerView: SPUIStickerView!
    public private(set) var sentThumbGifView: UIImageView!
    var content: ChatMessage?
    var isSender = false

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none
        self.backgroundColor = .clear
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    private var cellWidth: CGFloat = 100.0

    func configureCell(isSender: Bool) {
        if let giphyUrl = content?.extraData.giphyUrl {
            cellWidth = 200
        } else {
            cellWidth = 100
        }
        if viewContainer != nil {
            viewContainer.removeFromSuperview()
        }
        viewContainer = UIView()
        viewContainer.translatesAutoresizingMaskIntoConstraints = false
        viewContainer.backgroundColor = .clear
        viewContainer.clipsToBounds = true
        contentView.addSubview(viewContainer)
        viewContainer.widthAnchor.constraint(equalToConstant: cellWidth).isActive = true
        NSLayoutConstraint.activate([
            viewContainer.topAnchor.constraint(equalTo: self.contentView.topAnchor, constant: 4),
            viewContainer.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor, constant: -4)
        ])
        if isSender {
            viewContainer.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor, constant: -8).isActive = true
        } else {
            viewContainer.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor, constant: 8).isActive = true
        }

        subContainer = UIView()
        subContainer.translatesAutoresizingMaskIntoConstraints = false
        subContainer.backgroundColor = Appearance.default.colorPalette.background6
        subContainer.layer.cornerRadius = 12
        subContainer.clipsToBounds = true
        viewContainer.addSubview(subContainer)
        NSLayoutConstraint.activate([
            subContainer.bottomAnchor.constraint(equalTo: viewContainer.bottomAnchor, constant: 0),
            subContainer.leadingAnchor.constraint(equalTo: viewContainer.leadingAnchor, constant: 0),
            subContainer.trailingAnchor.constraint(equalTo: viewContainer.trailingAnchor, constant: 0),
            subContainer.heightAnchor.constraint(equalToConstant: cellWidth),
        ])


        sentThumbStickerView = SPUIStickerView()
        sentThumbStickerView.backgroundColor = Appearance.default.colorPalette.background6
        sentThumbStickerView.transform = .mirrorY
        sentThumbStickerView.contentMode = .scaleAspectFill
        sentThumbStickerView.translatesAutoresizingMaskIntoConstraints = false
        sentThumbStickerView.clipsToBounds = true
        subContainer.addSubview(sentThumbStickerView)
        NSLayoutConstraint.activate([
            sentThumbStickerView.leadingAnchor.constraint(equalTo: subContainer.leadingAnchor, constant: 0),
            sentThumbStickerView.trailingAnchor.constraint(equalTo: subContainer.trailingAnchor, constant: 0),
            sentThumbStickerView.bottomAnchor.constraint(equalTo: subContainer.bottomAnchor, constant: 0),
            sentThumbStickerView.heightAnchor.constraint(equalToConstant: cellWidth)
        ])
        subContainer.transform = .mirrorY

        sentThumbGifView = UIImageView()
        sentThumbGifView.backgroundColor = Appearance.default.colorPalette.background6
        sentThumbGifView.transform = .mirrorY
        sentThumbGifView.contentMode = .scaleAspectFill
        sentThumbGifView.translatesAutoresizingMaskIntoConstraints = false
        sentThumbGifView.clipsToBounds = true
        subContainer.addSubview(sentThumbGifView)
        NSLayoutConstraint.activate([
            sentThumbGifView.leadingAnchor.constraint(equalTo: subContainer.leadingAnchor, constant: 0),
            sentThumbGifView.trailingAnchor.constraint(equalTo: subContainer.trailingAnchor, constant: 0),
            sentThumbGifView.bottomAnchor.constraint(equalTo: subContainer.bottomAnchor, constant: 0),
            sentThumbGifView.heightAnchor.constraint(equalToConstant: cellWidth)
        ])

        viewContainer.heightAnchor.constraint(equalToConstant: cellWidth).isActive = true
        viewContainer.backgroundColor = .clear
        if let giphyUrl = content?.extraData.giphyUrl, let gifUrl = URL(string: giphyUrl) {
            sentThumbGifView.setGifFromURL(gifUrl)
            sentThumbGifView.isHidden = false
            sentThumbStickerView.isHidden = true
        } else if let sticker = content?.extraData.stickerUrl {
            sentThumbStickerView.setSticker(sticker ?? "", sizeOptimized: true)
            sentThumbGifView.isHidden = true
            sentThumbStickerView.isHidden = false
        }
    }
}
