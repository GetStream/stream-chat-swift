//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
import UIKit

class DebugObjectViewController: UIViewController {
    let object: Any?

    init(object: Any?) {
        self.object = object
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    lazy var textView: UITextView = {
        let view = UITextView()
        view.isSelectable = true
        view.isEditable = false
        return view
    }()

    override func loadView() {
        view = textView
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        var debug: String = ""
        dump(object, to: &debug)
        textView.text = debug

        print(Mirror(reflecting: object!).children.map {
            ($0.label, $0.value)
        })
    }
}
