//
// Copyright © 2022 Stream.io Inc. All rights reserved.
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

        public var loadingIndicator: UIImage = loadImageSafely(with: "loading_indicator")
        public var close: UIImage = {
            if #available(iOS 13.0, *) {
                return UIImage(systemName: "xmark")!
            } else {
                return loadImageSafely(with: "close")
            }
        }()

        public var closeCircleTransparent: UIImage = loadImageSafely(with: "close_circle_transparent")
        public var discardAttachment: UIImage = loadImageSafely(with: "close_circle_filled")
        public var back: UIImage = loadImageSafely(with: "icn_back")
        public var onlyVisibleToCurrentUser = loadImageSafely(with: "eye")
        public var more = loadImageSafely(with: "icn_more")
        public var share: UIImage = {
            if #available(iOS 13.0, *) {
                return UIImage(systemName: "square.and.arrow.up")!
            } else {
                return loadImageSafely(with: "share")
            }
        }()

        public var commands: UIImage = loadImageSafely(with: "bolt")
        public var smallBolt: UIImage = loadImageSafely(with: "bolt_small")
        public var openAttachments: UIImage = loadImageSafely(with: "clip")
        public var shrinkInputArrow: UIImage = loadImageSafely(with: "arrow_shrink_input")
        public var sendArrow: UIImage = loadImageSafely(with: "arrow_send")
        public var scrollDownArrow: UIImage = loadImageSafely(with: "arrow_down")
        public var whiteCheckmark: UIImage = loadImageSafely(with: "checkmark_white")
        public var confirmCheckmark: UIImage = loadImageSafely(with: "checkmark_confirm")
        public var bigConfirmCheckmark: UIImage = loadImageSafely(with: "checkmark_confirm_big")
        public var folder: UIImage = loadImageSafely(with: "folder")
        public var restart: UIImage = loadImageSafely(with: "restart")
        public var download: UIImage = {
            if #available(iOS 13.0, *) {
                return UIImage(systemName: "icloud.and.arrow.down")!
            } else {
                return loadImageSafely(with: "download")
            }
        }()

        // MARK: - Message Receipts
        
        public var messageDeliveryStatusSending: UIImage = loadImageSafely(with: "message_receipt_sending")
        public var messageDeliveryStatusSent: UIImage = loadImageSafely(with: "message_receipt_sent")
        public var messageDeliveryStatusRead: UIImage = loadImageSafely(with: "message_receipt_read")
        
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
                        "love": ChatMessageReactionAppearance(
                            smallIcon: reactionLoveSmall,
                            largeIcon: reactionLoveBig
                        ),
                        "haha": ChatMessageReactionAppearance(
                            smallIcon: reactionLolSmall,
                            largeIcon: reactionLolBig
                        ),
                        "like": ChatMessageReactionAppearance(
                            smallIcon: reactionThumgsUpSmall,
                            largeIcon: reactionThumgsUpBig
                        ),
                        "sad": ChatMessageReactionAppearance(
                            smallIcon: reactionThumgsDownSmall,
                            largeIcon: reactionThumgsDownBig
                        ),
                        "wow": ChatMessageReactionAppearance(
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

        public var messageActionInlineReply: UIImage = loadImageSafely(with: "icn_inline_reply")
        public var messageActionThreadReply: UIImage = loadImageSafely(with: "icn_thread_reply")
        public var messageActionEdit: UIImage = loadImageSafely(with: "icn_edit")
        public var messageActionCopy: UIImage = loadImageSafely(with: "icn_copy")
        public var messageActionBlockUser: UIImage = loadImageSafely(with: "icn_block_user")
        public var messageActionMuteUser: UIImage = loadImageSafely(with: "icn_mute_user")
        public var messageActionDelete: UIImage = loadImageSafely(with: "icn_delete")
        public var messageActionResend: UIImage = loadImageSafely(with: "icn_resend")
        public var messageActionFlag: UIImage = loadImageSafely(with: "icn_flag")

        // MARK: - Placeholders

        public var userAvatarPlaceholder1: UIImage = loadImageSafely(with: "pattern1")
        public var userAvatarPlaceholder2: UIImage = loadImageSafely(with: "pattern2")
        public var userAvatarPlaceholder3: UIImage = loadImageSafely(with: "pattern3")
        public var userAvatarPlaceholder4: UIImage = loadImageSafely(with: "pattern4")
        public var userAvatarPlaceholder5: UIImage = loadImageSafely(with: "pattern5")

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
                    .uploaded: download,
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
    }
}
