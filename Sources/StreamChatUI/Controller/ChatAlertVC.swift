//
//  ChatAlertVC.swift
//  Pods
//
//  Created by Jitendra Sharma on 14/02/22.
//

import UIKit

public class ChatAlertVC: UIViewController {
    
    public struct DataModel {
        let title: String
        let message: String
        let actionButtonTitle: String
    }
    //
    public enum AlertType {
        case leaveChatRoom
        case deleteGroup
        //
        var data: DataModel {
            switch self {
            case .leaveChatRoom:
                return DataModel(title: "Leave Chatroom", message: "Are you sure you want to leave this chatroom? If you leave, your chat history will be permanently deleted.", actionButtonTitle: "Leave Chatroom")
            case .deleteGroup:
                return DataModel(title: "Delete Group", message: "Are you sure you want to delete and leave the chatroom? This action cannot be undone and all chat history will be permanently deleted.", actionButtonTitle: "Delete Chatroom")
            }
        }
    }
    //MARK: - OUTLETS
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var messageLabel: UILabel!
    @IBOutlet private weak var actionButton: UIButton!
    @IBOutlet private weak var cancelButton: UIButton!
    @IBOutlet private weak var containerView: UIView!
    @IBOutlet private weak var backgroundView: UIView!
    //MARK: - VARIABLES
    var alertType: ChatAlertVC.AlertType!
    var bCallbackActionHandler:(() -> Void)?
    
    //MARK: - VIEW CYCLE
    public override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    //MARK: - METHODS
    private func setupUI() {
        self.titleLabel.text = self.alertType.data.title
        self.messageLabel.text = self.alertType.data.message
        self.actionButton.setTitle(self.alertType.data.actionButtonTitle, for: .normal)
        self.containerView.layer.cornerRadius = 30.0
        self.actionButton.layer.cornerRadius = actionButton.bounds.height/2
        self.cancelButton.layer.cornerRadius = actionButton.bounds.height/2
        let tapGesture = UITapGestureRecognizer.init(target: self, action: #selector(backgroundViewAction))
        tapGesture.numberOfTapsRequired = 1
        self.backgroundView.addGestureRecognizer(tapGesture)
    }
    // TO DO
    @objc func backgroundViewAction() {
        //self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func actionButton(_ sender: UIButton) {
        self.bCallbackActionHandler?()
        self.cancelButtonAction(sender)
    }
    
    @IBAction func cancelButtonAction(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }
}
