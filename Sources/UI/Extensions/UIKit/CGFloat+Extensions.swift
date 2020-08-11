//
//  CGFloat+Extensions.swift
//  StreamChat
//
//  Created by Alexey Bukhtin on 03/04/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import UIKit

extension CGFloat {
    /// The screen width (alias to `UIScreen.main.bounds.width`).
    public static let screenWidth: CGFloat = UIScreen.main.bounds.width
    /// The min screen width.
    public static let minScreenWidth: CGFloat = Swift.min(UIScreen.main.bounds.width, UIScreen.main.bounds.height)
    /// The screen height (alias to `UIScreen.main.bounds.height`).
    public static let screenHeight: CGFloat = UIScreen.main.bounds.height
    /// A top safe area value.
    public static let safeAreaTop: CGFloat = (UIApplication.shared.delegate?.window as? UIWindow)?.safeAreaInsets.top ?? 0
    /// A bottom safe area value.
    public static let safeAreaBottom: CGFloat = (UIApplication.shared.delegate?.window as? UIWindow)?.safeAreaInsets.bottom ?? 0
    
    /// A channel avatar radius.
    public static let channelAvatarRadius: CGFloat = 20
    
    /// A chat footer hight.
    public static let chatFooterHeight: CGFloat = 30
    /// A chat footer avatar radius.
    public static let chatFooterAvatarRadius: CGFloat = 13
    
    /// A composer corner radius.
    public static let composerCornerRadius: CGFloat = 10
    /// A composer height.
    public static let composerHeight: CGFloat = 60
    /// A composer max height.
    public static let composerMaxHeight: CGFloat = 200
    /// A composer inner radius.
    public static let composerInnerPadding: CGFloat = 16
    /// A composer button width.
    public static let composerButtonWidth: CGFloat = 44
    /// A composer attachment size.
    public static let composerAttachmentSize: CGFloat = 60
    /// A composer attachments height.
    public static let composerAttachmentsHeight: CGFloat = .composerAttachmentSize + 2 * .composerCornerRadius
    
    /// A composer helper corner radius.
    public static let composerHelperCornerRadius: CGFloat = .messageCornerRadius
    /// A composer helper icon size.
    public static let composerHelperIconSize: CGFloat = 32
    /// A composer helper icon corner radius.
    public static let composerHelperIconCornerRadius: CGFloat = .composerCornerRadius / 2
    /// A composer helper title edge padding.
    public static let composerHelperTitleEdgePadding: CGFloat = 20
    /// A composer helper button edge padding.
    public static let composerHelperButtonEdgePadding: CGFloat = 15
    /// A composer helper button corner radius.
    public static let composerHelperButtonCornerRadius: CGFloat = 3
    /// A composer helper shadow radius.
    public static let composerHelperShadowRadius: CGFloat = 20
    /// A composer helper shadow opacity.
    public static let composerHelperShadowOpacity: CGFloat = 0.15
    /// A reply in the channel button height.
    public static let composerReplyInChannelHeight: CGFloat = 40
    
    /// A composer file padding.
    public static let composerFilePadding: CGFloat = 10
    /// A composer file height.
    public static let composerFileHeight: CGFloat = .composerFileIconHeight + 2 * .composerFilePadding
    /// A composer file icon height.
    public static let composerFileIconHeight: CGFloat = 30
    /// A composer file icon width.
    public static let composerFileIconWidth: CGFloat = 25
    
    /// A message avatar radius.
    public static let messageAvatarRadius: CGFloat = 16
    /// A message avatar size.
    public static let messageAvatarSize: CGFloat = 2 * .messageAvatarRadius
    /// A message inner padding.
    public static let messageInnerPadding: CGFloat = 8
    /// A message edge padding.
    public static let messageEdgePadding: CGFloat = UIDevice.current.hasBigScreen ? 20 : 10
    /// A message bottom padding
    public static let messageBottomPadding: CGFloat = 10
    /// A message spacing.
    public static let messageSpacing: CGFloat = 3
    /// A message corner radius.
    public static let messageCornerRadius: CGFloat = 14
    /// A message horizontal inset.
    public static let messageHorizontalInset: CGFloat = 10
    /// A message vertical inset.
    public static let messageVerticalInset: CGFloat = 5
    /// A message text padding with avatar,
    public static let messageTextPaddingWithAvatar: CGFloat = .messageEdgePadding + .messageAvatarSize + .messageInnerPadding
    /// A name and date height for a message.
    public static let messageNameAndDateHeight: CGFloat = .messageAvatarRadius - .messageSpacing
    
    /// A message read users avatar border width.
    public static let messageReadUsersAvatarBorderWidth: CGFloat = 1
    /// A message read users avatar corner radius.
    public static let messageReadUsersAvatarCornerRadius: CGFloat = 10
    /// A message read users size.
    public static let messageReadUsersSize: CGFloat = 2 * .messageReadUsersAvatarCornerRadius
    
    /// A message status line width.
    public static let messageStatusLineWidth: CGFloat = 0.5
    /// A message status spacing.
    public static let messageStatusSpacing: CGFloat = 26
    
    /// A message attachment preview height.
    public static let attachmentPreviewHeight: CGFloat = 150
    /// A message attachment preview max height.
    public static let attachmentPreviewMaxHeight: CGFloat = 220
    
    /// An attachment preview max width.
    public static let attachmentPreviewMaxWidth: CGFloat = UIDevice.isPad
        ? (4 * .attachmentPreviewMaxHeight / 3).rounded()
        : .minScreenWidth - 2 * .messageTextPaddingWithAvatar
    
    /// A message attachment preview action button height.
    public static let attachmentPreviewActionButtonHeight: CGFloat = 2 * .messageCornerRadius
    /// A message attachment file preview height.
    public static let attachmentFilePreviewHeight: CGFloat = 50
    /// A message attachment file icon width.
    public static let attachmentFileIconWidth: CGFloat = 25
    /// A message attachment file icon height.
    public static let attachmentFileIconHeight: CGFloat = 30
    /// A message attachment file icon top.
    public static let attachmentFileIconTop: CGFloat = (.attachmentFilePreviewHeight - .attachmentFileIconHeight) / 2
    
    /// A message reactions text padding.
    public static let reactionsTextPadding: CGFloat = 5
    /// A message reactions to message offset.
    public static let reactionsToMessageOffset: CGFloat = 2
    /// A message reactions height.
    public static let reactionsHeight: CGFloat = 2 * .reactionsCornerRadius
    /// A message reactions corner radius.
    public static let reactionsCornerRadius: CGFloat = 10
    
    /// A message reactions picker corner radius.
    public static let reactionsPickerCornerRadius: CGFloat = 30
    /// A message reactions picker corner height.
    public static let reactionsPickerCornerHeight: CGFloat = 2 * .reactionsPickerCornerRadius
    /// A message reactions picker shadow offset y.
    public static let reactionsPickerShadowOffsetY: CGFloat = 11
    /// A message reactions picker shadow radius.
    public static let reactionsPickerShadowRadius: CGFloat = 8
    /// A message reactions picker shadow opacity.
    public static let reactionsPickerShdowOpacity: CGFloat = 0.3
    /// A message reactions picker avatar radius.
    public static let reactionsPickerAvatarRadius: CGFloat = 10
    /// A message reactions picker button width.
    public static let reactionsPickerButtonWidth: CGFloat = 36
    /// A message reactions picker counter height.
    public static let reactionsPickerCounterHeight: CGFloat = 20
    
    public static let bannerHeight: CGFloat = 60
    public static let bannerWidth: CGFloat = .screenWidth - 2 * .messageEdgePadding
    public static let bannerCornerRadius: CGFloat = 10
    public static let bannerTopOffset: CGFloat = .safeAreaTop
    public static let bannerMaxY: CGFloat = .bannerHeight + .bannerTopOffset + .composerHelperShadowRadius
}
