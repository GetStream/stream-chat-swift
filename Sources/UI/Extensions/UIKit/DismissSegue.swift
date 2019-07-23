//
//  DismissSegue.swift
//  StreamChat
//
//  Created by Alexey Bukhtin on 02/05/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import UIKit

final class DismissSegue: UIStoryboardSegue {
    override func perform() {
        source.presentingViewController?.dismiss(animated: true)
    }
}
