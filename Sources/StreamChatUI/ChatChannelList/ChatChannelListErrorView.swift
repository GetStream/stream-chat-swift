//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

public protocol ChatChannelListErrorShowingView: UIView {
    var buttonAction: (() -> Void)? { get set }
}

open class ChatChannelListErrorView: _View, ThemeProvider, ChatChannelListErrorShowingView {
    open var buttonAction: (() -> Void)?
    
    /// Label describing there has been an error.
    open lazy var titleLabel: UILabel = UILabel().withBidirectionalLanguagesSupport.withoutAutoresizingMaskConstraints
    /// Retry button which is located at the trailing of the view.
    open lazy var retryButton: UIButton = UIButton().withoutAutoresizingMaskConstraints
    /// Spacing view so the button has some spacing with bidirectional language support.
    open lazy var spacer: UIView = UIView().withoutAutoresizingMaskConstraints
    /// Main container which holds title,spacer and the retry button.
    open lazy var mainContainer: ContainerStackView = ContainerStackView().withoutAutoresizingMaskConstraints
    
    override open func setUp() {
        super.setUp()
        
        titleLabel.text = L10n.Channellist.ErrorIndicator.message
        retryButton.addTarget(self, action: #selector(didTapRetryButton), for: .touchUpInside)
    }
    
    override open func setUpAppearance() {
        super.setUpAppearance()
        retryButton.setImage(appearance.images.restart, for: .normal)
        backgroundColor = appearance.colorPalette.textLowEmphasis
        titleLabel.textColor = appearance.colorPalette.staticColorText
        retryButton.tintColor = appearance.colorPalette.staticColorText
    }
    
    override open func setUpLayout() {
        super.setUpLayout()
        
        directionalLayoutMargins = .init(top: 8, leading: 16, bottom: 8, trailing: 24)
        addSubview(mainContainer)
        mainContainer.pin(anchors: [.leading, .trailing, .top], to: layoutMarginsGuide)
        mainContainer.pin(anchors: [.bottom], to: safeAreaLayoutGuide)
        
        mainContainer.addArrangedSubviews([titleLabel, spacer, retryButton])
        mainContainer.axis = .horizontal
        mainContainer.alignment = .leading
    }
    
    @objc func didTapRetryButton() {
        buttonAction?()
    }
}
