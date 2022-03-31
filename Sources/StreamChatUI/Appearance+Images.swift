//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

public extension Appearance {
    struct Images {
        /// A private internal function that will safely load an image from the bundle or return a circle image as backup
        /// - Parameter imageName: The required image name to load from the bundle
        /// - Returns: A UIImage that is either the correct image from the bundle or backup circular image
        private static func loadImageSafely(with imageName: String) -> UIImage {
            if let image = UIImage(named: imageName, in: .streamChatUI) {
                return image
            } else {
                log.error(
                    """
                    \(imageName) image has failed to load from the bundle please make sure it's included in your assets folder.
                    A default 'red' circle image has been added.
                    """
                )
                return UIImage.circleImage
            }
        }
        
        // MARK: - General

        static var systemPerson: UIImage?  {
            if #available(iOS 13.0, *) {
                return UIImage(systemName: "person")
            } else {
                return nil
            }
        }
        static var systemMagnifying: UIImage? {
            if #available(iOS 13.0, *) {
                return UIImage(systemName: "magnifyingglass")
            } else {
                return nil
            }
        }
        static var systemCheckMarkCircle: UIImage? {
            if #available(iOS 13.0, *) {
                return UIImage(systemName: "checkmark.circle.fill")
            } else {
                return nil
            }
        }
        public var loadingIndicator: UIImage = loadImageSafely(with: "loading_indicator")
        public var close: UIImage = {
            if #available(iOS 13.0, *) {
                return UIImage(systemName: "xmark")!
            } else {
                return loadImageSafely(with: "close")
            }
        }()
        public var socialMail: UIImage = loadImageSafely(with: "social_mail")
        public var socialInsta: UIImage = loadImageSafely(with: "social_insta")
        public var socialTikTok: UIImage = loadImageSafely(with: "social_tiktok")
        public var socialTwitter: UIImage = loadImageSafely(with: "social_twitter")
        public var userSelected: UIImage = loadImageSafely(with: "chat_UserStatus")
        public var closeBold: UIImage = loadImageSafely(with: "close")
        public var closeCircleTransparent: UIImage = loadImageSafely(with: "close_circle_transparent")
        public let closeCircle: UIImage = loadImageSafely(with: "close_circle")
        public var discardAttachment: UIImage = loadImageSafely(with: "close_circle_filled")
        public var back: UIImage = loadImageSafely(with: "icn_back")
        public var onlyVisibleToCurrentUser = loadImageSafely(with: "eye")
        public var more = loadImageSafely(with: "icn_more")
        public var moregreyCircle = loadImageSafely(with: "more-grey-circle")
        public var share: UIImage? = {
            if #available(iOS 13.0, *) {
                return UIImage(systemName: "square.and.arrow.up")
            } else {
                return nil
            }
        }()
        public var arrowUpRightSquare: UIImage? = {
            if #available(iOS 13.0, *) {
                return UIImage(systemName: "arrow.up.right.square")
            } else {
                return nil
            }
        }()
        public var personBadgePlus: UIImage? = {
            if #available(iOS 13.0, *) {
                return UIImage(systemName: "person.badge.plus")
            } else {
                return nil
            }
        }()
        public var search: UIImage? = {
            if #available(iOS 13.0, *) {
                return UIImage(systemName: "magnifyingglass")
            } else {
                return nil
            }
        }()
        public var qrCode: UIImage? = {
            if #available(iOS 13.0, *) {
                return UIImage(systemName: "qrcode")
            } else {
                return nil
            }
        }()
        public var qrCodeViewFinder: UIImage? = {
            if #available(iOS 13.0, *) {
                return UIImage(systemName: "qrcode.viewfinder")
            } else {
                return nil
            }
        }()
        public var mute: UIImage? = {
            if #available(iOS 13.0, *) {
                return UIImage(systemName: "speaker.slash")
            } else {
                return nil
            }
        }()
        public var unMute: UIImage? = {
            if #available(iOS 13.0, *) {
                return UIImage(systemName: "speaker")
            } else {
                return nil
            }
        }()
        public var photo: UIImage? = {
            if #available(iOS 13.0, *) {
                return UIImage(systemName: "photo")
            } else {
                return nil
            }
        }()
        public var trash: UIImage? = {
            if #available(iOS 13.0, *) {
                return UIImage(systemName: "trash")
            } else {
                return nil
            }
        }()
        public var rectangleArrowRight: UIImage? = {
            if #available(iOS 13.0, *) {
                return UIImage(systemName: "rectangle.portrait.and.arrow.right")
            } else {
                return nil
            }
        }()
        public var muteChannel: UIImage? = {
            if #available(iOS 13.0, *) {
                return UIImage(systemName: "speaker.slash.fill")?.withTintColor(.gray)
            } else {
                return nil
            }
        }()
        public lazy var exclamationMarkCircle: UIImage? = {
            if #available(iOS 13.0, *) {
                return UIImage(systemName: "exclamationmark.circle")
            } else {
                return nil
            }
        }()
        public lazy var starCircleFill: UIImage? = {
            if #available(iOS 13.0, *) {
                return UIImage(systemName: "star.circle.fill")
            } else {
                return nil
            }
        }()
        public lazy var bell: UIImage? = {
            if #available(iOS 13.0, *) {
                return UIImage(systemName: "bell")
            } else {
                return nil
            }
        }()
        public lazy var bellSlash: UIImage? = {
            if #available(iOS 13.0, *) {
                return UIImage(systemName: "bell.slash")
            } else {
                return nil
            }
        }()
        public lazy var crown: UIImage? = {
            if #available(iOS 13.0, *) {
                return UIImage(systemName: "crown")
            } else {
                return nil
            }
        }()
        public var commands: UIImage = loadImageSafely(with: "bolt")
        public var smallBolt: UIImage = loadImageSafely(with: "bolt_small")
        public var openAttachments: UIImage = loadImageSafely(with: "clip")
        public var shrinkInputArrow: UIImage = loadImageSafely(with: "arrow_shrink_input")
        public var sendArrow: UIImage = loadImageSafely(with: "arrow_send")
        public var moneyTransaction: UIImage = loadImageSafely(with: "money-transaction")
        public var moreRounded: UIImage = loadImageSafely(with: "more-rounded")
        public var moreVertical: UIImage = loadImageSafely(with: "more-vertical")
        public var scrollDownArrow: UIImage = loadImageSafely(with: "arrow_down")
        public var backCircle: UIImage = loadImageSafely(with: "back_circle")
        public var messageSent: UIImage = loadImageSafely(with: "checkmark_grey")
        public var whiteCheckmark: UIImage = loadImageSafely(with: "checkmark_white")
        public var readByAll: UIImage = loadImageSafely(with: "checkmark_double")
        public var confirmCheckmark: UIImage = loadImageSafely(with: "checkmark_confirm")
        public var bigConfirmCheckmark: UIImage = loadImageSafely(with: "checkmark_confirm_big")
        public var folder: UIImage = loadImageSafely(with: "folder")
        public var restart: UIImage = loadImageSafely(with: "restart")
        public var chatIcon: UIImage = loadImageSafely(with: "chatIcon")
        public var download: UIImage? = {
            if #available(iOS 13.0, *) {
                return UIImage(systemName: "icloud.and.arrow.down")!
            } else {
                return nil
            }
        }()
        public var senOneImage: UIImage? = {
            if #available(iOS 13.0, *) {
                return UIImage(systemName: "paperplane.fill")?.withTintColor(.white)
            } else {
                return nil
            }
        }()
        public var handPointUp: UIImage? = {
            if #available(iOS 13.0, *) {
                return UIImage(systemName: "hand.point.up")?.withTintColor(.white.withAlphaComponent(0.6))
            } else {
                return nil
            }
        }()
        public var menuRedPacket: UIImage? = {
            if #available(iOS 13.0, *) {
                return UIImage(systemName: "heart.rectangle")?.withRenderingMode(.alwaysTemplate)
            } else {
                return nil
            }
        }()

        public var menuGiftPacket: UIImage? = {
            if #available(iOS 13.0, *) {
                return UIImage(systemName: "gift")?.withRenderingMode(.alwaysTemplate)
            } else {
                return nil
            }
        }()

        // MARK: - Reactions

        public var reactionLoveSmall: UIImage = loadImageSafely(with: "reaction_love_small")
        public var reactionLoveBig: UIImage = loadImageSafely(with: "reaction_love_big")
        public var reactionLolSmall: UIImage = loadImageSafely(with: "reaction_lol_small")
        public var reactionLolBig: UIImage = loadImageSafely(with: "reaction_lol_big")
        public var reactionThumgsUpSmall: UIImage = loadImageSafely(with: "reaction_thumbsup_small")
        public var reactionThumgsUpBig: UIImage = loadImageSafely(with: "reaction_thumbsup_big")
        public var reactionThumgsDownSmall: UIImage = loadImageSafely(with: "reaction_thumbsdown_small")
        public var reactionThumgsDownBig: UIImage = loadImageSafely(with: "reaction_thumbsdown_big")
        public var reactionWutSmall: UIImage = loadImageSafely(with: "reaction_wut_small")
        public var reactionWutBig: UIImage = loadImageSafely(with: "reaction_wut_big")

        private var _availableReactions: [MessageReactionType: ChatMessageReactionAppearanceType]?
        public var availableReactions: [MessageReactionType: ChatMessageReactionAppearanceType] {
            get {
                _availableReactions ??
                    [
                        .init(rawValue: "love"): ChatMessageReactionAppearance(
                            smallIcon: reactionLoveSmall,
                            largeIcon: reactionLoveBig
                        ),
                        .init(rawValue: "haha"): ChatMessageReactionAppearance(
                            smallIcon: reactionLolSmall,
                            largeIcon: reactionLolBig
                        ),
                        .init(rawValue: "like"): ChatMessageReactionAppearance(
                            smallIcon: reactionThumgsUpSmall,
                            largeIcon: reactionThumgsUpBig
                        ),
                        .init(rawValue: "sad"): ChatMessageReactionAppearance(
                            smallIcon: reactionThumgsDownSmall,
                            largeIcon: reactionThumgsDownBig
                        ),
                        .init(rawValue: "wow"): ChatMessageReactionAppearance(
                            smallIcon: reactionWutSmall,
                            largeIcon: reactionWutBig
                        )
                    ]
            }
            set { _availableReactions = newValue }
        }

        // MARK: - MessageList

        public var messageListErrorIndicator: UIImage = loadImageSafely(with: "error_indicator")

        // MARK: - FileIcons

        public var file7z: UIImage = loadImageSafely(with: "7z")
        public var fileCsv: UIImage = loadImageSafely(with: "csv")
        public var fileDoc: UIImage = loadImageSafely(with: "doc")
        public var fileDocx: UIImage = loadImageSafely(with: "docx")
        public var fileHtml: UIImage = loadImageSafely(with: "html")
        public var fileMd: UIImage = loadImageSafely(with: "md")
        public var fileMp3: UIImage = loadImageSafely(with: "mp3")
        public var fileOdt: UIImage = loadImageSafely(with: "odt")
        public var filePdf: UIImage = loadImageSafely(with: "pdf")
        public var filePpt: UIImage = loadImageSafely(with: "ppt")
        public var filePptx: UIImage = loadImageSafely(with: "pptx")
        public var fileRar: UIImage = loadImageSafely(with: "rar")
        public var fileRtf: UIImage = loadImageSafely(with: "rtf")
        public var fileTargz: UIImage = loadImageSafely(with: "tar.gz")
        public var fileTxt: UIImage = loadImageSafely(with: "txt")
        public var fileXls: UIImage = loadImageSafely(with: "xls")
        public var fileXlsx: UIImage = loadImageSafely(with: "xlsx")
        public var filezip: UIImage = loadImageSafely(with: "zip")
        public var fileFallback: UIImage = loadImageSafely(with: "generic")

        private var _documentPreviews: [String: UIImage]?

        public var documentPreviews: [String: UIImage] {
            get { _documentPreviews ??
                [
                    "7z": file7z,
                    "csv": fileCsv,
                    "doc": fileDoc,
                    "docx": fileDocx,
                    "html": fileHtml,
                    "md": fileMd,
                    "mp3": fileMp3,
                    "odt": fileOdt,
                    "pdf": filePdf,
                    "ppt": filePpt,
                    "pptx": filePptx,
                    "rar": fileRar,
                    "rtf": fileRtf,
                    "tar.gz": fileTargz,
                    "txt": fileTxt,
                    "xls": fileXls,
                    "xlsx": fileXlsx,
                    "zip": filezip
                ]
            }
            set { _documentPreviews = newValue }
        }

        private var _fileIcons: [AttachmentFileType: UIImage]?
        public var fileIcons: [AttachmentFileType: UIImage] {
            get { _fileIcons ??
                [AttachmentFileType: UIImage](
                    uniqueKeysWithValues: AttachmentFileType.allCases.compactMap {
                        guard let icon = UIImage(named: $0.rawValue, in: .streamChatUI) else { return nil }
                        return ($0, icon)
                    }
                )
            }
            set { _fileIcons = newValue }
        }

        // MARK: - Message Actions

        public var messageActionInlineReply: UIImage = loadImageSafely(with: "reply") //icn_inline_reply
        public var messageActionThreadReply: UIImage = loadImageSafely(with: "icn_thread_reply")
        public var messageActionEdit: UIImage = loadImageSafely(with: "icn_edit")
        public var messageActionCopy: UIImage = loadImageSafely(with: "copy") //icn_copy
        public var messageActionTranslate: UIImage = loadImageSafely(with: "icn_translate")
        public var moreAction: UIImage = loadImageSafely(with: "icn_more")
        public var messageActionBlockUser: UIImage = loadImageSafely(with: "icn_block_user")
        public var messageActionMuteUser: UIImage = loadImageSafely(with: "icn_mute_user")
        public var messageActionDelete: UIImage = loadImageSafely(with: "icn_delete")
        public var messageActionResend: UIImage = loadImageSafely(with: "icn_resend")

        // MARK: - Placeholders

        public var userAvatarPlaceholder1: UIImage = loadImageSafely(with: "pattern1")
        public var userAvatarPlaceholder2: UIImage = loadImageSafely(with: "pattern2")
        public var userAvatarPlaceholder3: UIImage = loadImageSafely(with: "pattern3")
        public var userAvatarPlaceholder4: UIImage = loadImageSafely(with: "pattern4")
        public var userAvatarPlaceholder5: UIImage = loadImageSafely(with: "pattern5")
        public var videoAttachmentPlaceholder: UIImage = loadImageSafely(with: "placeholder")

        public var avatarPlaceholders: [UIImage] {
            [
                userAvatarPlaceholder1,
                userAvatarPlaceholder2,
                userAvatarPlaceholder3,
                userAvatarPlaceholder4,
                userAvatarPlaceholder5
            ]
        }

        // MARK: - FileAttachmentIcons

        private var _fileAttachmentActionIcons: [LocalAttachmentState?: UIImage]?
        public var fileAttachmentActionIcons: [LocalAttachmentState?: UIImage] {
            get { _fileAttachmentActionIcons ??
                [
                    .uploaded: download ?? UIImage(),
                    .uploadingFailed: restart,
                    nil: folder
                ]
            }
            set { _fileAttachmentActionIcons = newValue }
        }
        
        public var camera: UIImage = loadImageSafely(with: "camera")
        public var bigPlay: UIImage = loadImageSafely(with: "play_big")
        
        public var play: UIImage = loadImageSafely(with: "play")
        public var pause: UIImage = loadImageSafely(with: "pause")
        public var editCircle: UIImage = loadImageSafely(with: "editIcon")

        // MARK: - CommandIcons

        public var commandBan: UIImage = loadImageSafely(with: "command_ban")
        public var commandFlag: UIImage = loadImageSafely(with: "command_flag")
        public var commandGiphy: UIImage = loadImageSafely(with: "command_giphy")
        public var commandImgur: UIImage = loadImageSafely(with: "command_imgur")
        public var commandMention: UIImage = loadImageSafely(with: "command_mention")
        public var commandMute: UIImage = loadImageSafely(with: "command_mute")
        public var commandUnban: UIImage = loadImageSafely(with: "command_unban")
        public var commandUnmute: UIImage = loadImageSafely(with: "command_unmute")
        public var commandFallback: UIImage = loadImageSafely(with: "command_fallback")

        private var _commandIcons: [String: UIImage]?
        public var commandIcons: [String: UIImage] {
            get { _commandIcons ??
                [
                    "ban": commandBan,
                    "flag": commandFlag,
                    "giphy": commandGiphy,
                    "imgur": commandImgur,
                    "mention": commandMention,
                    "mute": commandMute,
                    "unban": commandUnban,
                    "unmute": commandUnmute
                ]
            }
            set { _commandIcons = newValue }
        }

        // MARK: - Keyboard toolkit
        public var sendMoney: UIImage = loadImageSafely(with: "send_money")
        public var nftGallery: UIImage = loadImageSafely(with: "nft_gallery")
        public var photoPicker: UIImage = loadImageSafely(with: "photo_picker")
        public var redPacket: UIImage = loadImageSafely(with: "red_packet")

        // MARK: - Gift cell
        public var starbucks: UIImage = loadImageSafely(with: "starbucks")
        public var cryptoSentThumb: UIImage = loadImageSafely(with: "crypto_sent_thumb")
        public var expiredPacketThumb: UIImage = loadImageSafely(with: "expiredPacket")
        public var redPacketExpired: UIImage = loadImageSafely(with: "redPacketExpired")
        public var redPacketThumb: UIImage = loadImageSafely(with: "redPacket")
        public var requestImg: UIImage = loadImageSafely(with: "requestImg")

        // MARK: - Wallet Keyboard
        public var add: UIImage = loadImageSafely(with: "add")
        public var remove: UIImage = loadImageSafely(with: "remove")
        public var closePopup: UIImage = loadImageSafely(with: "closePopup")
        public var addMenu: UIImage = loadImageSafely(with: "addMenu")
        public var hideMenu: UIImage = loadImageSafely(with: "hideMenu")

        //Menu
        public var menu1n: UIImage = loadImageSafely(with: "1:n")
        public var menuContact: UIImage = loadImageSafely(with: "contact")
        public var menuDao: UIImage = loadImageSafely(with: "dao")
        public var menuMedia: UIImage = loadImageSafely(with: "media")
        public var menuNft: UIImage = loadImageSafely(with: "nft")
        public var menuWeather: UIImage = loadImageSafely(with: "weather")
        public var menuCrypto: UIImage = loadImageSafely(with: "crypto")
        public var backMenuOption: UIImage = loadImageSafely(with: "back")
        public var emojiIcon: UIImage = loadImageSafely(with: "emoji")
        public var disburseFund: UIImage = loadImageSafely(with: "disburseFund")
        public var polling: UIImage = loadImageSafely(with: "polling")
        public var contributeToFund: UIImage = loadImageSafely(with: "fundIcon")

        // MARK: QR Code Option
        public var shareImageIcon: UIImage = loadImageSafely(with: "share_image_icon")
    }
}
