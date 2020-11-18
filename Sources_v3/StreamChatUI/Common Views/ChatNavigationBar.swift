//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

open class ChatNavigationBar: UINavigationBar {
    override public init(frame: CGRect) {
        super.init(frame: frame)
        applyDefaultAppearance()
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        applyDefaultAppearance()
    }
}

// MARK: - AppearanceSetting
 
extension ChatNavigationBar: AppearanceSetting {
    public static func initialAppearanceSetup(_ bar: ChatNavigationBar) {
        let backIcon = UIImage(named: "icn_back", in: Bundle(for: Self.self), compatibleWith: nil)
        bar.backIndicatorTransitionMaskImage = backIcon
        bar.backIndicatorImage = backIcon
    }
}
