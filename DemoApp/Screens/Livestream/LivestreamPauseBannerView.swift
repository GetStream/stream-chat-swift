//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import StreamChatUI
import UIKit

/// A banner view that displays the chat pause state and resuming status for livestream channels.
class LivestreamPauseBannerView: UIView {
    enum BannerState {
        case paused
        case resuming
    }
    
    private lazy var label: UILabel = {
        let label = UILabel()
        label.font = appearance.fonts.footnote
        label.textColor = appearance.colorPalette.text
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private var appearance: Appearance {
        Appearance.default
    }
    
    /// Current state of the banner.
    private(set) var currentState: BannerState = .paused
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    private func setupView() {
        backgroundColor = appearance.colorPalette.background2
        layer.cornerRadius = 12
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = CGSize(width: 0, height: 2)
        layer.shadowOpacity = 0.1
        layer.shadowRadius = 4
        translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(label)
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            label.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            label.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8)
        ])

        isHidden = true
        alpha = 0.0
        
        setState(.paused)
    }
    
    /// Updates the banner state and text.
    /// - Parameter state: The new state to display.
    func setState(_ state: BannerState) {
        currentState = state
        
        switch state {
        case .paused:
            label.text = "Chat paused due to scroll"
        case .resuming:
            label.text = "Resuming..."
        }
    }
    
    /// Shows or hides the banner with animation.
    /// - Parameters:
    ///   - show: Whether to show or hide the banner.
    ///   - animated: Whether to animate the transition.
    func setVisible(_ show: Bool, animated: Bool = true) {
        guard animated else {
            isHidden = !show
            alpha = show ? 1.0 : 0.0
            return
        }
        
        UIView.animate(withDuration: 0.3) {
            self.isHidden = !show
            self.alpha = show ? 1.0 : 0.0
        }
    }
}
