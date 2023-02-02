//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import StreamChat
import StreamChatUI
import SwiftUI
import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use a UIHostingController as window root view controller.
        if let windowScene = scene as? UIWindowScene {
            let window = UIWindow(windowScene: windowScene)
            window.rootViewController = SplashViewController { [unowned window] in
                window.rootViewController = UIHostingController(rootView: MessengerChatChannelList())
            }
            self.window = window
            window.makeKeyAndVisible()
        }
    }
}

private final class SplashViewController: UIViewController {
    private let userInfo: UserInfo
    private let token: Token
    private let completionHandler: () -> Void
    
    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    init(
        userInfo: UserInfo = .init(id: "user-1"),
        token: Token = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoiY2lsdmlhIn0.jHi2vjKoF02P9lOog0kDVhsIrGFjuWJqZelX5capR30",
        completionHandler: @escaping () -> Void
    ) {
        self.userInfo = userInfo
        self.token = token
        self.completionHandler = completionHandler
        super.init(nibName: nil, bundle: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .systemBackground
        let activityIndicatorView = UIActivityIndicatorView(style: .large)
        activityIndicatorView.startAnimating()
        activityIndicatorView.center = view.center
        view.addSubview(activityIndicatorView)
        
        ChatClient.shared.connectUser(
            userInfo: userInfo,
            token: token
        ) { [weak self] error in
            if let error {
                fatalError("Failed to connect user.(\(error.localizedDescription)")
            } else {
                DispatchQueue.main.async {
                    self?.completionHandler()
                }
            }
        }
    }
}
