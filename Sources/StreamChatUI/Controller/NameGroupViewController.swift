//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation
import Nuke
import StreamChat
import StreamChatUI
import UIKit

private let GroupNameLimit = 40
private let HashtagNameLimit = 100

public class NameGroupViewController: ChatBaseVC {
    // MARK: - OUTLETS
    @IBOutlet private var searchFieldStack: UIStackView!
    @IBOutlet private var nameContainerView: UIView!
    @IBOutlet private var descriptionContainerView: UIView!
    @IBOutlet private var nameField: UITextField!
    @IBOutlet private var groupDescriptionField: UITextField!
    @IBOutlet private var lblFriendCount: UILabel!
    @IBOutlet private var lblTitle: UILabel!
    @IBOutlet private var lblGroupNameCount: UILabel!
    @IBOutlet private var lblHashtagCount: UILabel!
    @IBOutlet private var tableView: UITableView!
    @IBOutlet private var tagView: UIStackView!
    @IBOutlet private var tagViewPlaceHolderView: UIView!
    // MARK: - VARIABLES
    public var client: ChatClient?
    public var selectedUsers: [ChatUser]!
    public var bCallbackSelectedUsers:(([ChatUser]) -> Void)?
    // MARK: - VIEW CYCLE
    public override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    // MARK: - METHODS
    public func setupUI() {
        self.view.backgroundColor = Appearance.default.colorPalette.viewBackgroundLightBlack
        self.nameField.autocorrectionType = .no
        self.nameField.addTarget(self, action: #selector(textDidChange(_:)), for: .editingChanged)
        groupDescriptionField.addTarget(self, action: #selector(textDidChange(_:)), for: .editingChanged)
        //
        groupDescriptionField.delegate = self
        nameField.delegate = self
        nameField.becomeFirstResponder()
        nameContainerView.layer.cornerRadius = 6.0
        descriptionContainerView.layer.cornerRadius = 6.0
        
        let str = self.selectedUsers.count > 1 ? "friends" : "friend"
        lblFriendCount.text = "\(self.selectedUsers.count) \(str)"
        //
        navigationController?.navigationBar.isHidden = true
        lblTitle.textColor = .white
        //
        lblTitle.text = "New Chat"
        //
        nameField.placeholder = "Group chat name"
        //
        let chatUserID = TableViewCellChatUser.reuseId
        let chatUserNib = UINib(nibName: chatUserID, bundle: nil)
        tableView?.register(chatUserNib, forCellReuseIdentifier: chatUserID)
        //
        tableView.dataSource = self
        tableView.bounces = false
        tableView.tableFooterView = UIView()
        tableView.reloadData()
        tableView.separatorStyle = .none
    }
    // MARK: - ACTIONS
    @objc private func textDidChange(_ sender: UITextField) {
        if sender == nameField {
            DispatchQueue.main.async {
                self.lblGroupNameCount.text = "\(sender.text?.count ?? 0)"
            }
        } else {
            DispatchQueue.main.async {
                self.lblHashtagCount.text = "\(sender.text?.count ?? 0)"
            }
        }
    }
    //
    @IBAction func backBtnTapped(_ sender: UIButton) {
        navigationController?.popViewController(animated: true)
    }

    @IBAction func doneTapped(_ sender: UIButton) {
        //
        self.view.endEditing(true)
        //
        
        guard let name = nameField.text, !name.isEmpty else {
            Snackbar.show(text: "Name cannot be empty")
            return
        }
        do {
            
            let channelController = try ChatClient.shared.channelController(
                createChannelWithId: .init(type: .messaging, id: String(UUID().uuidString.prefix(10))),
                name: name,
                members: Set(selectedUsers.map(\.id)), extraData: [kExtraDataChannelDescription: .string(self.groupDescriptionField.text ?? "")])
            
            channelController.synchronize { [weak self] error in
                guard let weakSelf = self else {
                    return
                }
                if let error = error {
                    DispatchQueue.main.async {
                        Snackbar.show(text: error.localizedDescription)
                    }
                } else {
                    //
                    DispatchQueue.main.async {
        
                        let chatChannelVC = ChatChannelVC.init()
                        chatChannelVC.isChannelCreated = true
                        chatChannelVC.channelController = channelController
                        
                        weakSelf.navigationController?.pushViewController(chatChannelVC, animated: true)
                        
                        let navControllers = weakSelf.navigationController?.viewControllers ?? []
                        
                        for (index,navController) in navControllers.enumerated() {
                            if index == 0 || navController.isKind(of: ChatChannelVC.self) {
                                continue
                            }
                            navController.removeFromParent()
                        }
                    }
                }
            }
        } catch {
            Snackbar.show(text: "Error when creating the channel")
        }
    }
}
// MARK: - UITextFieldDelegate
extension NameGroupViewController: UITextFieldDelegate {
    
    public func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if textField == nameField {
            let maxLength = 40
            let currentString: NSString = (textField.text ?? "") as NSString
            let newString: NSString =
                currentString.replacingCharacters(in: range, with: string) as NSString
            return newString.length <= maxLength
        } else {
            let maxLength = 100
            let currentString: NSString = (textField.text ?? "") as NSString
            let newString: NSString =
                currentString.replacingCharacters(in: range, with: string) as NSString
            return newString.length <= maxLength
        }
    }
}

// MARK: - TABLEVIEW
extension NameGroupViewController: UITableViewDataSource {
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        selectedUsers.count
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let reuseID = TableViewCellChatUser.reuseId
        //
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: reuseID,
            for: indexPath) as? TableViewCellChatUser else {
            return UITableViewCell()
        }
        //
        let user: ChatUser = selectedUsers[indexPath.row]
        //
        cell.config(user: user,
                        selectedImage: nil,
                        avatarBG: view.tintColor)
        cell.backgroundColor = .clear
        return cell

    }
    
    public func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    public func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if (editingStyle == .delete) {
            self.selectedUsers.remove(at: indexPath.row)
            self.tableView.reloadData()
            self.bCallbackSelectedUsers?(self.selectedUsers)
            if self.selectedUsers.isEmpty {
                self.navigationController?.popViewController(animated: false)
            }
        }
    }
}
// MARK: - Generic View Class
class ViewWithRadius: UIView {}
