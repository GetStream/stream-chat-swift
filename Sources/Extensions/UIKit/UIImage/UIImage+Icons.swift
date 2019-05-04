//
//  UIImage+Icons.swift
//  GetStreamChat
//
//  Created by Alexey Bukhtin on 01/04/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import UIKit

extension UIImage {
    public struct FileTypes {
        public static let csv: UIImage = UIImage.chat(named: "CSV")
        public static let doc: UIImage = UIImage.chat(named: "DOC")
        public static let pdf: UIImage = UIImage.chat(named: "PDF")
        public static let ppt: UIImage = UIImage.chat(named: "PPT")
        public static let tar: UIImage = UIImage.chat(named: "TAR")
        public static let xls: UIImage = UIImage.chat(named: "XLS")
        public static let zip: UIImage = UIImage.chat(named: "ZIP")
    }
    
    public struct Icons {
        public static let close: UIImage = UIImage.chat(named: "closeIcon")
        public static let delivered: UIImage = UIImage.chat(named: "deliveredIcon")
        public static let edit: UIImage = UIImage.chat(named: "editIcon")
        public static let happy: UIImage = UIImage.chat(named: "happyIcon")
        public static let image: UIImage = UIImage.chat(named: "imageIcon")
        public static let more: UIImage = UIImage.chat(named: "moreIcon")
        public static let path: UIImage = UIImage.chat(named: "pathIcon")
        public static let plus: UIImage = UIImage.chat(named: "plusIcon")
        public static let send: UIImage = UIImage.chat(named: "sendIcon")
        public static let startThread: UIImage = UIImage.chat(named: "startThreadIcon")
    }
    
    static func chat(named name: String) -> UIImage {
        let bundle = Bundle(for: Client.self)
        return UIImage(named: name, in: bundle, compatibleWith: nil)
            ?? UIImage(named: "ZIP", in: bundle, compatibleWith: nil)
            ?? .init(color: UIColor.chatGray.withAlphaComponent(0.5))
    }
}
