//
//  ChatMessageStickerBubble.swift
//  StreamChatUI
//
//  Created by Parth Kshatriya on 25/03/22.
//

import StreamChat
import Nuke
import AVKit
import Stipop
import GiphyUISDK

class ChatMessageStickerBubble: _TableViewCell {

    public private(set) var timestampLabel: UILabel?
    public var layoutOptions: ChatMessageLayoutOptions?
    public lazy var dateFormatter: DateFormatter = .makeDefault()
    public lazy var mainContainer = ContainerStackView(axis: .horizontal)
        .withoutAutoresizingMaskConstraints
    public lazy var subContainer = ContainerStackView(axis: .vertical)
        .withoutAutoresizingMaskConstraints
    public private(set) var sentThumbStickerView: SPUIStickerView!
    public private(set) var sentThumbGifView: UIImageView!
    public private(set) var authorAvatarView: ChatAvatarView?
    private var messageAuthorAvatarSize: CGSize { .init(width: 32, height: 32) }
    var content: ChatMessage?
    var chatChannel: ChatChannel?
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
            cellWidth = 150
        }
        if mainContainer != nil && subContainer != nil {
            mainContainer.removeFromSuperview()
            subContainer.removeFromSuperview()
            mainContainer.removeAllArrangedSubviews()
            subContainer.removeAllArrangedSubviews()
            timestampLabel = nil
            authorAvatarView = nil
        }
        mainContainer.addArrangedSubviews([createAvatarView(), subContainer])
        mainContainer.alignment = .bottom
        contentView.addSubview(mainContainer)
        NSLayoutConstraint.activate([
            mainContainer.topAnchor.constraint(equalTo: self.contentView.topAnchor, constant: 4),
            mainContainer.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor, constant: -4)
        ])
        if isSender {
            mainContainer.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor, constant: -8).isActive = true
            authorAvatarView?.isHidden = true
        } else {
            mainContainer.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor, constant: 8).isActive = true
            authorAvatarView?.isHidden = false
        }

        sentThumbStickerView = SPUIStickerView()
        sentThumbStickerView.heightAnchor.constraint(equalToConstant: cellWidth).isActive = true
        sentThumbStickerView.widthAnchor.constraint(equalToConstant: cellWidth).isActive = true
        sentThumbStickerView.backgroundColor = Appearance.default.colorPalette.background6
        sentThumbStickerView.transform = .mirrorY
        sentThumbStickerView.contentMode = .scaleAspectFill
        sentThumbStickerView.layer.cornerRadius = 12
        sentThumbStickerView.translatesAutoresizingMaskIntoConstraints = false
        sentThumbStickerView.clipsToBounds = true
        subContainer.transform = .mirrorY
        sentThumbGifView = GPHMediaView()
        sentThumbGifView.backgroundColor = Appearance.default.colorPalette.background6
        sentThumbGifView.transform = .mirrorY
        sentThumbGifView.contentMode = .scaleAspectFill
        sentThumbGifView.layer.cornerRadius = 12
        sentThumbGifView.translatesAutoresizingMaskIntoConstraints = false
        sentThumbGifView.heightAnchor.constraint(equalToConstant: cellWidth).isActive = true
        sentThumbGifView.widthAnchor.constraint(equalToConstant: cellWidth).isActive = true
        sentThumbGifView.clipsToBounds = true
        subContainer.addSubview(sentThumbGifView)
        subContainer.addArrangedSubviews([createTimestampLabel(), sentThumbStickerView, sentThumbGifView])
        subContainer.alignment = .leading
        timestampLabel?.widthAnchor.constraint(equalToConstant: cellWidth).isActive = true
        if let giphyUrl = content?.extraData.giphyUrl, let gifUrl = URL(string: giphyUrl) {
            sentThumbGifView.setGifFromURL(gifUrl)
            sentThumbGifView.isHidden = false
            sentThumbStickerView.isHidden = true
        } else if let sticker = content?.extraData.stickerUrl?.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
            sentThumbStickerView.setSticker(sticker, sizeOptimized: true)
            sentThumbGifView.isHidden = true
            sentThumbStickerView.isHidden = false
        }
        if let options = layoutOptions, let memberCount = chatChannel?.memberCount {
            // Hide Avatar view for one-way chat
            if memberCount <= 2 {
                authorAvatarView?.isHidden = true
            } else {
                authorAvatarView?.isHidden = false
                if !options.contains(.authorName) {
                    authorAvatarView?.imageView.image = nil
                } else {
                    Nuke.loadImage(with: content?.author.imageURL, into: authorAvatarView?.imageView ?? .init())
                }
            }
            timestampLabel?.isHidden = !options.contains(.timestamp)
        }
        if let createdAt = content?.createdAt,
            let authorName = content?.author.name?.trimStringBy(count: 15),
            let memberCount = chatChannel?.memberCount {
            var authorName = (memberCount <= 2) ? "" : authorName
            // Add extra white space in leading
            if !isSender {
                timestampLabel?.text = " " + authorName + "  " + dateFormatter.string(from: createdAt)
                timestampLabel?.textAlignment = .left
            } else {
                timestampLabel?.text = dateFormatter.string(from: createdAt)
                timestampLabel?.textAlignment = .right
            }
        } else {
            timestampLabel?.text = nil
        }
    }

    private func createAvatarView() -> ChatAvatarView {
        if authorAvatarView == nil {
            authorAvatarView = Components.default
                .avatarView
                .init()
                .withoutAutoresizingMaskConstraints
        }
        authorAvatarView?.widthAnchor.pin(equalToConstant: messageAuthorAvatarSize.width).isActive = true
        authorAvatarView?.heightAnchor.pin(equalToConstant: messageAuthorAvatarSize.height).isActive = true
        return authorAvatarView!
    }

    private func createTimestampLabel() -> UILabel {
        if timestampLabel == nil {
            timestampLabel = UILabel()
                .withAdjustingFontForContentSizeCategory
                .withBidirectionalLanguagesSupport
                .withoutAutoresizingMaskConstraints

            timestampLabel?.textColor = Appearance.default.colorPalette.subtitleText
            timestampLabel?.font = Appearance.default.fonts.footnote
            timestampLabel?.transform = .mirrorY
        }
        return timestampLabel!
    }
}
