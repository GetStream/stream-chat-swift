//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation
import UIKit
import StreamChat

final class DebugMenu {

    static let shared = DebugMenu()

    func showMenu(in viewController: UIViewController, channelController: ChatChannelController) {
        presentAlert(in: viewController,
                     title: "Select an action",
                     actions: [
                        .init(title: "Add member", style: .default, handler: { [unowned self] _ in
                            self.presentAlert(in: viewController,
                                              title: "Enter user id",
                                              textFieldPlaceholder: "User ID") { id in
                                guard let id = id, !id.isEmpty else {
                                    self.presentAlert(in: viewController, title: "User ID is not valid", actions: [])
                                    return
                                }
                                channelController.addMembers(userIds: [id]) { [unowned self] error in
                                    if let error = error {
                                        self.presentAlert(
                                            in: viewController,
                                            title: "Couldn't add user \(id) to channel \(String(describing: channelController.cid))",
                                            message: "\(error)",
                                            actions: []
                                        )
                                    }
                                }
                            }
                        }),
                        .init(title: "Remove a member",
                              style: .default,
                              handler: { [unowned self] _ in
                                  let actions = channelController.channel?.lastActiveMembers.map { member in
                                      UIAlertAction(title: member.id, style: .default) { _ in
                                          channelController.removeMembers(userIds: [member.id]) { [unowned self] error in
                                              if let error = error {
                                                  self.presentAlert(
                                                    in: viewController,
                                                    title: "Couldn't remove user \(member.id) from channel \(String(describing: channelController.cid))",
                                                    message: "\(error)",
                                                    actions: []
                                                  )
                                              }
                                          }
                                      }} ?? []
                                  self.presentAlert(in: viewController,
                                                    title: "Select a member",
                                                    actions: actions)
                              }),
                        .init(title: "Show Members",
                              style: .default,
                              handler: { [unowned self] _ in
                                  self.presentAlert(in: viewController,
                                                    title: "Members",
                                                    message: channelController.channel?.lastActiveMembers.map(\.name).debugDescription,
                                                    actions: []
                                  )
                        })
                     ])
    }

    func presentAlert(in viewController: UIViewController,
                      title: String?,
                      message: String? = nil,
                      actions: [UIAlertAction],
                      cancelHandler: (() -> Void)? = nil) {
        let alert = UIAlertController(
            title: title,
            message: message,
            preferredStyle: .alert
        )

        actions.forEach { alert.addAction($0) }
        alert.addAction(.init(title: "Cancel", style: .destructive, handler: { _ in
            cancelHandler?()
        }))

        viewController.present(alert, animated: true, completion: nil)
    }

    func presentAlert(
        in viewController: UIViewController,
        title: String?,
        message: String? = nil,
        textFieldPlaceholder: String? = nil,
        okHandler: @escaping ((String?) -> Void),
        cancelHandler: (() -> Void)? = nil
    ) {
        let alert = UIAlertController(
            title: title,
            message: message,
            preferredStyle: .alert
        )

        alert.addTextField { textField in
            textField.placeholder = textFieldPlaceholder
            textField.accessibilityIdentifier = "debug_alert_textfield"
        }

        alert.addAction(.init(title: "OK", style: .default, handler: { _ in
            okHandler(alert.textFields?.first?.text)
        }))

        alert.addAction(.init(title: "Cancel", style: .destructive, handler: { _ in
            cancelHandler?()
        }))

        viewController.present(alert, animated: true, completion: nil)
    }

}
