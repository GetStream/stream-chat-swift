//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import UIKit
import StreamChat

open class _ChatMessageListTitleView<ExtraData: ExtraDataTypes>: _View, UIConfigProvider {
    open var content: (title: String?, subtitle: String?) = (nil, nil) {
        didSet {
            updateContent()
        }
    }
    
    open private(set) var titleLabel: UILabel = UILabel()
    open private(set) var subtitleLabel: UILabel = UILabel()
    
    public override func defaultAppearance() {
        super.defaultAppearance()
        
        titleLabel.textAlignment = .center
        titleLabel.font = uiConfig.font.headlineBold
        
        subtitleLabel.textAlignment = .center
        subtitleLabel.font = uiConfig.font.caption1
        subtitleLabel.textColor = uiConfig.colorPalette.subtitleText
    }
    
    open override func setUpLayout() {
        super.setUpLayout()
        
        let titleView = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        titleView.axis = .vertical
        addSubview(titleView)
        titleView.translatesAutoresizingMaskIntoConstraints = false
        titleView.pin(to: self)
    }
    
    open override func updateContent() {
        super.updateContent()
        
        titleLabel.text = content.title
        subtitleLabel.text = content.subtitle
    }
}
