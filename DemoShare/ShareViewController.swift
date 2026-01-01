//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import CoreServices
import Social
import StreamChat
import SwiftUI
import UIKit

class ShareViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let userCredentials = UserDefaults.shared.currentUser else {
            self.extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
            return
        }
                
        self.view.backgroundColor = .systemBackground
        let demoShareView = UIHostingController(
            rootView: DemoShareView(
                userCredentials: userCredentials,
                extensionContext: self.extensionContext
            )
        ).view!
        
        demoShareView.frame = view.frame
        self.view.addSubview(demoShareView)
    }
}
