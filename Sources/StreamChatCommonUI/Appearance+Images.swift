//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

public extension Appearance {
    struct Images {
        /// A private internal function that will safely load an image from the bundle or return a circle image as backup
        /// - Parameter imageName: The required image name to load from the bundle
        /// - Returns: A UIImage that is either the correct image from the bundle or backup circular image
        private static func loadImageSafely(with imageName: String) -> UIImage {
            if let bundle, let image = UIImage(named: imageName, in: bundle) {
                return image
            }
            if let image = UIImage(named: imageName, in: .streamChatCommonUI) {
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

        private static func loadSafely(
            systemName: String,
            config: UIImage.SymbolConfiguration? = nil,
            assetsFallback: String? = nil
        ) -> UIImage {
            if let systemImage = UIImage(systemName: systemName, withConfiguration: config) {
                return systemImage
            }
            if let assetsFallback {
                return loadImageSafely(with: assetsFallback)
            }
            return UIImage.circleImage
        }

        // MARK: - General

        public var loadingIndicator: UIImage = loadImageSafely(with: "loading_indicator")
        public var close: UIImage = loadSafely(systemName: "xmark", assetsFallback: "close")
        public var discard: UIImage = loadImageSafely(with: "close")
        public var link: UIImage = loadImageSafely(with: "link")

        public var closeCircleTransparent: UIImage = loadImageSafely(with: "close_circle_transparent")
        public var discardAttachment: UIImage = loadImageSafely(with: "close_circle_filled")
        public var back: UIImage = loadImageSafely(with: "icn_back")
        public var onlyVisibleToCurrentUser = loadImageSafely(with: "eye")
        public var more = loadImageSafely(with: "icn_more")
        public var share: UIImage = loadSafely(systemName: "square.and.arrow.up", assetsFallback: "share")

        public var commands: UIImage = loadImageSafely(with: "bolt")
        public var smallBolt: UIImage = loadImageSafely(with: "bolt_small")
        public var openAttachments: UIImage = loadImageSafely(with: "clip")
        public var shrinkInputArrow: UIImage = loadImageSafely(with: "arrow_shrink_input")
        public var sendArrow: UIImage = loadImageSafely(with: "arrow_send").imageFlippedForRightToLeftLayoutDirection()
        public var scrollDownArrow: UIImage = loadImageSafely(with: "arrow_down")
        public var whiteCheckmark: UIImage = loadImageSafely(with: "checkmark_white")
        public var confirmCheckmark: UIImage = loadImageSafely(with: "checkmark_confirm")
        public var bigConfirmCheckmark: UIImage = loadImageSafely(with: "checkmark_confirm_big")
        public var folder: UIImage = loadImageSafely(with: "folder")
        public var restart: UIImage = loadImageSafely(with: "restart")
        public var emptyChannelListMessageBubble: UIImage = loadImageSafely(with: "empty_channel_list_message_bubble")
        public var emptySearch: UIImage = loadImageSafely(with: "empty_search")
        public var download: UIImage = loadSafely(systemName: "icloud.and.arrow.down", assetsFallback: "download")
        
        // MARK: - Recording

        public var mic: UIImage = loadSafely(systemName: "mic", assetsFallback: "mic")
        public var lock: UIImage = loadSafely(systemName: "lock", assetsFallback: "lock")
        public var chevronLeft: UIImage = loadSafely(systemName: "chevron.left", assetsFallback: "chevron.left").imageFlippedForRightToLeftLayoutDirection()
        public var chevronRight: UIImage = loadSafely(systemName: "chevron.right", assetsFallback: "chevron.right").imageFlippedForRightToLeftLayoutDirection()
        public var chevronUp: UIImage = loadSafely(systemName: "chevron.up", assetsFallback: "chevron.up")
        public var trash: UIImage = loadSafely(systemName: "trash", assetsFallback: "trash")
        public var stop: UIImage = loadSafely(systemName: "stop.circle", assetsFallback: "")
        public var playFill: UIImage = loadSafely(systemName: "play.fill", assetsFallback: "play.fill").imageFlippedForRightToLeftLayoutDirection()
        public var pauseFill: UIImage = loadSafely(systemName: "pause.fill", assetsFallback: "pause.fill")
        public var recordingPlay: UIImage = loadSafely(systemName: "play", assetsFallback: "play_big").imageFlippedForRightToLeftLayoutDirection()
        public var recordingPause: UIImage = loadSafely(systemName: "pause", assetsFallback: "pause.fill")
        public var rateButtonPillBackground: UIImage = loadImageSafely(with: "pill")
        public var sliderThumb: UIImage = loadImageSafely(with: "sliderThumb")

        // MARK: - Message Receipts

        public var messageDeliveryStatusSending: UIImage = loadImageSafely(with: "message_receipt_sending")
        public var messageDeliveryStatusSent: UIImage = loadImageSafely(with: "message_receipt_sent")
        public var messageDeliveryStatusRead: UIImage = loadImageSafely(with: "message_receipt_read")
        public var messageDeliveryStatusFailed: UIImage = loadImageSafely(with: "message_receipt_failed")

        // MARK: - Polls

        public var pollReorderIcon: UIImage = loadSafely(systemName: "line.3.horizontal", assetsFallback: "line.3.horizontal")
        public var pollCreationSendIcon: UIImage = loadSafely(systemName: "paperplane.fill", assetsFallback: "paperplane.fill")
        public var pollWinner: UIImage = loadSafely(systemName: "trophy", assetsFallback: "trophy")
        public var pollVoteCheckmarkActive: UIImage = .checkmark
        public var pollVoteCheckmarkInactive: UIImage = UIImage(
            systemName: "circle",
            withConfiguration: UIImage.SymbolConfiguration(weight: .thin)
        ) ?? loadSafely(systemName: "circle", assetsFallback: "checkmark_confirm")

        // MARK: - Threads

        public var threadIcon: UIImage = loadSafely(systemName: "text.bubble", assetsFallback: "text_bubble")

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

        /// The reactions appearance used to display reactions in the message list.
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

        private var _availableReactions: [MessageReactionType: ChatMessageReactionAppearanceType]?

        /// The reactions emoji unicode rendered in the push notifications.
        public var availableReactionPushEmojis: [MessageReactionType: String] {
            get {
                _availableReactionPushEmojis ??
                    [
                        "love": "❤️",
                        "haha": "😂",
                        "like": "👍",
                        "sad": "👎",
                        "wow": "😮"
                    ]
            }
            set { _availableReactionPushEmojis = newValue }
        }

        private var _availableReactionPushEmojis: [MessageReactionType: String]?
        
        public var availableEmojis: [String] = [
            "😀", "😃", "😄", "😁", "😆", "😅", "🤣", "😂", "🙂", "🙃",
            "😉", "😊", "😇", "🥰", "😍", "🤩", "😘", "😗", "😚", "😙",
            "😋", "😛", "😜", "🤪", "😝", "🤑", "🤗", "🤭", "🤫", "🤔",
            "🤐", "🤨", "😐", "😑", "😶", "😶‍🌫️", "😏", "😒", "🙄", "😬",
            "🤥", "😌", "😔", "😪", "🤤", "😴", "😷", "🤒", "🤕", "🤢",
            "🤮", "🤧", "🥵", "🥶", "🥴", "😵‍💫", "🤯", "🤠", "🥳", "😎",
            "🤓", "🧐", "😕", "😟", "🙁", "☹️", "😮", "😯", "😲", "😳",
            "🥺", "😦", "😧", "😨", "😰", "😥", "😢", "😭", "😱", "😖",
            "😣", "😞", "😓", "😩", "😫", "🥱", "😤", "😡", "😠", "🤬",
            "😈", "👿", "💀", "☠️", "💩", "🤡", "👹", "👺", "👻", "👽",
            "👾", "🤖", "🎃", "😺", "😸", "😹", "😻", "😼", "😽", "🙀",
            "😿", "😾", "👍", "👎", "👌", "🤌", "🤏", "✌️", "🤞", "🤟",
            "🤘", "🤙", "👈", "👉", "👆", "👇", "☝️", "✋", "🤚", "🖐️",
            "🖖", "👋", "🤝", "🙏", "💪", "👣", "👀", "🧠", "🫶", "💋",
            "❤️", "🧡", "💛", "💚", "💙", "💜", "🖤", "🤍", "🤎", "💔",
            "❣️", "💕", "💞", "💓", "💗", "💖", "💘", "💝"
        ]

        // MARK: - MessageList

        public var messageListErrorIndicator: UIImage = loadImageSafely(with: "error_indicator")

        // MARK: - FileIcons

        public var file7z: UIImage = loadImageSafely(with: "7z")
        public var fileAac: UIImage = loadImageSafely(with: "aac")
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
                    "aac": fileAac,
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
                        guard let icon = UIImage(named: $0.rawValue, in: .streamChatCommonUI) else { return nil }
                        return ($0, icon)
                    }
                )
            }
            set { _fileIcons = newValue }
        }

        // MARK: - Message Actions

        public var messageActionSwipeReply: UIImage = loadImageSafely(with: "icn_inline_reply").imageFlippedForRightToLeftLayoutDirection()
        public var messageActionInlineReply: UIImage = loadImageSafely(with: "icn_inline_reply").imageFlippedForRightToLeftLayoutDirection()
        public var messageActionThreadReply: UIImage = loadImageSafely(with: "icn_thread_reply")
        public var messageActionMarkUnread: UIImage = loadSafely(systemName: "message.badge", assetsFallback: "mark_unread")

        public var messageActionEdit: UIImage = loadImageSafely(with: "icn_edit")
        public var messageActionCopy: UIImage = loadImageSafely(with: "icn_copy")
        public var messageActionBlockUser: UIImage = loadImageSafely(with: "icn_block_user")
        public var messageActionMuteUser: UIImage = loadImageSafely(with: "icn_mute_user")
        public var messageActionDelete: UIImage = loadImageSafely(with: "icn_delete")
        public var messageActionResend: UIImage = loadImageSafely(with: "icn_resend")
        public var messageActionFlag: UIImage = loadImageSafely(with: "icn_flag")

        // MARK: - Placeholders

        public var channelAvatarPlaceholder: UIImage = loadSafely(systemName: "person.3", assetsFallback: "pattern1")
        public var userAvatarPlaceholder: UIImage = loadSafely(systemName: "person", assetsFallback: "pattern1")
        
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
                    .uploadingFailed: restart,
                    nil: folder
                ]
            }
            set { _fileAttachmentActionIcons = newValue }
        }

        private var _fileAttachmentDownloadActionIcons: [LocalAttachmentDownloadState?: UIImage]?
        public var fileAttachmentDownloadActionIcons: [LocalAttachmentDownloadState?: UIImage] {
            get { _fileAttachmentDownloadActionIcons ??
                [
                    .downloaded: share,
                    .downloadingFailed: download,
                    nil: download
                ]
            }
            set { _fileAttachmentDownloadActionIcons = newValue }
        }

        public var camera: UIImage = loadImageSafely(with: "camera")
        public var bigPlay: UIImage = loadImageSafely(with: "play_big").imageFlippedForRightToLeftLayoutDirection()

        public var play: UIImage = loadImageSafely(with: "play").imageFlippedForRightToLeftLayoutDirection()
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
        
        // MARK: - SwiftUI images
        
        public var attachmentPickerPhotos: UIImage = UIImage(systemName: "photo")!
        public var attachmentPickerFolder: UIImage = UIImage(systemName: "folder")!
        public var attachmentPickerCamera: UIImage = UIImage(systemName: "camera")!
        public var attachmentPickerPolls: UIImage = loadImageSafely(with: "attachment_picker_polls")
        
        public var muted: UIImage = UIImage(systemName: "speaker.slash")!
        public var searchClose: UIImage = UIImage(systemName: "multiply.circle")!
        public var pin: UIImage = loadImageSafely(with: "icn_pin")
        public var imagePlaceholder: UIImage = UIImage(systemName: "photo")!
        public var personPlaceholder: UIImage = UIImage(systemName: "person.circle")!
        public var checkmarkFilled: UIImage = UIImage(systemName: "checkmark.circle.fill")!
        public var closeFill: UIImage = UIImage(systemName: "xmark.circle.fill")!
        public var videoIndicator: UIImage = UIImage(systemName: "video.fill")!
        public var gallery: UIImage = UIImage(systemName: "square.grid.3x3.fill")!
        
        // MARK: - No Content Icons
        
        public var noContent: UIImage = UIImage(
            systemName: "message",
            withConfiguration: UIImage.SymbolConfiguration(pointSize: 100, weight: .regular)
        ) ?? UIImage.circleImage
        public var noMedia: UIImage = UIImage(
            systemName: "folder",
            withConfiguration: UIImage.SymbolConfiguration(pointSize: 100, weight: .regular)
        ) ?? UIImage.circleImage
        public var noThreads: UIImage = UIImage(
            systemName: "text.bubble",
            withConfiguration: UIImage.SymbolConfiguration(pointSize: 100, weight: .regular)
        ) ?? UIImage.circleImage

        // MARK: - V5 - Composer Icons

        public var composerAdd: UIImage = loadSafely(
            systemName: "plus",
            config: UIImage.SymbolConfiguration(
                weight: .light
            )
        )

        public var composerSend: UIImage = loadSafely(
            systemName: "paperplane",
            config: UIImage.SymbolConfiguration(
                weight: .regular
            )
        )

        public var composerMic: UIImage = loadSafely(
            systemName: "mic",
            config: UIImage.SymbolConfiguration(
                weight: .regular
            )
        )
        
        /// The reactions emoji unicode rendered in the message list.
        public var availableMessagesReactionEmojis: [MessageReactionType: String] {
            get {
                _availableMessagesReactionEmojis ??
                    [
                        "love": "❤️",
                        "haha": "😂",
                        "like": "👍",
                        "sad": "👎",
                        "wow": "😮"
                    ]
            }
            set { _availableMessagesReactionEmojis = newValue }
        }

        private var _availableMessagesReactionEmojis: [MessageReactionType: String]?

        // MARK: - V5 - Attachment Icons

        public var attachmentPlayOverlayIcon: UIImage = loadSafely(
            systemName: "play.fill",
            config: UIImage.SymbolConfiguration(
                pointSize: 12,
                weight: .regular
            )
        )

        public var overlayDismissIcon: UIImage = loadSafely(
            systemName: "xmark",
            config: UIImage.SymbolConfiguration(
                pointSize: 10,
                weight: .heavy
            )
        )

        public var attachmentImageIcon: UIImage = loadSafely(
            systemName: "camera",
            config: UIImage.SymbolConfiguration(weight: .regular)
        )

        public var attachmentLinkIcon: UIImage = loadSafely(
            systemName: "link",
            config: UIImage.SymbolConfiguration(weight: .regular)
        )

        public var attachmentVideoIcon: UIImage = loadSafely(
            systemName: "video",
            config: UIImage.SymbolConfiguration(weight: .regular)
        )

        public var attachmentDocIcon: UIImage = loadSafely(
            systemName: "document",
            config: UIImage.SymbolConfiguration(weight: .regular)
        )

        public var attachmentVoiceIcon: UIImage = loadSafely(
            systemName: "microphone",
            config: UIImage.SymbolConfiguration(weight: .regular)
        )

        public var attachmentPollIcon: UIImage = loadSafely(
            systemName: "chart.bar",
            config: UIImage.SymbolConfiguration(weight: .regular)
        )

        public var attachmentPhotoIcon: UIImage = loadSafely(
            systemName: "photo",
            config: UIImage.SymbolConfiguration(weight: .regular)
        )

        // MARK: - V5 - File Type Preview Icons

        public var iconPdf: UIImage = loadImageSafely(with: "file-pdf")
        public var iconDoc: UIImage = loadImageSafely(with: "file-doc")
        public var iconPpt: UIImage = loadImageSafely(with: "file-ppt")
        public var iconXls: UIImage = loadImageSafely(with: "file-xls")
        public var iconMp3: UIImage = loadImageSafely(with: "file-mp3")
        public var iconMp4: UIImage = loadImageSafely(with: "file-mp4")
        public var iconHtml: UIImage = loadImageSafely(with: "file-html")
        public var iconZip: UIImage = loadImageSafely(with: "file-zip")
        public var iconOther: UIImage = loadImageSafely(with: "file-other")

        private var _fileIconPreviews: [String: UIImage]?

        /// Mapping of file extensions to their v5 file type preview icons.
        public var fileIconPreviews: [String: UIImage] {
            get {
                _fileIconPreviews ?? [
                    // PDF
                    "pdf": iconPdf,
                    // Documents
                    "doc": iconDoc,
                    "docx": iconDoc,
                    "txt": iconDoc,
                    "rtf": iconDoc,
                    "odt": iconDoc,
                    "md": iconDoc,
                    // Presentations
                    "ppt": iconPpt,
                    "pptx": iconPpt,
                    // Spreadsheets
                    "xls": iconXls,
                    "xlsx": iconXls,
                    "csv": iconXls,
                    // Audio
                    "mp3": iconMp3,
                    "aac": iconMp3,
                    "wav": iconMp3,
                    "m4a": iconMp3,
                    // Video
                    "mp4": iconMp4,
                    "mov": iconMp4,
                    "avi": iconMp4,
                    "mkv": iconMp4,
                    "webm": iconMp4,
                    // Code
                    "html": iconHtml,
                    "htm": iconHtml,
                    "css": iconHtml,
                    "js": iconHtml,
                    "json": iconHtml,
                    "xml": iconHtml,
                    "swift": iconHtml,
                    // Compression
                    "zip": iconZip,
                    "rar": iconZip,
                    "7z": iconZip,
                    "tar": iconZip,
                    "gz": iconZip,
                    "tar.gz": iconZip
                ]
            }
            set { _fileIconPreviews = newValue }
        }
    }
}
