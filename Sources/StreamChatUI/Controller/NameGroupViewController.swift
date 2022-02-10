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

    public var client: ChatClient?
    @IBOutlet private var searchFieldStack: UIStackView!
    @IBOutlet private var nameContainerView: UIView!
    @IBOutlet private var descriptionContainerView: UIView!
    @IBOutlet private var nameField: UITextField!
    @IBOutlet private var groupDescriptionField: UITextField!
    
    //
    @IBOutlet private var lblFriendCount: UILabel!
    @IBOutlet private var lblTitle: UILabel!
    @IBOutlet private var lblGroupNameCount: UILabel!
    @IBOutlet private var lblHashtagCount: UILabel!
    //
    @IBOutlet private var tableView: UITableView!
    //
    @IBOutlet private var tagView: UIStackView!
    @IBOutlet private var tagViewPlaceHolderView: UIView!
    //
    public var selectedUsers: [ChatUser]!
    //
    //private let tagsField = WSTagsField()
    //
    public var bCallbackSelectedUsers:(([ChatUser]) -> Void)?
    
    //
    public override func viewDidLoad() {
        super.viewDidLoad()
        //
        setupUI()
        //
        configureTagView()
    }
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        //tagsField.beginEditing()
    }
    
    public func setupUI() {
        self.view.backgroundColor = Appearance.default.colorPalette.viewBackgroundLightBlack
        //
        self.nameField.autocorrectionType = .no
        self.nameField.addTarget(self, action: #selector(textDidChange(_:)), for: .editingChanged)
        groupDescriptionField.addTarget(self, action: #selector(textDidChange(_:)), for: .editingChanged)
        groupDescriptionField.delegate = self
        nameField.delegate = self
        
        
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
        // An old trick to force the table view to hide empty lines
        tableView.tableFooterView = UIView()
        tableView.reloadData()
        tableView.separatorStyle = .none
    }
    //
    private func updateTagViewPlaceholder() {
        //self.tagViewPlaceHolderView.isHidden = (self.tagsField.tags.isEmpty && self.tagsField.textField.text?.isBlank ?? true) ? false : true
    }
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
            presentAlert(title: "Name cannot be empty")
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
                    weakSelf.presentAlert(title: "Error when creating the channel", message: error.localizedDescription)
                } else {
                    //
                    DispatchQueue.main.async {
                        weakSelf.navigationController?.popToRootViewController(animated: true)
                        let chatChannelVC = ChatChannelVC.init()
                        chatChannelVC.channelController = channelController
                        weakSelf.navigationController?.pushViewController(chatChannelVC, animated: true)
                    }
                }
            }
        } catch {
            presentAlert(title: "Error when creating the channel", message: error.localizedDescription)
        }
    }
}

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
// MARK: - TAGVIEW
extension NameGroupViewController {
    //
    private func configureTagView() {
        //
//        tagView.addArrangedSubview(tagsField)
//        tagsField.isScrollEnabled = false
//        //tagsField.suggestions = ["#intro", "#using", "#hashtags"]
//        tagsField.layoutMargins = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
//        tagsField.contentInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
//        tagsField.spaceBetweenLines = 15.0
//        tagsField.spaceBetweenTags = 10.0
//        //tagsField.cornerRadius = 5.0
//        tagsField.font = .systemFont(ofSize: 12.0)
//        tagsField.backgroundColor = .clear
//        self.tagsField.textField.tintColor = .white
//        tagsField.tintColor = UIColor.tabbarBackground
//        tagsField.textColor = .white
//        tagsField.fieldTextColor = .white
////        tagsField.selectedColor = .black
////        tagsField.selectedTextColor = .red
//        tagsField.delimiter = ""
//        tagsField.isDelimiterVisible = false
//        tagsField.placeholder = ""
//        tagsField.placeholderColor = .green
//        tagsField.placeholderAlwaysVisible = false
//        tagsField.keyboardAppearance = .dark
//        tagsField.returnKeyType = .next
//        tagsField.acceptTagOption = .space
//        tagsField.shouldTokenizeAfterResigningFirstResponder = true
//
//        // Events
//        tagsField.onDidAddTag = { field, tag in
//            print("DidAddTag", tag.text)
//
//        }
//        tagsField.onDidSelectTagView = { field, tag in
//            self.tagsField.removeTag(tag.displayText)
//        }
//        //
//        tagsField.onDidRemoveTag = { field, tag in
//            print("DidRemoveTag", tag.text)
//            DispatchQueue.main.async {
//                self.tagsField.textField.becomeFirstResponder()
//                self.updateTagViewPlaceholder()
//            }
//        }
//        //
//        tagsField.onDidChangeText = { _, text in
//            print("DidChangeText \(text)")
//            DispatchQueue.main.async {
//                self.updateTagViewPlaceholder()
//                self.lblHashtagCount.text = "\(text?.count ?? 0)"
//            }
//        }
//        //
//        tagsField.onDidChangeHeightTo = { _, height in
//            print("HeightTo", height)
//        }
//        //
//        tagsField.onValidateTag = { tag, tags in
//            // custom validations, called before tag is added to tags list
//            return tag.text != "#" && !tags.contains(where: { $0.text.uppercased() == tag.text.uppercased() })
//        }
//        //
//        print("List of Tags Strings:", tagsField.tags.map({$0.text}))
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

class ViewWithRadius: UIView {
    //
//    private var cornerRadiusValue: CGFloat = 20
//    //
//    override init(frame: CGRect) {
//        super.init(frame: frame)
//        commonInit()
//    }
//    
//    required init?(coder aDecoder: NSCoder) {
//        super.init(coder: aDecoder)
//        commonInit()
//    }
//    override func draw(_ rect: CGRect) {
//        super.draw(rect)
//        layer.cornerRadius = cornerRadiusValue
//    }
//    func commonInit(value: CGFloat = 20) {
//        //
//        layer.cornerRadius = value
//    }
}
