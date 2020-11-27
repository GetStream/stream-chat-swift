//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// Yes it's ViewController, because it controlls popup view
/// But not UIViewController, because we don't actually need it yet
class ChatMessagePopupViewController<ExtraData: UIExtraDataTypes>: NSObject {
    let window: UIWindow
    let snapshot: UIView
    let originalView: UIView
    let overlay: UIView
    let reactionsController: ChatMessageReactionViewController<ExtraData>
    let onComplete: () -> Void

    init?(
        _ view: UIView,
        for message: _ChatMessage<ExtraData>,
        in channel: ChannelId,
        with client: _ChatClient<ExtraData>,
        onComplete: @escaping () -> Void
    ) {
        guard let window = view.window else { return nil }
        guard let snapshot = view.snapshotView(afterScreenUpdates: false) else { return nil }

        originalView = view
        self.window = window
        self.snapshot = snapshot
        overlay = UIView()
        reactionsController = ChatMessageReactionViewController(
            showAllAvailableReactions: true,
            messageID: message.id,
            channel: channel,
            client: client
        )
        self.onComplete = onComplete

        super.init()

        window.embed(overlay)
        if !UIAccessibility.isReduceTransparencyEnabled {
            let blur = UIVisualEffectView(effect: UIBlurEffect(style: .regular))
            overlay.embed(blur)
        }
        snapshot.frame = window.convert(view.frame, from: view.superview)
        overlay.addSubview(snapshot)

        let tapAction = UITapGestureRecognizer(target: self, action: #selector(didTapOnOverlay))
        overlay.addGestureRecognizer(tapAction)

        let reactionView = reactionsController.view
        reactionView.translatesAutoresizingMaskIntoConstraints = false
        overlay.addSubview(reactionView)
        reactionView.bottomAnchor.constraint(equalTo: snapshot.topAnchor).isActive = true
        let centerToMessage: NSLayoutConstraint
        if message.isSentByCurrentUser {
            reactionView.style = .bigOutgoing
            centerToMessage = reactionView.centerXAnchor.constraint(equalTo: snapshot.leadingAnchor)
        } else {
            reactionView.style = .bigIncoming
            centerToMessage = reactionView.centerXAnchor.constraint(equalTo: snapshot.trailingAnchor)
        }
        centerToMessage.priority = .defaultHigh
        centerToMessage.isActive = true
        reactionView.leadingAnchor.constraint(greaterThanOrEqualTo: overlay.leadingAnchor).isActive = true
        reactionView.trailingAnchor.constraint(lessThanOrEqualTo: overlay.trailingAnchor).isActive = true
    }

    @objc func didTapOnOverlay() {
        overlay.removeFromSuperview()
        onComplete()
    }
}
