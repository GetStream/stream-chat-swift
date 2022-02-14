//
//  ChatAddFriendVC.swift
//  Timeless-wallet
//
//  Created by Jitendra Sharma on 08/02/22.
//

import Nuke
import StreamChat
import StreamChatUI
import UIKit

public class ChatAddFriendVC: ChatBaseVC {
    
    public enum SelectionType {
        case addFriend,inviteUser
        var title: String {
            switch self {
            case .addFriend: return "Add Friends"
            case .inviteUser: return "Invite Friends"
            }
        }
    }
    // MARK: - OUTLETS
    @IBOutlet private var titleLabel: UILabel!
    @IBOutlet private var viewHeaderTitleView: UIView!
    @IBOutlet private var viewHeaderView: UIView!
    @IBOutlet private var viewHeaderViewHeightConst: NSLayoutConstraint!
    @IBOutlet private var viewHeaderViewTopConst: NSLayoutConstraint!
    @IBOutlet private var searchFieldStack: UIStackView!
    @IBOutlet private var searchBarContainerView: UIView!
    @IBOutlet private var tableviewContainerView: UIView!
    @IBOutlet private var searchField: UITextField!
    @IBOutlet private var mainStackView: UIStackView!
    // MARK: - VARIABLES
    public var selectionType = ChatAddFriendVC.SelectionType.addFriend
    public lazy var chatUserList: ChatUserListVC = {
        let obj = ChatUserListVC.instantiateController(storyboard: .GroupChat) as? ChatUserListVC
        return obj!
    }()
    private var curentSortType: Em_ChatUserListFilterTypes = .sortByLastSeen
    private var isFullScreen = false
    public var selectedUsers = [ChatUser]()
    public var bCallbackAddUser:(([ChatUser]) -> Void)?
    // MARK: - VIEW CYCLE
    public override func viewDidLoad() {
        super.viewDidLoad()
        setup()
    }
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.view.layoutIfNeeded()
        chatUserList.tableViewFrameUpdate()
    }
    // MARK: - METHODS
    public func setup() {
        //
        self.view.backgroundColor = .clear
        self.titleLabel.text = selectionType.title
        //
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(viewDidDrag(_:)))
        viewHeaderTitleView.addGestureRecognizer(panGesture)
        //
        btnBack?.setImage(Appearance.Images.closeCircle, for: .normal)
        btnNext?.isEnabled = !self.selectedUsers.isEmpty
        //
        self.searchField.addTarget(self, action: #selector(textDidChange(_:)), for: .editingChanged)
        //
        addChild(chatUserList)
        tableviewContainerView.addSubview(chatUserList.view)
        chatUserList.didMove(toParent: self)
        tableviewContainerView.updateChildViewContraint(childView: chatUserList.view)
        chatUserList.delegate = self
        chatUserList.userSelectionType = .addFriend
        chatUserList.tableViewFrameUpdate()
        chatUserList.curentSortType = .sortByAtoZ
        chatUserList.fetchUserList()
        //
        viewHeaderView.backgroundColor = Appearance.default.colorPalette.viewBackgroundLightBlack
        searchBarContainerView.backgroundColor = Appearance.default.colorPalette.searchBarBackground
        //
        searchBarContainerView.layer.cornerRadius = 20.0
        viewHeaderView.layer.cornerRadius = 20.0
    }
    //
    @objc private func textDidChange(_ sender: UITextField) {
        self.chatUserList.searchDataUsing(searchString: sender.text)
    }
    @objc private func addPangGesture(_ sender: UIPanGestureRecognizer) {
        UIView.animate(withDuration: 0.1) {
            if self.isFullScreen {
                self.viewHeaderViewTopConst.priority = .defaultLow
                self.viewHeaderViewHeightConst.priority = .defaultHigh
                //self.isFullScreen = false
            } else {
                //self.isFullScreen = true
                self.viewHeaderViewTopConst.priority = .defaultHigh
                self.viewHeaderViewHeightConst.priority = .defaultLow
            }
            self.view.layoutIfNeeded()
        }
    }
    @objc private func viewDidDrag(_ sender: UIPanGestureRecognizer) {
        
        let velocity = sender.velocity(in: viewHeaderTitleView)
        
        if velocity.y > 0 {
            self.isFullScreen = true
            self.addPangGesture(sender)
        } else if velocity.y < 0  {
            self.isFullScreen = false
            self.addPangGesture(sender)
        }
    }
    //
    // MARK: - Actions
    //
    @IBAction private func btnBackAction(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }
    @IBAction private func invitLinkAction(_ sender: UIButton) {
        //
    }
    // swiftlint:disable redundant_type_annotation
    @IBAction private func btnDoneAction(_ sender: UIButton) {
        if self.selectedUsers.count > 0 {
            self.bCallbackAddUser?(self.selectedUsers)
            self.btnBackAction(sender)
        }
    }
    //
}

// MARK: - ChatUserListDelegate
extension ChatAddFriendVC: ChatUserListDelegate {
    public func chatListStateUpdated(state: ChatUserListVC.ChatUserLoadingState) {
        
    }
    public func chatUserDidSelect() {
        self.selectedUsers = self.chatUserList.selectedUsers
        self.btnNext?.isEnabled = !self.selectedUsers.isEmpty
    }
}
