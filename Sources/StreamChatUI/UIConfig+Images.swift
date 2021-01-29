//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

public extension _UIConfig {
    struct Images {
        // MARK: - General

        public var loadingIndicator: UIImage = UIImage(named: "loading_indicator", in: .streamChatUI)!
        public var close: UIImage = UIImage(named: "close", in: .streamChatUI)!
        public var close1: UIImage = UIImage(named: "dismissInCircle", in: .streamChatUI)!
        public var back: UIImage = UIImage(named: "icn_back", in: .streamChatUI)!
        public var onlyVisibleToCurrentUser = UIImage(named: "eye", in: .streamChatUI)!

        // MARK: - ChannelList

        public var channelListReadByAll: UIImage = UIImage(named: "doubleCheckmark", in: .streamChatUI)!
        public var channelListSent: UIImage = UIImage(named: "checkmark", in: .streamChatUI)!
        public var newChat: UIImage = UIImage(named: "icn_new_chat", in: .streamChatUI)!

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

        // MARK: - Message Composer

        public var messageComposerCommand: UIImage = UIImage(named: "bolt", in: .streamChatUI)!
        public var messageComposerFileAttachment: UIImage = UIImage(named: "clip", in: .streamChatUI)!
        public var messageComposerAlsoSendToChannelCheck: UIImage = UIImage(named: "threadCheckmark", in: .streamChatUI)!
        public var messageComposerDiscardAttachment: UIImage = UIImage(named: "discardAttachment", in: .streamChatUI)!
        public var messageComposerShrinkInput: UIImage = UIImage(named: "shrinkInputArrow", in: .streamChatUI)!
        public var messageComposerReplyButton: UIImage = UIImage(named: "replyArrow", in: .streamChatUI)!
        public var messageComposerEditMessage: UIImage = UIImage(named: "editPencil", in: .streamChatUI)!
        public var messageComposerSendMessage: UIImage = UIImage(named: "sendMessageArrow", in: .streamChatUI)!
        public var messageComposerSendEditedMessage: UIImage = UIImage(named: "editMessageCheckmark", in: .streamChatUI)!
        public var messageComposerDownloadAndOpen: UIImage = UIImage(named: "download_and_open", in: .streamChatUI)!
        public var messageComposerRestartUpload: UIImage = UIImage(named: "restart", in: .streamChatUI)!
        public var messageComposerFileUploaded: UIImage = UIImage(named: "uploaded", in: .streamChatUI)!

        private var _fileAttachmentActionIcons: [LocalAttachmentState?: UIImage]?
        public var fileAttachmentActionIcons: [LocalAttachmentState?: UIImage] {
            get { _fileAttachmentActionIcons ??
                [
                    .uploaded: messageComposerRestartUpload,
                    .uploadingFailed: messageComposerRestartUpload,
                    nil: messageComposerDownloadAndOpen
                ]
            }
            set { _fileAttachmentActionIcons = newValue }
        }

        // MARK: - Message Composer Suggestions

        public var messageComposerCommandsBan: UIImage = UIImage(named: "command_ban", in: .streamChatUI)!
        public var messageComposerCommandsFlag: UIImage = UIImage(named: "command_flag", in: .streamChatUI)!
        public var messageComposerCommandsGiphy: UIImage = UIImage(named: "command_giphy", in: .streamChatUI)!
        public var messageComposerCommandsImgur: UIImage = UIImage(named: "command_imgur", in: .streamChatUI)!
        public var messageComposerCommandsMention: UIImage = UIImage(named: "command_mention", in: .streamChatUI)!
        public var messageComposerCommandsMute: UIImage = UIImage(named: "command_mute", in: .streamChatUI)!
        public var messageComposerCommandsUnban: UIImage = UIImage(named: "command_unban", in: .streamChatUI)!
        public var messageComposerCommandsUnmute: UIImage = UIImage(named: "command_unmute", in: .streamChatUI)!
        public var messageComposerCommandFallback: UIImage = UIImage(named: "command_fallback", in: .streamChatUI)!
        public var messageComposerSuggestionsMention: UIImage = UIImage(named: "command_mention", in: .streamChatUI)!
        public var messageComposerCommandButton: UIImage? = UIImage(named: "icon_giphy", in: .streamChatUI)

        private var _commandIcons: [String: UIImage]?

        public var commandIcons: [String: UIImage] {
            get { _commandIcons ??
                [
                    "ban": messageComposerCommandsBan,
                    "flag": messageComposerCommandsFlag,
                    "giphy": messageComposerCommandsGiphy,
                    "imgur": messageComposerCommandsImgur,
                    "mention": messageComposerCommandsMention,
                    "mute": messageComposerCommandsMute,
                    "unban": messageComposerCommandsUnban,
                    "unmute": messageComposerCommandsUnmute
                ]
            }
            set { _commandIcons = newValue }
        }
    }
}
