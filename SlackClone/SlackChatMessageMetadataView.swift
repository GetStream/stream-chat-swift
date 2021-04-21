//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import StreamChatUI
import UIKit

final class SlackChatMessageMetadataView: ChatMessageMetadataView {
    private lazy var nameLabel = UILabel()
    
    override func setUpLayout() {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.spacing = UIStackView.spacingUseSystem
        stackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
        
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        stackView.addArrangedSubview(nameLabel)
        
        stackView.addArrangedSubview(timestampLabel)
    }
    
    override func setUpAppearance() {
        super.setUpAppearance()
        
        nameLabel.font = uiConfig.font.bodyBold
        timestampLabel.font = uiConfig.font.footnote
    }
    
    override func updateContent() {
        super.updateContent()
        
        nameLabel.text = message?.author.name ?? ""
    }
}
