//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import UIKit

public class ContainerStackView: UIStackView {
    
    // MARK: - Subviews
    
    public let topStackView = UIStackView()
    public let bottomStackView = UIStackView()
    public let leadingStackView = UIStackView()
    public let trailingStackView = UIStackView()
    public let centerStackView = UIStackView()
        
    // MARK: - Init

    override public init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    public required init(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    private func commonInit() {
        distribution = .fill
        axis = .vertical
        alignment = .fill
        translatesAutoresizingMaskIntoConstraints = false
        
        let centerContainerStackView = UIStackView()
        centerContainerStackView.distribution = .fill
        centerContainerStackView.axis = .horizontal
        centerContainerStackView.alignment = .fill
        centerContainerStackView.translatesAutoresizingMaskIntoConstraints = false
        
        centerContainerStackView.addArrangedSubview(leadingStackView)
        centerContainerStackView.addArrangedSubview(centerStackView)
        centerContainerStackView.addArrangedSubview(trailingStackView)
        
        addArrangedSubview(topStackView)
        addArrangedSubview(centerContainerStackView)
        addArrangedSubview(bottomStackView)
        
        [topStackView, bottomStackView, leadingStackView, trailingStackView, centerStackView].forEach {
            $0.isHidden = true
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
    }
}

extension UIStackView {
    func addArranged(subview: UIView, spacingAfter: CGFloat = 0, offset: CGPoint = .zero) {
        subview.bounds.origin.x += offset.x
        subview.bounds.origin.y += offset.y
        addArrangedSubview(subview)
        // TODO: https://stackoverflow.com/questions/33073127/nested-uistackviews-broken-constraints
        setCustomSpacing(spacingAfter, after: subview)
    }
    
    func addSpacer() {
        let spacerView = UIView()
        spacerView.setContentHuggingPriority(.defaultLow, for: .horizontal)
        spacerView.setContentHuggingPriority(.defaultLow, for: .vertical)
        addArrangedSubview(spacerView)
    }
}
