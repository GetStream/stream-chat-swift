//
//  CGFloat+Extensions.swift
//  GetStreamChat
//
//  Created by Alexey Bukhtin on 03/04/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import UIKit

extension CGFloat {
    public static let safeAreaTop: CGFloat = (UIApplication.shared.delegate?.window as? UIWindow)?.safeAreaInsets.top ?? 0
    public static let safeAreaBottom: CGFloat = (UIApplication.shared.delegate?.window as? UIWindow)?.safeAreaInsets.bottom ?? 0
    
    public static let chatBottomThreshold: CGFloat = .messageAvatarSize + 2 * .messageVerticalInset + .messagesToComposerPadding
    
    public static let chatFooterHeight: CGFloat = 30
    public static let chatFooterAvatarRadius: CGFloat = 13
    
    public static let composerCornerRadius: CGFloat = 10
    public static let composerHeight: CGFloat = 60
    public static let composerMaxHeight: CGFloat = 200
    public static let composerInnerPadding: CGFloat = 16
    public static let composerButtonWidth: CGFloat = 44
    public static let composerAttachmentsHeight: CGFloat = 80
    public static let composerAttachmentWidth: CGFloat = 50
    public static let composerAttachmentHeight: CGFloat = 60
    
    public static let composerHelperIconSize: CGFloat = 30
    public static let composerHelperTitleEdgePadding: CGFloat = 20
    public static let composerHelperButtonEdgePadding: CGFloat = 15
    public static let composerHelperButtonCornerRadius: CGFloat = 3
    public static let composerHelperShadowRadius: CGFloat = 20
    public static let composerHelperShdowOpacity: CGFloat = 0.15
    
    public static let messagesToComposerPadding: CGFloat = .composerHeight + 2 * .messageEdgePadding
    public static let messageAvatarRadius: CGFloat = 16
    public static let messageAvatarSize: CGFloat = 2 * .messageAvatarRadius
    public static let messageInnerPadding: CGFloat = 8
    public static let messageEdgePadding: CGFloat = 10
    public static let messageBottomPadding: CGFloat = 10
    public static let messageSpacing: CGFloat = 3
    public static let messageCornerRadius: CGFloat = 16
    public static let messageHorizontalInset: CGFloat = 10
    public static let messageVerticalInset: CGFloat = 5
    public static let messageTextPadding: CGFloat = .messageEdgePadding + .messageAvatarSize + .messageInnerPadding
    public static let messageTextMaxWidth: CGFloat = UIScreen.main.bounds.width - 2 * .messageTextPadding
    
    public static let messageStatusLineWidth: CGFloat = 1
    public static let messageStatusSpacing: CGFloat = 26
    
    public static let attachmentPreviewHeight: CGFloat = 150
    public static let attachmentPreviewMaxHeight: CGFloat = 220
    public static let attachmentPreviewActionButtonHeight: CGFloat = 2 * .messageCornerRadius
    public static let attachmentFilePreviewHeight: CGFloat = 50
    public static let attachmentFileIconWidth: CGFloat = 25
    public static let attachmentFileIconHeight: CGFloat = 30
    public static let attachmentFileIconTop: CGFloat = (.attachmentFilePreviewHeight - .attachmentFileIconHeight) / 2
    
    public static let reactionsTextPagging: CGFloat = 5
    public static let reactionsToMessageOffset: CGFloat = 2
    public static let reactionsHeight: CGFloat = 2 * .reactionsCornerRadius
    public static let reactionsCornerRadius: CGFloat = 10
    
    public static let reactionsPickerCornerRadius: CGFloat = 30
    public static let reactionsPickerCornerHeight: CGFloat = 2 * .reactionsPickerCornerRadius
    public static let reactionsPickerShadowOffsetY: CGFloat = 11
    public static let reactionsPickerShadowRadius: CGFloat = 8
    public static let reactionsPickerShdowOpacity: CGFloat = 0.3
    public static let reactionsPickerAvatarRadius: CGFloat = 10
    public static let reactionsPickerButtonWidth: CGFloat = 36
    public static let reactionsPickerCounterHeight: CGFloat = 20
}
