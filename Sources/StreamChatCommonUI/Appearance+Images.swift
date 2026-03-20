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
        public var close: UIImage = loadSafely(systemName: "xmark")
        public var discard: UIImage = loadSafely(systemName: "xmark")
        public var link: UIImage = loadImageSafely(with: "link")

        public var closeCircleTransparent: UIImage = loadSafely(systemName: "xmark.circle")
        public var discardAttachment: UIImage = loadImageSafely(with: "close_circle_filled")
        public var back: UIImage = loadSafely(systemName: "chevron.left")
        public var onlyVisibleToCurrentUser = loadSafely(systemName: "eye.fill")
        public var more = loadSafely(systemName: "ellipsis")
        public var share: UIImage = loadSafely(systemName: "square.and.arrow.up")

        public var commands: UIImage = loadImageSafely(with: "bolt")
        public var smallBolt: UIImage = loadImageSafely(with: "bolt_small")
        public var openAttachments: UIImage = loadImageSafely(with: "clip")
        public var shrinkInputArrow: UIImage = loadImageSafely(with: "arrow_shrink_input")
        public var sendArrow: UIImage = loadImageSafely(with: "arrow_send").imageFlippedForRightToLeftLayoutDirection()
        public var whiteCheckmark: UIImage = loadImageSafely(with: "checkmark_white")
        public var confirmCheckmark: UIImage = loadImageSafely(with: "checkmark_confirm")
        public var bigConfirmCheckmark: UIImage = loadImageSafely(with: "checkmark_confirm_big")
        public var folder: UIImage = loadSafely(systemName: "folder")
        public var restart: UIImage = loadSafely(systemName: "arrow.trianglehead.2.counterclockwise")
        public var emptyChannelListMessageBubble: UIImage = loadSafely(systemName: "message")
        public var emptySearch: UIImage = loadSafely(systemName: "magnifyingglass")
        public var download: UIImage = loadSafely(systemName: "icloud.and.arrow.down")
        
        // MARK: - Recording

        public var mic: UIImage = loadSafely(systemName: "mic")
        public var lock: UIImage = loadSafely(systemName: "lock")
        public var chevronLeft: UIImage = loadSafely(systemName: "chevron.left").imageFlippedForRightToLeftLayoutDirection()
        public var chevronRight: UIImage = loadSafely(systemName: "chevron.right").imageFlippedForRightToLeftLayoutDirection()
        public var chevronUp: UIImage = loadSafely(systemName: "chevron.up")
        public var trash: UIImage = loadSafely(systemName: "trash")
        public var stop: UIImage = loadSafely(systemName: "stop.circle")
        public var playFill: UIImage = loadSafely(systemName: "play.fill").imageFlippedForRightToLeftLayoutDirection()
        public var pauseFill: UIImage = loadSafely(systemName: "pause.fill")
        public var recordingPlay: UIImage = loadSafely(systemName: "play").imageFlippedForRightToLeftLayoutDirection()
        public var recordingPause: UIImage = loadSafely(systemName: "pause")
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
        
        public var reactionDetailsShowPicker: UIImage = loadSafely(systemName: "face.smiling")

        /// The reactions appearance used to display reactions in the message list.
        public var defaultReactions: [MessageReactionType: ChatMessageReactionAppearanceType] {
            get {
                _defaultReactions ??
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
            set { _defaultReactions = newValue }
        }

        private var _defaultReactions: [MessageReactionType: ChatMessageReactionAppearanceType]?

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
        
        public var availableEmojis: [[String: String]] = [
            ["key": "grinning", "value": "😀"],
            ["key": "smiley", "value": "😃"],
            ["key": "smile", "value": "😄"],
            ["key": "grin", "value": "😁"],
            ["key": "laughing", "value": "😆"],
            ["key": "sweat_smile", "value": "😅"],
            ["key": "rofl", "value": "🤣"],
            ["key": "haha", "value": "😂"],
            ["key": "slightly_smiling_face", "value": "🙂"],
            ["key": "upside_down_face", "value": "🙃"],
            ["key": "wink", "value": "😉"],
            ["key": "blush", "value": "😊"],
            ["key": "innocent", "value": "😇"],
            ["key": "smiling_face_with_three_hearts", "value": "🥰"],
            ["key": "heart_eyes", "value": "😍"],
            ["key": "star_struck", "value": "🤩"],
            ["key": "kissing_heart", "value": "😘"],
            ["key": "kissing", "value": "😗"],
            ["key": "kissing_closed_eyes", "value": "😚"],
            ["key": "kissing_smiling_eyes", "value": "😙"],
            ["key": "yum", "value": "😋"],
            ["key": "stuck_out_tongue", "value": "😛"],
            ["key": "stuck_out_tongue_winking_eye", "value": "😜"],
            ["key": "zany_face", "value": "🤪"],
            ["key": "stuck_out_tongue_closed_eyes", "value": "😝"],
            ["key": "money_mouth_face", "value": "🤑"],
            ["key": "hugs", "value": "🤗"],
            ["key": "hand_over_mouth", "value": "🤭"],
            ["key": "shushing_face", "value": "🤫"],
            ["key": "thinking", "value": "🤔"],
            ["key": "zipper_mouth_face", "value": "🤐"],
            ["key": "raised_eyebrow", "value": "🤨"],
            ["key": "neutral_face", "value": "😐"],
            ["key": "expressionless", "value": "😑"],
            ["key": "no_mouth", "value": "😶"],
            ["key": "face_in_clouds", "value": "😶‍🌫️"],
            ["key": "smirk", "value": "😏"],
            ["key": "unamused", "value": "😒"],
            ["key": "roll_eyes", "value": "🙄"],
            ["key": "grimacing", "value": "😬"],
            ["key": "lying_face", "value": "🤥"],
            ["key": "relieved", "value": "😌"],
            ["key": "pensive", "value": "😔"],
            ["key": "sleepy", "value": "😪"],
            ["key": "drooling_face", "value": "🤤"],
            ["key": "sleeping", "value": "😴"],
            ["key": "mask", "value": "😷"],
            ["key": "face_with_thermometer", "value": "🤒"],
            ["key": "face_with_head_bandage", "value": "🤕"],
            ["key": "nauseated_face", "value": "🤢"],
            ["key": "vomiting_face", "value": "🤮"],
            ["key": "sneezing_face", "value": "🤧"],
            ["key": "hot_face", "value": "🥵"],
            ["key": "cold_face", "value": "🥶"],
            ["key": "woozy_face", "value": "🥴"],
            ["key": "face_with_spiral_eyes", "value": "😵‍💫"],
            ["key": "exploding_head", "value": "🤯"],
            ["key": "cowboy_hat_face", "value": "🤠"],
            ["key": "partying_face", "value": "🥳"],
            ["key": "sunglasses", "value": "😎"],
            ["key": "nerd_face", "value": "🤓"],
            ["key": "monocle_face", "value": "🧐"],
            ["key": "confused", "value": "😕"],
            ["key": "worried", "value": "😟"],
            ["key": "slightly_frowning_face", "value": "🙁"],
            ["key": "frowning_face", "value": "☹️"],
            ["key": "wow", "value": "😮"],
            ["key": "hushed", "value": "😯"],
            ["key": "astonished", "value": "😲"],
            ["key": "flushed", "value": "😳"],
            ["key": "pleading_face", "value": "🥺"],
            ["key": "frowning", "value": "😦"],
            ["key": "anguished", "value": "😧"],
            ["key": "fearful", "value": "😨"],
            ["key": "cold_sweat", "value": "😰"],
            ["key": "disappointed_relieved", "value": "😥"],
            ["key": "cry", "value": "😢"],
            ["key": "sob", "value": "😭"],
            ["key": "scream", "value": "😱"],
            ["key": "confounded", "value": "😖"],
            ["key": "persevere", "value": "😣"],
            ["key": "disappointed", "value": "😞"],
            ["key": "sweat", "value": "😓"],
            ["key": "weary", "value": "😩"],
            ["key": "tired_face", "value": "😫"],
            ["key": "yawning_face", "value": "🥱"],
            ["key": "triumph", "value": "😤"],
            ["key": "rage", "value": "😡"],
            ["key": "angry", "value": "😠"],
            ["key": "cursing_face", "value": "🤬"],
            ["key": "smiling_imp", "value": "😈"],
            ["key": "imp", "value": "👿"],
            ["key": "skull", "value": "💀"],
            ["key": "skull_and_crossbones", "value": "☠️"],
            ["key": "poop", "value": "💩"],
            ["key": "clown_face", "value": "🤡"],
            ["key": "japanese_ogre", "value": "👹"],
            ["key": "japanese_goblin", "value": "👺"],
            ["key": "ghost", "value": "👻"],
            ["key": "alien", "value": "👽"],
            ["key": "space_invader", "value": "👾"],
            ["key": "robot", "value": "🤖"],
            ["key": "jack_o_lantern", "value": "🎃"],
            ["key": "smiley_cat", "value": "😺"],
            ["key": "smile_cat", "value": "😸"],
            ["key": "joy_cat", "value": "😹"],
            ["key": "heart_eyes_cat", "value": "😻"],
            ["key": "smirk_cat", "value": "😼"],
            ["key": "kissing_cat", "value": "😽"],
            ["key": "scream_cat", "value": "🙀"],
            ["key": "crying_cat_face", "value": "😿"],
            ["key": "pouting_cat", "value": "😾"],
            ["key": "like", "value": "👍"],
            ["key": "sad", "value": "👎"],
            ["key": "ok_hand", "value": "👌"],
            ["key": "pinched_fingers", "value": "🤌"],
            ["key": "pinching_hand", "value": "🤏"],
            ["key": "v", "value": "✌️"],
            ["key": "crossed_fingers", "value": "🤞"],
            ["key": "love_you_gesture", "value": "🤟"],
            ["key": "metal", "value": "🤘"],
            ["key": "call_me_hand", "value": "🤙"],
            ["key": "point_left", "value": "👈"],
            ["key": "point_right", "value": "👉"],
            ["key": "point_up_2", "value": "👆"],
            ["key": "point_down", "value": "👇"],
            ["key": "point_up", "value": "☝️"],
            ["key": "raised_hand", "value": "✋"],
            ["key": "raised_back_of_hand", "value": "🤚"],
            ["key": "raised_hand_with_fingers_splayed", "value": "🖐️"],
            ["key": "vulcan_salute", "value": "🖖"],
            ["key": "wave", "value": "👋"],
            ["key": "handshake", "value": "🤝"],
            ["key": "pray", "value": "🙏"],
            ["key": "muscle", "value": "💪"],
            ["key": "footprints", "value": "👣"],
            ["key": "eyes", "value": "👀"],
            ["key": "brain", "value": "🧠"],
            ["key": "heart_hands", "value": "🫶"],
            ["key": "kiss", "value": "💋"],
            ["key": "love", "value": "❤️"],
            ["key": "orange_heart", "value": "🧡"],
            ["key": "yellow_heart", "value": "💛"],
            ["key": "green_heart", "value": "💚"],
            ["key": "blue_heart", "value": "💙"],
            ["key": "purple_heart", "value": "💜"],
            ["key": "black_heart", "value": "🖤"],
            ["key": "white_heart", "value": "🤍"],
            ["key": "brown_heart", "value": "🤎"],
            ["key": "broken_heart", "value": "💔"],
            ["key": "heart_exclamation", "value": "❣️"],
            ["key": "two_hearts", "value": "💕"],
            ["key": "revolving_hearts", "value": "💞"],
            ["key": "heartbeat", "value": "💓"],
            ["key": "growing_heart", "value": "💗"],
            ["key": "sparkling_heart", "value": "💖"],
            ["key": "cupid", "value": "💘"],
            ["key": "gift_heart", "value": "💝"]
        ]

        // MARK: - MessageList

        public var messageListErrorIndicator: UIImage = loadSafely(systemName: "exclamationmark.circle.fill")

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
        public var bigPlay: UIImage = loadSafely(systemName: "play.fill").imageFlippedForRightToLeftLayoutDirection()

        public var play: UIImage = loadSafely(systemName: "play.fill").imageFlippedForRightToLeftLayoutDirection()
        public var pause: UIImage = loadSafely(systemName: "pause")

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

        public var scrollDownArrow: UIImage = loadSafely(
            systemName: "arrow.down",
            config: UIImage.SymbolConfiguration(
                weight: .medium
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

        public var attachmentLinkIcon: UIImage = loadSafely(
            systemName: "link",
            config: UIImage.SymbolConfiguration(weight: .regular)
        )

        public var attachmentVideoIcon: UIImage = loadSafely(
            systemName: "video",
            config: UIImage.SymbolConfiguration(weight: .regular)
        )

        public var attachmentDocumentIcon: UIImage = loadSafely(
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

        public var attachmentCameraIcon: UIImage = loadSafely(
            systemName: "camera",
            config: UIImage.SymbolConfiguration(weight: .regular)
        )

        public var attachmentCommandIcon: UIImage = loadSafely(
            systemName: "chevron.left.forwardslash.chevron.right",
            config: UIImage.SymbolConfiguration(weight: .regular)
        )

        public var overlayDismissIcon: UIImage = loadSafely(
            systemName: "xmark",
            config: UIImage.SymbolConfiguration(
                pointSize: 10,
                weight: .heavy
            )
        )

        public var pollOptionDragIcon: UIImage = loadImageSafely(with: "poll_option_drag")

        // MARK: - V5 - Command Icons

        public var commandGiphyIcon: UIImage = loadImageSafely(with: "GiphyIcon")
            .withRenderingMode(.alwaysOriginal)

        public var commandMuteIcon: UIImage = loadSafely(
            systemName: "speaker.slash",
            config: UIImage.SymbolConfiguration(pointSize: 16, weight: .medium)
        ).withRenderingMode(.alwaysTemplate)

        public var commandUnmuteIcon: UIImage = loadSafely(
            systemName: "speaker.wave.2",
            config: UIImage.SymbolConfiguration(pointSize: 16, weight: .medium)
        ).withRenderingMode(.alwaysTemplate)

        public var commandsBolt: UIImage = loadSafely(
            systemName: "bolt.fill",
            config: UIImage.SymbolConfiguration(weight: .black)
        )

        public var commandsDismissIcon: UIImage = loadSafely(
            systemName: "xmark",
            config: UIImage.SymbolConfiguration(weight: .bold)
        )

        // MARK: - V5 - Media Picker View

        public var selectionBadgeIcon: UIImage = loadSafely(
            systemName: "checkmark",
            config: UIImage.SymbolConfiguration(weight: .bold)
        )

        // MARK: - V5 - Media Badge Icons

        public var videoMediaIcon: UIImage = loadSafely(
            systemName: "video.fill",
            config: UIImage.SymbolConfiguration(pointSize: 10)
        )

        public var audioMediaIcon: UIImage = loadSafely(
            systemName: "mic.fill",
            config: UIImage.SymbolConfiguration(pointSize: 10)
        )

        // MARK: - V5 - Message Annotation Icons

        public var annotationThread: UIImage = loadSafely(
            systemName: "arrow.up.right",
            config: UIImage.SymbolConfiguration(pointSize: 14)
        )

        public var annotationReminder: UIImage = loadSafely(
            systemName: "bell",
            config: UIImage.SymbolConfiguration(pointSize: 14)
        )

        public var annotationTranslation: UIImage = loadSafely(
            systemName: "translate",
            config: UIImage.SymbolConfiguration(pointSize: 13)
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
                    "ods": iconXls,
                    "md": iconDoc,
                    "generic": iconOther,
                    "unknown": iconOther,
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
                    "ogg": iconMp3,
                    // Video
                    "mp4": iconMp4,
                    "mov": iconMp4,
                    "avi": iconMp4,
                    "mkv": iconMp4,
                    "webm": iconMp4,
                    "wmv": iconMp4,
                    // Code
                    "html": iconHtml,
                    "shtml": iconHtml,
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
                    "x7z": iconZip,
                    "tar": iconZip,
                    "gz": iconZip,
                    "xz": iconZip,
                    "tar.gz": iconZip
                ]
            }
            set { _fileIconPreviews = newValue }
        }
    }
}
