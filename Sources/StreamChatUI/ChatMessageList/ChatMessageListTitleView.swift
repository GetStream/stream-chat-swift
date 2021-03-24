//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import UIKit
import StreamChat

public class ChatMessageListTitleView<ExtraData: ExtraDataTypes>: UIView, UIConfigProvider {
    public var title: String? {
        get { titleLabel.text }
        set { titleLabel.text = newValue }
    }
    
    public var subtitle: String? {
        get { subtitleLabel.text }
        set { subtitleLabel.text = newValue }
    }
    
    private weak var titleLabel: UILabel!
    private weak var subtitleLabel: UILabel!
    
    public init() {
        super.init(frame: .zero)
        
        let titleLabel = UILabel()
        titleLabel.textAlignment = .center
        titleLabel.font = uiConfig.font.headlineBold
        self.titleLabel = titleLabel

        let subtitleLabel = UILabel()
        subtitleLabel.textAlignment = .center
        subtitleLabel.font = uiConfig.font.caption1
        subtitleLabel.textColor = uiConfig.colorPalette.subtitleText
        self.subtitleLabel = subtitleLabel

        let titleView = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        titleView.axis = .vertical
        addSubview(titleView)
        titleView.translatesAutoresizingMaskIntoConstraints = false
        titleView.pin(to: self)
    }
    
    @available(*, unavailable)
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
