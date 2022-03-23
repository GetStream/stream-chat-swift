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
    @IBOutlet weak var heightSafeAreaView: NSLayoutConstraint!
    
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
        heightSafeAreaView.constant = UIView.safeAreaTop
        navigationController?.navigationBar.isHidden = true
        self.btnNext?.isHidden = true
        self.view.backgroundColor = Appearance.default.colorPalette.chatViewBackground
        self.nameField.autocorrectionType = .no
        self.nameField.addTarget(self, action: #selector(textDidChange(_:)), for: .editingChanged)
        groupDescriptionField.addTarget(self, action: #selector(textDidChange(_:)), for: .editingChanged)
        nameField.canPerformAction(#selector(UIResponderStandardEditActions.paste(_:)), withSender: nil)
        groupDescriptionField.canPerformAction(#selector(UIResponderStandardEditActions.paste(_:)), withSender: nil)
        nameField.delegate = self
        groupDescriptionField.delegate = self
        nameField.tintColor = Appearance.default.colorPalette.statusColorBlue
        groupDescriptionField.tintColor = Appearance.default.colorPalette.statusColorBlue
        nameField.becomeFirstResponder()
        nameContainerView.layer.cornerRadius = 6.0
        descriptionContainerView.layer.cornerRadius = 6.0
        let str = self.selectedUsers.count > 1 ? "friends" : "friend"
        lblFriendCount.text = "\(self.selectedUsers.count) \(str)"
        lblTitle.setChatNavTitleColor()
        lblTitle.text = "New Chat"
        nameField.placeholder = "Group chat name"
        let chatUserID = TableViewCellChatUser.reuseId
        let chatUserNib = UINib(nibName: chatUserID, bundle: nil)
        tableView?.register(chatUserNib, forCellReuseIdentifier: chatUserID)
        //
        tableView.dataSource = self
        tableView.bounces = false
        tableView.tableFooterView = UIView()
        tableView.reloadData()
        tableView.separatorStyle = .none
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: UIView.safeAreaBottom, right: 0)
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
        let name = self.nameField.text ?? ""
        let description = self.groupDescriptionField.text ?? ""
        if name.isBlank || description.isBlank || name.containsEmoji || description.containsEmoji {
            self.btnNext?.isHidden = true
        } else {
            self.btnNext?.isHidden = false
        }
    }
    
    @IBAction func backBtnTapped(_ sender: UIButton) {
        popWithAnimation()
    }

    @IBAction func doneTapped(_ sender: UIButton) {
        self.view.endEditing(true)
        guard let name = nameField.text, !name.isEmpty else {
            Snackbar.show(text: "Group name cannot be blank")
            return
        }
        guard name.containsEmoji == false else {
            Snackbar.show(text: "Please enter valid group name")
            return
        }
        let groupId = String(UUID().uuidString)
        let encodeGroupId = groupId.base64Encoded.string ?? ""
        let expiryDate = String(Date().withAddedHours(hours: 24).ticks).base64Encoded.string ?? ""
        var extraData: [String: RawJSON] = [:]
        extraData[kExtraDataChannelDescription] = RawJSON.string(self.groupDescriptionField.text ?? "")
        // Deeplink url Callback
        ChatClientConfiguration.shared.requestedGeneralGroupDynamicLink = { [weak self] url in
            guard let weakSelf = self else { return }
            guard let groupInviteLink = url else {
                return
            }
            ChatClientConfiguration.shared.requestedGeneralGroupDynamicLink = nil
            extraData["joinLink"] = .string(groupInviteLink.absoluteString)
            do {
                let channelController = try ChatClient.shared.channelController(
                    createChannelWithId: .init(type: .messaging, id: groupId),
                    name: name,
                    members: Set(weakSelf.selectedUsers.map(\.id)), extraData: extraData)
                // Channel synchronize
                channelController.synchronize { [weak self] error in
                    guard let weakSelf = self , error == nil else {
                        DispatchQueue.main.async {
                            Snackbar.show(text: "something went wrong!")
                        }
                        return
                    }
                    DispatchQueue.main.async {
                        let chatChannelVC = ChatChannelVC.init()
                        chatChannelVC.isChannelCreated = true
                        chatChannelVC.channelController = channelController
                        weakSelf.pushWithAnimation(controller: chatChannelVC)
                        let navControllers = weakSelf.navigationController?.viewControllers ?? []
                        for (index,navController) in navControllers.enumerated() {
                            if index == 0 || navController.isKind(of: ChatChannelVC.self) {
                                continue
                            }
                            navController.removeFromParent()
                        }
                    }
                }
            } catch {
                Snackbar.show(text: "Error while creating the channel")
            }
        }
        // Fetching invite link
        let parameter = [kInviteGroupID: encodeGroupId, kInviteExpiryDate: expiryDate]
        NotificationCenter.default.post(name: .generalGroupInviteLink, object: nil, userInfo: parameter)
    }
}
// MARK: - UITextFieldDelegate
extension NameGroupViewController: UITextFieldDelegate {
    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    public func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if textField == nameField {
            let maxLength = 40
            let currentString: NSString = (textField.text ?? "") as NSString
            let newString: NSString =
                currentString.replacingCharacters(in: range, with: string) as NSString
            let status = newString.length <= maxLength
            if !status {
                self.nameContainerView.shake()
            }
            return status
        } else {
            let maxLength = 100
            let currentString: NSString = (textField.text ?? "") as NSString
            let newString: NSString =
                currentString.replacingCharacters(in: range, with: string) as NSString
            let status = newString.length <= maxLength
            if !status {
                self.descriptionContainerView.shake()
            }
            return status
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
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: reuseID,
            for: indexPath) as? TableViewCellChatUser else {
            return UITableViewCell()
        }
        let user: ChatUser = selectedUsers[indexPath.row]
        cell.config(user: user,selectedImage: nil)
        cell.backgroundColor = .clear
        return cell

    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
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
                self.popWithAnimation()
            }
        }
    }
}
// MARK: - Generic View Class
class ViewWithRadius: UIView {}
// MARK: - UITextField extension
extension UITextField {
    open override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        return true
    }
    
    public func setAttributedPlaceHolder(placeHolder: String) {
        let attributeString = [
            NSAttributedString.Key.foregroundColor: Appearance.default.colorPalette.searchPlaceHolder,
            NSAttributedString.Key.font: UIFont.systemFont(ofSize: 16, weight: .regular)
        ] as [NSAttributedString.Key : Any]
        self.attributedPlaceholder = NSAttributedString(string: placeHolder, attributes: attributeString)
    }
}
