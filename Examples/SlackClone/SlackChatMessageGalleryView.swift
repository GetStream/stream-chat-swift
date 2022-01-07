//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import StreamChat
import StreamChatUI
import UIKit

final class SlackGalleryAttachmentViewInjector: GalleryAttachmentViewInjector {
    override var galleryViewAspectRatio: CGFloat? { nil }
}

final class SlackChatMessageGalleryView: ChatMessageGalleryView {
    private lazy var stackView = ContainerStackView()
    
    override func setUpAppearance() {
        super.setUpAppearance()
        
        (itemSpots + [moreItemsOverlay]).forEach {
            $0.layer.cornerRadius = 10
            $0.layer.masksToBounds = true
        }
    }
    
    override func setUpLayout() {
        stackView.spacing = 15
        stackView.distribution = .equal
        stackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stackView)
        
        itemSpots.forEach {
            stackView.addArrangedSubview($0)
            $0.heightAnchor.constraint(equalTo: $0.widthAnchor).isActive = true
        }
        
        let lastSpot = itemSpots.last!
        addSubview(moreItemsOverlay)
        NSLayoutConstraint.activate([
            moreItemsOverlay.leadingAnchor.constraint(equalTo: lastSpot.leadingAnchor),
            moreItemsOverlay.trailingAnchor.constraint(equalTo: lastSpot.trailingAnchor),
            moreItemsOverlay.topAnchor.constraint(equalTo: lastSpot.topAnchor),
            moreItemsOverlay.bottomAnchor.constraint(equalTo: lastSpot.bottomAnchor)
        ])
        
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
}
