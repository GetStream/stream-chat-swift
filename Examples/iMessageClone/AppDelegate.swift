//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import StreamChat
import StreamChatUI
import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = UINavigationController(
            rootViewController: SplashViewController { [unowned window] in
                window.rootViewController = UINavigationController(
                    rootViewController: iMessageChatChannelListViewController()
                )
            }
        )
        window.makeKeyAndVisible()
        self.window = window

        return true
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
