//
//  UIViewController+MoveToStoryboard.swift
//  StreamChatClient
//
//  Created by Matheus Cardoso on 19/08/20.
//  Copyright © 2020 Stream.io Inc. All rights reserved.
//

import UIKit

extension UIViewController {
    func moveToStoryboard(_ storyboard: UIStoryboard, options: UIView.AnimationOptions = []) {
        let initial = storyboard.instantiateInitialViewController()
        UIView.transition(with: self.view.window!, duration: 0.5, options: options, animations: {
            self.view.window?.rootViewController = initial
        })
    }
}
