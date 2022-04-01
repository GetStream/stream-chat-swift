//
//  HapticFeedbackGenerator.swift
//  StreamChatUI
//
//  Created by Parth Kshatriya on 01/04/22.
//

import Foundation
import UIKit

class HapticFeedbackGenerator {
    static let feedbackGenerator = UISelectionFeedbackGenerator()
    static var ImpactGenerator: UIImpactFeedbackGenerator?

    static func selectionHaptic() {
        feedbackGenerator.selectionChanged()
    }

    static func softHaptic() {
        if #available(iOS 13.0, *) {
            ImpactGenerator = UIImpactFeedbackGenerator(style: .light)
            ImpactGenerator?.impactOccurred()
        } else {
            // Fallback on earlier versions
        }
    }
}
