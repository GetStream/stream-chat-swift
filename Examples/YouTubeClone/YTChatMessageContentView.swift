//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import StreamChat
import StreamChatUI
import UIKit

final class YTChatMessageContentView: ChatMessageContentView {
    override var maxContentWidthMultiplier: CGFloat { 1 }
    
    override func createTimestampLabel() -> UILabel {
        let label = super.createTimestampLabel()
        label.font = appearance.fonts.footnote
        label.textAlignment = .center
        label.textColor = .secondaryLabel
        return label
    }
    
    override func createTextView() -> UITextView {
        let textView = super.createTextView()
        textView.font = appearance.fonts.footnote
        textView.textColor = .secondaryLabel
        return textView
    }
    
    override func createAuthorNameLabel() -> UILabel {
        let label = super.createAuthorNameLabel()
        label.font = appearance.fonts.footnoteBold
        return label
    }
    
    override var messageAuthorAvatarSize: CGSize {
        .init(width: 40, height: 40)
    }
    
    override func layout(options: ChatMessageLayoutOptions) {
        super.layout(options: options)
        
        // Set the container's axis to horizontal to match the look of YouTube comments(default is vertical)
        bubbleThreadMetaContainer.axis = .horizontal
        
        // Reverse the order of the subviews of the `bubbleThreadMetaContainer`
        // By default, the order is
        // |--- message---|
        // |--metadataContainer---|
        
        // By changing the axis to `horizontal` and reversing the order, now the arrangement looks like:
        // |--- metadataContainer ---message ---|
        let subviews = bubbleThreadMetaContainer.subviews
        bubbleThreadMetaContainer.removeAllArrangedSubviews()
        bubbleThreadMetaContainer.addArrangedSubviews(subviews.reversed())
        
        // Reverse the order of the subviews in the `metadataContainer`
        // By default, the order is
        // |--- author --- time ---|
        
        // By changing reversing it, the arrangement looks like:
        // |---time --- author---|
        let metadataSubviews = metadataContainer?.subviews
        metadataContainer?.removeAllArrangedSubviews()
        metadataContainer?.addArrangedSubviews((metadataSubviews?.reversed())!)
        
        // By default, there are directionalLayoutMargins with system value because of the bubble border option.
        // We need to disable them to get cleaner
        bubbleContentContainer.directionalLayoutMargins = .zero
        
        mainContainer.alignment = .center
    }
}
