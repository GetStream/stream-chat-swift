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

class ChatMessageStickerBubble: _TableViewCell {

    public private(set) var viewContainer: UIView!
    public private(set) var subContainer: UIView!
    public private(set) var sentThumbImageView: UIImageView!
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

    private var cellWidth: CGFloat {
        return 100
    }

    func configureCell(isSender: Bool) {
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

        sentThumbImageView = UIImageView()
        sentThumbImageView.backgroundColor = Appearance.default.colorPalette.background6
        sentThumbImageView.transform = .mirrorY
        sentThumbImageView.contentMode = .scaleAspectFill
        sentThumbImageView.translatesAutoresizingMaskIntoConstraints = false
        sentThumbImageView.clipsToBounds = true
        subContainer.addSubview(sentThumbImageView)
        NSLayoutConstraint.activate([
            sentThumbImageView.leadingAnchor.constraint(equalTo: subContainer.leadingAnchor, constant: 0),
            sentThumbImageView.trailingAnchor.constraint(equalTo: subContainer.trailingAnchor, constant: 0),
            sentThumbImageView.bottomAnchor.constraint(equalTo: subContainer.bottomAnchor, constant: 0),
            sentThumbImageView.heightAnchor.constraint(equalToConstant: cellWidth)
        ])
        subContainer.transform = .mirrorY
        viewContainer.heightAnchor.constraint(equalToConstant: cellWidth).isActive = true
        viewContainer.backgroundColor = .clear

        if let url = content?.extraData.stickerUrl, let imageAttachment = URL(string: url) {
            if imageAttachment.pathExtension == "gif" {
                sentThumbImageView.setGifFromURL(imageAttachment)
            } else {
                Nuke.loadImage(with: imageAttachment, into: sentThumbImageView)
            }
        } else {
            sentThumbImageView.image = nil
        }
    }
}
