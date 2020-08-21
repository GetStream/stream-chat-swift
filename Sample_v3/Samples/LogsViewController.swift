//
//  LogsViewController.swift
//  StreamChatClient
//
//  Created by Matheus Cardoso on 19/08/20.
//  Copyright © 2020 Stream.io Inc. All rights reserved.
//

import UIKit
import StreamChatClient

class LogsViewController: UIViewController {
    @IBOutlet weak var textView: UITextView!

    override func viewDidLoad() {
        super.viewDidLoad()
        updateText()
    }
    
    func updateText() {
        textView.text = LogStore.shared.logs
    }
    
    @IBAction func clearButtonPressed(_ sender: UIBarButtonItem) {
        LogStore.shared.logs = ""
        updateText()
    }
    
    @IBAction func downButtonPressed(_ sender: Any) {
        textView.scrollRangeToVisible(NSRange(..<textView.text.endIndex, in: textView.text))
    }
    
    @IBAction func refreshButtonPressend(_ sender: Any) {
        updateText()
    }
}
