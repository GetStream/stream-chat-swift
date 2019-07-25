//
//  UIImage+Icons.swift
//  StreamChat
//
//  Created by Alexey Bukhtin on 01/04/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import UIKit
import StreamChatCore

extension UIImage {
    /// A file types images.
    public struct FileTypes {
        /// A CSV file image.
        public static let csv: UIImage = UIImage.chat(named: "csv")
        /// A DOC file image.
        public static let doc: UIImage = UIImage.chat(named: "doc")
        /// A PDF file image.
        public static let pdf: UIImage = UIImage.chat(named: "pdf")
        /// A PPT file image.
        public static let ppt: UIImage = UIImage.chat(named: "ppt")
        /// A TAR file image.
        public static let tar: UIImage = UIImage.chat(named: "tar")
        /// A XLS file image.
        public static let xls: UIImage = UIImage.chat(named: "xls")
        /// A ZIP file image.
        public static let zip: UIImage = UIImage.chat(named: "zip")
        /// A MP3 file image.
        public static let mp3: UIImage = UIImage.chat(named: "mp3")
        /// A MOV file image.
        public static let mp4: UIImage = UIImage.chat(named: "mov")
    }
    
    /// An icons images.
    public struct Icons {
        /// A close icon.
        public static let close: UIImage = UIImage.chat(named: "closeIcon")
        /// A delivered icon.
        public static let delivered: UIImage = UIImage.chat(named: "deliveredIcon")
        /// An edit icon.
        public static let edit: UIImage = UIImage.chat(named: "editIcon")
        /// An image icon.
        public static let image: UIImage = UIImage.chat(named: "imageIcon")
        /// An images icon.
        public static let images: UIImage = UIImage.chat(named: "imagesIcon")
        /// A file icon.
        public static let file: UIImage = UIImage.chat(named: "fileIcon")
        /// A camera icon.
        public static let camera: UIImage = UIImage.chat(named: "cameraIcon")
        /// A more icon.
        public static let more: UIImage = UIImage.chat(named: "moreIcon")
        /// A path icon.
        public static let path: UIImage = UIImage.chat(named: "pathIcon")
        /// A plus icon.
        public static let plus: UIImage = UIImage.chat(named: "plusIcon")
        /// A send icon.
        public static let send: UIImage = UIImage.chat(named: "sendIcon")
        /// A start thread icon.
        public static let startThread: UIImage = UIImage.chat(named: "startThreadIcon")
    }
    
    /// A logo images.
    public struct Logo {
        /// A giphy logo image.
        public static let giphy: UIImage = UIImage.chat(named: "giphy")
    }
    
    static func chat(named name: String) -> UIImage {
        let name = name == "mp4" ? "mov" : name
        
        let bundle = Bundle(for: ComposerView.self)
        return UIImage(named: name, in: bundle, compatibleWith: nil)
            ?? UIImage(named: "zip", in: bundle, compatibleWith: nil)
            ?? .init(color: UIColor.chatGray.withAlphaComponent(0.5))
    }
}
