//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import UIKit

extension UIViewController {
    func alert(title: String, message: String, completion: @escaping () -> Void = {}) {
        let controller = UIAlertController(title: title, message: message, preferredStyle: .alert)
        controller.addAction(.init(title: "OK", style: .default, handler: { _ in completion() }))
        present(controller, animated: true)
    }
    
    func alertTextField(title: String, placeholder: String, completion: @escaping (String) -> Void) {
        let controller = UIAlertController(title: title, message: "", preferredStyle: .alert)
        controller.addAction(UIAlertAction(title: "Confirm", style: .default, handler: { _ in
            let input = controller.textFields?.first?.text ?? ""
            completion(input.isEmpty ? placeholder : input)
        }))
        controller.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        controller.addTextField(configurationHandler: nil)
        controller.textFields?.first?.placeholder = placeholder
        present(controller, animated: true)
    }
}
