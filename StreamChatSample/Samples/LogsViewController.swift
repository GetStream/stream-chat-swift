//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

class LogsViewController: UIViewController {
    @IBOutlet var textView: UITextView!

    override func viewDidLoad() {
        super.viewDidLoad()
        updateText()
    }
    
    func updateText() {
        textView.text = LogStore.shared.logs
    }
    
    @IBAction
    func clearButtonPressed(_ sender: UIBarButtonItem) {
        LogStore.shared.logs = ""
        updateText()
    }
    
    @IBAction
    func downButtonPressed(_ sender: Any) {
        textView.scrollRangeToVisible(NSRange(..<textView.text.endIndex, in: textView.text))
    }
    
    @IBAction
    func refreshButtonPressend(_ sender: Any) {
        updateText()
    }
}
