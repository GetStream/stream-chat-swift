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
    @IBOutlet private var viewContainerLeadingConst: NSLayoutConstraint!
    @IBOutlet private var viewContainerTrailingConst: NSLayoutConstraint!
    // MARK: - VARIABLES
    public var channelController: ChatChannelController!
    public var selectionType = ChatAddFriendVC.SelectionType.addFriend
    public lazy var chatUserList: ChatUserListVC = {
        let obj = ChatUserListVC.instantiateController(storyboard: .GroupChat) as? ChatUserListVC
        return obj!
    }()
    private var curentSortType: Em_ChatUserListFilterTypes = .sortByLastSeen
    private var isFullScreen = false
    public var selectedUsers = [ChatUser]()
    public var existingUsers = [ChatUser]()
    public var bCallbackAddFriend:(([ChatUser]) -> Void)?
    public var bCallbackInviteFriend:(([ChatUser]) -> Void)?
    public var groupInviteLink: String?
    private var isShortFormEnabled = true
    private lazy var panModelState: PanModalPresentationController.PresentationState = .shortForm
    // MARK: - VIEW CYCLE
    public override func viewDidLoad() {
        super.viewDidLoad()
        setup()
    }
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.view.layoutIfNeeded()
    }
    // MARK: - METHODS
    public func setup() {
        self.view.backgroundColor = .clear
        btnBack?.setImage(Appearance.Images.closeCircle, for: .normal)
        btnAddFriend?.setTitle("", for: .normal)
        btnAddFriend?.isEnabled = !self.selectedUsers.isEmpty
        btnInviteLink?.isEnabled = !self.selectedUsers.isEmpty
        btnAddFriend?.isHidden = selectionType == .inviteUser
        titleLabel.text = selectionType.title
        self.searchField.addTarget(self, action: #selector(textDidChange(_:)), for: .editingChanged)
        self.searchField.delegate = self
        
        addChild(chatUserList)
        tableviewContainerView.addSubview(chatUserList.view)
        chatUserList.didMove(toParent: self)
        tableviewContainerView.updateChildViewContraint(childView: chatUserList.view)
        chatUserList.delegate = self
        chatUserList.userSelectionType = .addFriend
        chatUserList.sortType = .sortByAtoZ
        chatUserList.viewModel.existingUsers = existingUsers
        chatUserList.viewModel.fetchUserList()
        viewContainerLeadingConst.constant = 5
        viewContainerTrailingConst.constant = 5
        setupUI()
    }
    
    private func setupUI() {
        let cornorRadius = viewContainerLeadingConst.constant > 0 ? 32 : 0
        
        viewHeaderView.backgroundColor = Appearance.default.colorPalette.chatViewBackground
        searchBarContainerView.backgroundColor = Appearance.default.colorPalette.searchBarBackground
        searchBarContainerView.layer.cornerRadius = 20.0
        viewHeaderView.layer.cornerRadius = CGFloat(cornorRadius)
    }
    
    @objc private func textDidChange(_ sender: UITextField) {
        self.chatUserList.viewModel.searchDataUsing(searchString: sender.text)
    }
    // MARK: - Actions
    @IBAction private func btnBackAction(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction private func invitLinkAction(_ sender: UIButton) {
        // TODO: Will add in future release
//        self.dismiss(animated: true, completion: nil)
//        guard let inviteLink = self.groupInviteLink else { return }
//        guard let shareInviteVC = ShareInviteLinkVC.instantiateController(storyboard: .GroupChat) as? ShareInviteLinkVC else {
//            return
//        }
//        shareInviteVC.groupInviteLink = self.groupInviteLink
//        shareInviteVC.channelController = self.channelController
//        shareInviteVC.selectedUsers = self.selectedUsers
//        shareInviteVC.callbackSelectedUser = { [weak self] users in
//            guard let weakSelf = self else { return }
//            weakSelf.selectedUsers = users
//            weakSelf.chatUserList.selectedUsers = users
//            weakSelf.chatUserList.reloadData()
//        }
//        let nav = UINavigationController(rootViewController: shareInviteVC)
//        nav.navigationBar.isHidden = true
//        nav.modalPresentationStyle = .overCurrentContext
//        nav.modalTransitionStyle = .crossDissolve
//        UIApplication.shared.getTopViewController()?.present(nav, animated: true, completion: nil)
//        UIApplication.shared.windows.first?.bringSubviewToFront(nav.view)
    }
    
    // swiftlint:disable redundant_type_annotation
    @IBAction private func btnDoneAction(_ sender: UIButton) {
        if self.selectedUsers.count > 0 {
            self.bCallbackAddFriend?(self.selectedUsers)
            self.btnBackAction(sender)
        }
    }
}
// MARK: - UITextFieldDelegate
extension ChatAddFriendVC: UITextFieldDelegate {
    public func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        if self.panModelState == .shortForm {
            panModalSetNeedsLayoutUpdate()
            panModalTransition(to: .longForm)
        }
        return true
    }
}
// MARK: - ChatUserListDelegate
extension ChatAddFriendVC: ChatUserListDelegate {
    public func chatUserDidSelect() {
        self.selectedUsers = self.chatUserList.viewModel.selectedUsers
        self.btnAddFriend?.isEnabled = !self.selectedUsers.isEmpty
        self.btnInviteLink?.isEnabled = !self.selectedUsers.isEmpty
    }
}
// MARK: - Pan Modal Presentable
extension ChatAddFriendVC: PanModalPresentable {
    public override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    public var panScrollable: UIScrollView? {
        return nil
    }
    public var shortFormHeight: PanModalHeight {
        return isShortFormEnabled ? .contentHeightIgnoringSafeArea(465) : longFormHeight
    }
    public var showDragIndicator: Bool {
        return false
    }
    public var allowsDragToDismiss: Bool {
        return true
    }
    public func willTransition(to state: PanModalPresentationController.PresentationState) {
        self.panModelState = state
        if state == .shortForm {
            viewContainerLeadingConst.constant = 5
            viewContainerTrailingConst.constant = 5
        } else {
            viewContainerLeadingConst.constant = 0
            viewContainerTrailingConst.constant = 0
        }
        setupUI()
        guard isShortFormEnabled, case .longForm = state
            else { return }

        isShortFormEnabled = false
        panModalSetNeedsLayoutUpdate()
    }
}
