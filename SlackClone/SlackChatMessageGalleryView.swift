//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import StreamChatUI
import UIKit

final class SlackChatMessageGalleryView: ChatMessageGalleryView {
    private lazy var stackView = UIStackView()
    
    override func setUpLayout() {
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.alignment = .fill
        stackView.spacing = 15
        stackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        itemSpots.forEach {
            stackView.addArrangedSubview($0)
            NSLayoutConstraint.activate([
                $0.heightAnchor.constraint(equalTo: $0.widthAnchor)
            ])
        }
    }
}

final class SlackChatMessageImagePreview: ChatMessageGalleryView.ImagePreview {
    override func setUpAppearance() {
        super.setUpAppearance()
        
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 10
    }
}
