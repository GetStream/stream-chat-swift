//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// A `NavigationRouter` subclass used for navigating from message-list-based view controllers.
public typealias ChatMessageListRouter = _ChatMessageListRouter<NoExtraData>

/// A `NavigationRouter` subclass used for navigating from message-list-based view controllers.
open class _ChatMessageListRouter<ExtraData: ExtraDataTypes>:
    // We use UIViewController here because the router is used for both
    // the channel and thread message lists.
    NavigationRouter<UIViewController>,
    UIViewControllerTransitioningDelegate,
    ComponentsProvider
{
    /// The transition controller used to animate `ChatMessagePopupVC` transition.
    open private(set) lazy var messagePopUpTransitionController = MessageActionsTransitionController<ExtraData>()

    /// Feedback generator used when presenting actions controller on selected message
    open var impactFeedbackGenerator = UIImpactFeedbackGenerator(style: .medium)

    /// The transition controller used to animate photo gallery transition.
    open private(set) lazy var zoomTransitionController = ZoomTransitionController()

    /// Shows the detail pop-up for the selected message. By default called when the message is long-pressed.
    ///
    /// - Parameters:
    ///   - messageContentView: The source content view of the selected message. It's used to get the information
    ///   about the source frame for the zoom-like transition.
    ///   - messageActionsController: The `ChatMessageActionsVC` object which will presented as a part of the pop up.
    ///   - messageReactionsController: The `ChatMessageReactionsVC` object which will presented as a part of the pop up.
    ///
    open func showMessageActionsPopUp(
        messageContentView: _ChatMessageContentView<ExtraData>,
        messageActionsController: _ChatMessageActionsVC<ExtraData>,
        messageReactionsController: _ChatMessageReactionsVC<ExtraData>?
    ) {
        let popup = components.messagePopupVC.init()
        popup.messageContentView = messageContentView
        popup.actionsController = messageActionsController
        popup.reactionsController = messageReactionsController
        let bubbleView = messageContentView.bubbleView ?? messageContentView.bubbleContentContainer
        let bubbleViewFrame = bubbleView.superview!.convert(bubbleView.frame, to: nil)
        popup.messageBubbleViewInsets = UIEdgeInsets(
            top: bubbleViewFrame.origin.y,
            left: bubbleViewFrame.origin.x,
            bottom: messageContentView.frame.height - bubbleViewFrame.height,
            right: messageContentView.frame.width - bubbleViewFrame.origin.x - bubbleViewFrame.width
        )
        popup.modalPresentationStyle = .overFullScreen
        popup.transitioningDelegate = messagePopUpTransitionController

        messagePopUpTransitionController.messageContentView = messageContentView
        
        rootViewController.present(popup, animated: true)
    }

    /// Handles opening of a link URL.
    ///
    /// - Parameter url: The URL of the link to preview.
    ///
    open func showLinkPreview(link: URL) {
        UIApplication.shared.open(link)
    }

    /// Shows a View Controller that show the detail of a file attachment.
    ///
    /// - Parameter fileURL: The URL of the file to preview.
    ///
    open func showFilePreview(fileURL: URL?) {
        let preview = components.filePreviewVC.init()
        preview.content = fileURL
        
        let navigation = UINavigationController(rootViewController: preview)
        rootViewController.present(navigation, animated: true)
    }

    /// Shows the detail View Controller of a message thread.
    ///
    /// - Parameters:
    ///   - messageId: The id if the parent message of the thread.
    ///   - cid: The `cid` of the channel the message belongs to.
    ///   - client: The current `ChatClient` instance.
    ///
    open func showThread(
        messageId: MessageId,
        cid: ChannelId,
        client: _ChatClient<ExtraData>
    ) {
        let threadVC = components.threadVC.init()
        threadVC.channelController = client.channelController(for: cid)
        threadVC.messageController = client.messageController(
            cid: cid,
            messageId: messageId
        )
        rootNavigationController?.show(threadVC, sender: self)
    }

    /// Shows the image gallery VC for the selected photo attachment.
    ///
    /// - Parameters:
    ///   - message: The id of the message the attachment belongs to.
    ///   - initialAttachment: The attachment to present.
    ///   - previews: All previewable attachments of the message. This is used for swiping right-left when a single
    ///   message has multiple previewable attachments.
    ///
    open func showImageGallery(
        message: _ChatMessage<ExtraData>,
        initialAttachment: ChatMessageImageAttachment,
        previews: [ImagePreviewable]
    ) {
        guard
            let preview = previews.first(where: { $0.content?.id == initialAttachment.id })
        else { return }
        let imageGalleryVC = components.imagePreviewVC.init()
        imageGalleryVC.modalPresentationStyle = .overFullScreen
        imageGalleryVC.transitioningDelegate = self
        imageGalleryVC.content = message
        imageGalleryVC.initialAttachment = initialAttachment
        imageGalleryVC.transitionController = zoomTransitionController
        
        zoomTransitionController.presentedVCImageView = {
            let cell = imageGalleryVC.attachmentsCollectionView.cellForItem(
                at: IndexPath(item: imageGalleryVC.currentPage, section: 0)
            ) as? _ImageCollectionViewCell<ExtraData>
            return cell?.imageView
        }
        zoomTransitionController.presentingImageView = {
            let attachment = imageGalleryVC.images[imageGalleryVC.currentPage]
            return previews.first(where: { $0.content?.id == attachment.id })?.imageView ?? previews.last?.imageView
        }
        zoomTransitionController.fromImageView = preview.imageView
        rootViewController.present(imageGalleryVC, animated: true)
    }

    // MARK: - UIViewControllerTransitioningDelegate

    open func animationController(
        forPresented presented: UIViewController,
        presenting: UIViewController,
        source: UIViewController
    ) -> UIViewControllerAnimatedTransitioning? {
        zoomTransitionController.animationController(
            forPresented: presented,
            presenting: presenting,
            source: source
        )
    }
    
    open func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        zoomTransitionController.animationController(forDismissed: dismissed)
    }
    
    open func interactionControllerForDismissal(using animator: UIViewControllerAnimatedTransitioning)
        -> UIViewControllerInteractiveTransitioning? {
        zoomTransitionController.interactionControllerForDismissal(using: animator)
    }
}
