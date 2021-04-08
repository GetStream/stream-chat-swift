//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import UIKit

@available(*, deprecated, message: "This view is deprecated and will be replaced by the new ContainerStackView.")
public class DeprecatedContainerStackView: UIStackView {
    // MARK: - Subviews
    
    public let topStackView = UIStackView()
    public let bottomStackView = UIStackView()
    public let leftStackView = UIStackView()
    public let rightStackView = UIStackView()
    public let centerStackView = UIStackView()
    
    public let centerContainerStackView = UIStackView()
        
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
        
        centerContainerStackView.distribution = .fill
        centerContainerStackView.axis = .horizontal
        centerContainerStackView.alignment = .fill
        centerContainerStackView.translatesAutoresizingMaskIntoConstraints = false
        
        centerContainerStackView.addArrangedSubview(leftStackView)
        centerContainerStackView.addArrangedSubview(centerStackView)
        centerContainerStackView.addArrangedSubview(rightStackView)
        
        addArrangedSubview(topStackView)
        addArrangedSubview(centerContainerStackView)
        addArrangedSubview(bottomStackView)
        
        [topStackView, bottomStackView, leftStackView, rightStackView, centerStackView].forEach {
            $0.isHidden = true
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
    }
}
