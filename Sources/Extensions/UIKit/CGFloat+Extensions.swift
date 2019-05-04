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
    
    public static let composerCornerRadius: CGFloat = 10
    public static let composerHeight: CGFloat = 60
    public static let composerMaxHeight: CGFloat = 200
    public static let composerInnerPadding: CGFloat = 16
    public static let composerButtonWidth: CGFloat = 44
    public static let composerAttachmentsHeight: CGFloat = 80
    public static let composerAttachmentWidth: CGFloat = 50
    public static let composerAttachmentHeight: CGFloat = 60
    
    public static let messagesToComposerPadding: CGFloat = .composerHeight + 2 * .messageEdgePadding + 20
    public static let messageAvatarRadius: CGFloat = 16
    public static let messageAvatarSize: CGFloat = 2 * .messageAvatarRadius
    public static let messageInnerPadding: CGFloat = 8
    public static let messageEdgePadding: CGFloat = 10
    public static let messageBottomPadding: CGFloat = 10
    public static let messageSpacing: CGFloat = 3
    public static let messageCornerRadius: CGFloat = 16
    public static let messageHorizontalInset: CGFloat = 10
    public static let messageVerticalInset: CGFloat = 5
    
    public static let messageStatusLineWidth: CGFloat = 1
    public static let messageStatusSpacing: CGFloat = 26
    
    public static let attachmentPreviewHeight: CGFloat = 150
    public static let attachmentPreviewMaxHeight: CGFloat = 220
    public static let attachmentFilePreviewHeight: CGFloat = 50
    public static let attachmentFileIconWidth: CGFloat = 25
    public static let attachmentFileIconHeight: CGFloat = 30
    public static let attachmentFileIconTop: CGFloat = (.attachmentFilePreviewHeight - .attachmentFileIconHeight) / 2

    public static let reactionsTextPagging: CGFloat = 5
    public static let reactionsToMessageOffset: CGFloat = 1
    public static let reactionsHeight: CGFloat = 2 * .reactionsCornerRadius
    public static let reactionsCornerRadius: CGFloat = 10
    public static let reactionOptionsHeight: CGFloat = 50
}
