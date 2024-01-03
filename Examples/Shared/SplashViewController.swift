//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChat
import UIKit

final class SplashViewController: UIViewController {
    private let userInfo: UserInfo
    private let token: Token
    private let completionHandler: () -> Void
    
    private lazy var activityIndicatorView: UIActivityIndicatorView = .init(style: .large)
    private lazy var cancellationLabel: UILabel = {
        let label = UILabel()
        label.text = "No connected user found.\nTap the button below to try connect the user with id \(userInfo.id)."
        label.font = .preferredFont(forTextStyle: .callout)
        label.textAlignment = .center
        label.textColor = .black
        label.numberOfLines = 0
        return label
    }()

    private lazy var actionButton: UIButton = {
        let button = UIButton(configuration: .filled())
        button.setTitle("Connect User", for: .normal)
        button.addAction(.init(handler: { [weak self] _ in self?.connectUser() }), for: .touchUpInside)
        return button
    }()

    private lazy var stackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [
            cancellationLabel,
            actionButton
        ])
        stackView.axis = .vertical
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()
    
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
        
        connectUser()
    }
    
    private func connectUser() {
        showActivityIndicatorView()
        
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
            title: "Cancel",
            style: .cancel,
            handler: { [weak self] _ in
                self?.showCancellationLabel()
            }
        ))
        alertController.addAction(.init(
            title: "Retry",
            style: .default,
            handler: { [weak self] _ in
                self?.connectUser()
            }
        ))
        
        present(alertController, animated: true)
    }
    
    private func showActivityIndicatorView() {
        stackView.removeFromSuperview()
        activityIndicatorView.startAnimating()
        activityIndicatorView.center = view.center
        view.addSubview(activityIndicatorView)
    }
    
    private func showCancellationLabel() {
        activityIndicatorView.removeFromSuperview()
        view.addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            stackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            stackView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16)
        ])
    }
}
