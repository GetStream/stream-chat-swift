//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

public extension Appearance {
    struct Images {
        // MARK: - General

        public var loadingIndicator: UIImage = UIImage(named: "loading_indicator", in: .streamChatUI)!
        public var close: UIImage = {
            if #available(iOS 13.0, *) {
                return UIImage(systemName: "xmark")!
            } else {
                return UIImage(named: "close", in: .streamChatUI)!
            }
        }()

        public var closeCircleTransparent: UIImage = UIImage(named: "close_circle_transparent", in: .streamChatUI)!
        public var discardAttachment: UIImage = UIImage(named: "close_circle_filled", in: .streamChatUI)!
        public var back: UIImage = UIImage(named: "icn_back", in: .streamChatUI)!
        public var onlyVisibleToCurrentUser = UIImage(named: "eye", in: .streamChatUI)!
        public var more = UIImage(named: "icn_more", in: .streamChatUI)!
        public var share: UIImage = {
            if #available(iOS 13.0, *) {
                return UIImage(systemName: "square.and.arrow.up")!
            } else {
                return UIImage(named: "share", in: .streamChatUI)!
            }
        }()

        public var message: UIImage = UIImage(named: "message", in: .streamChatUI)!
        public var commands: UIImage = UIImage(named: "bolt", in: .streamChatUI)!
        public var smallBolt: UIImage = UIImage(named: "bolt_small", in: .streamChatUI)!
        public var openAttachments: UIImage = UIImage(named: "clip", in: .streamChatUI)!
        public var shrinkInputArrow: UIImage = UIImage(named: "arrow_shrink_input", in: .streamChatUI)!
        public var sendArrow: UIImage = UIImage(named: "arrow_send", in: .streamChatUI)!
        public var scrollDownArrow: UIImage = UIImage(named: "arrow_down", in: .streamChatUI)!
        public var messageSent: UIImage = UIImage(named: "checkmark_grey", in: .streamChatUI)!
        public var whiteCheckmark: UIImage = UIImage(named: "checkmark_white", in: .streamChatUI)!
        public var readByAll: UIImage = UIImage(named: "checkmark_double", in: .streamChatUI)!
        public var confirmCheckmark: UIImage = UIImage(named: "checkmark_confirm", in: .streamChatUI)!
        public var bigConfirmCheckmark: UIImage = UIImage(named: "checkmark_confirm_big", in: .streamChatUI)!
        public var folder: UIImage = UIImage(named: "folder", in: .streamChatUI)!
        public var restart: UIImage = UIImage(named: "restart", in: .streamChatUI)!
        public var download: UIImage = {
            if #available(iOS 13.0, *) {
                return UIImage(systemName: "icloud.and.arrow.down")!
            } else {
                return UIImage(named: "download", in: .streamChatUI)!
            }
        }()

        // MARK: - Reactions

        public var reactionLoveSmall: UIImage = UIImage(named: "reaction_love_small", in: .streamChatUI)!
        public var reactionLoveBig: UIImage = UIImage(named: "reaction_love_big", in: .streamChatUI)!
        public var reactionLolSmall: UIImage = UIImage(named: "reaction_lol_small", in: .streamChatUI)!
        public var reactionLolBig: UIImage = UIImage(named: "reaction_lol_big", in: .streamChatUI)!
        public var reactionThumgsUpSmall: UIImage = UIImage(named: "reaction_thumbsup_small", in: .streamChatUI)!
        public var reactionThumgsUpBig: UIImage = UIImage(named: "reaction_thumbsup_big", in: .streamChatUI)!
        public var reactionThumgsDownSmall: UIImage = UIImage(named: "reaction_thumbsdown_small", in: .streamChatUI)!
        public var reactionThumgsDownBig: UIImage = UIImage(named: "reaction_thumbsdown_big", in: .streamChatUI)!
        public var reactionWutSmall: UIImage = UIImage(named: "reaction_wut_small", in: .streamChatUI)!
        public var reactionWutBig: UIImage = UIImage(named: "reaction_wut_big", in: .streamChatUI)!

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

        public var messageListErrorIndicator: UIImage = UIImage(named: "error_indicator", in: .streamChatUI)!

        // MARK: - FileIcons

        public var file7z: UIImage = UIImage(named: "7z", in: .streamChatUI)!
        public var fileCsv: UIImage = UIImage(named: "csv", in: .streamChatUI)!
        public var fileDoc: UIImage = UIImage(named: "doc", in: .streamChatUI)!
        public var fileDocx: UIImage = UIImage(named: "docx", in: .streamChatUI)!
        public var fileHtml: UIImage = UIImage(named: "html", in: .streamChatUI)!
        public var fileMd: UIImage = UIImage(named: "md", in: .streamChatUI)!
        public var fileMp3: UIImage = UIImage(named: "mp3", in: .streamChatUI)!
        public var fileOdt: UIImage = UIImage(named: "odt", in: .streamChatUI)!
        public var filePdf: UIImage = UIImage(named: "pdf", in: .streamChatUI)!
        public var filePpt: UIImage = UIImage(named: "ppt", in: .streamChatUI)!
        public var filePptx: UIImage = UIImage(named: "pptx", in: .streamChatUI)!
        public var fileRar: UIImage = UIImage(named: "rar", in: .streamChatUI)!
        public var fileRtf: UIImage = UIImage(named: "rtf", in: .streamChatUI)!
        public var fileTargz: UIImage = UIImage(named: "tar.gz", in: .streamChatUI)!
        public var fileTxt: UIImage = UIImage(named: "txt", in: .streamChatUI)!
        public var fileXls: UIImage = UIImage(named: "xls", in: .streamChatUI)!
        public var fileXlsx: UIImage = UIImage(named: "xlsx", in: .streamChatUI)!
        public var filezip: UIImage = UIImage(named: "zip", in: .streamChatUI)!
        public var fileFallback: UIImage = UIImage(named: "generic", in: .streamChatUI)!

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

        public var messageActionInlineReply: UIImage = UIImage(named: "icn_inline_reply", in: .streamChatUI)!
        public var messageActionThreadReply: UIImage = UIImage(named: "icn_thread_reply", in: .streamChatUI)!
        public var messageActionEdit: UIImage = UIImage(named: "icn_edit", in: .streamChatUI)!
        public var messageActionCopy: UIImage = UIImage(named: "icn_copy", in: .streamChatUI)!
        public var messageActionBlockUser: UIImage = UIImage(named: "icn_block_user", in: .streamChatUI)!
        public var messageActionMuteUser: UIImage = UIImage(named: "icn_mute_user", in: .streamChatUI)!
        public var messageActionDelete: UIImage = UIImage(named: "icn_delete", in: .streamChatUI)!
        public var messageActionResend: UIImage = UIImage(named: "icn_resend", in: .streamChatUI)!

        // MARK: - Placeholders

        public var userAvatarPlaceholder1: UIImage = UIImage(named: "pattern1", in: .streamChatUI)!
        public var userAvatarPlaceholder2: UIImage = UIImage(named: "pattern2", in: .streamChatUI)!
        public var userAvatarPlaceholder3: UIImage = UIImage(named: "pattern3", in: .streamChatUI)!
        public var userAvatarPlaceholder4: UIImage = UIImage(named: "pattern4", in: .streamChatUI)!
        public var userAvatarPlaceholder5: UIImage = UIImage(named: "pattern5", in: .streamChatUI)!

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
        
        public var camera: UIImage = UIImage(named: "camera", in: .streamChatUI)!
        public var bigPlay: UIImage = UIImage(named: "play_big", in: .streamChatUI)!
        
        public var play: UIImage = UIImage(named: "play", in: .streamChatUI)!
        public var pause: UIImage = UIImage(named: "pause", in: .streamChatUI)!

        // MARK: - CommandIcons

        public var commandBan: UIImage = UIImage(named: "command_ban", in: .streamChatUI)!
        public var commandFlag: UIImage = UIImage(named: "command_flag", in: .streamChatUI)!
        public var commandGiphy: UIImage = UIImage(named: "command_giphy", in: .streamChatUI)!
        public var commandImgur: UIImage = UIImage(named: "command_imgur", in: .streamChatUI)!
        public var commandMention: UIImage = UIImage(named: "command_mention", in: .streamChatUI)!
        public var commandMute: UIImage = UIImage(named: "command_mute", in: .streamChatUI)!
        public var commandUnban: UIImage = UIImage(named: "command_unban", in: .streamChatUI)!
        public var commandUnmute: UIImage = UIImage(named: "command_unmute", in: .streamChatUI)!
        public var commandFallback: UIImage = UIImage(named: "command_fallback", in: .streamChatUI)!

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
