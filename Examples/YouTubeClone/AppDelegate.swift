//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import AVKit
import StreamChat
import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = SplashViewController { [unowned window] in
            window.rootViewController = UINavigationController(
                rootViewController: YTLiveVideoViewController()
            )
        }
        window.makeKeyAndVisible()
        self.window = window

        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playback, mode: .moviePlayback)
        } catch {
            print("Setting category to AVAudioSessionCategoryPlayback failed.")
        }

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
        userInfo: UserInfo = .init(id: "sagar"),
        token: Token = .development(userId: "sagar"),
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
