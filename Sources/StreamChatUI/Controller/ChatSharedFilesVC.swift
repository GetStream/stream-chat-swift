//
//  ChatSharedFilesVC.swift
//  Timeless-wallet
//
//  Created by Jitendra Sharma on 08/02/22.
//

import UIKit

class ChatSharedFilesVC: UIViewController {
    //
    enum FileType: Int {
        case media = 0
        case files = 1
        case link = 2
    }
    //
    @IBOutlet private weak var lblEmpty: UILabel!
    //
    override func viewDidLoad() {
        super.viewDidLoad()
        //
        self.view.backgroundColor = .clear
    }

    func setFileType(type: ChatSharedFilesVC.FileType) {
        //
        switch type {
        case .media:
            self.lblEmpty.text = "No media available"
        case .files:
            self.lblEmpty.text = "No files available"
        case .link:
            self.lblEmpty.text = "No link available"
        }
    }
}
