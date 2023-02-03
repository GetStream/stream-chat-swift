//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChat
import UIKit

final class SplashViewController: UIViewController {
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
        
        connectUser()
    }
    
    private func connectUser() {
        ChatClient.shared.connectUser(
            userInfo: userInfo,
            token: token
        ) { [weak self] error in
            DispatchQueue.main.async {
                if let error {
                    self?.presentAlert(with: error)
                } else {
                    self?.completionHandler()
                }
            }
        }
    }
    
    private func presentAlert(
        with error: Error
    ) {
        let alertController = UIAlertController(
            title: "Error",
            message: error.localizedDescription,
            preferredStyle: .alert
        )
        
        alertController.addAction(.init(
            title: nil,
            style: .cancel
        ))
        alertController.addAction(.init(
            title: "Retry",
            style: .default,
            handler: { [weak self] _ in
                self?.connectUser()
            }
        )
        )
        
        present(alertController, animated: true)
    }
}
