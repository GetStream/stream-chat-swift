//
//  String+FileType.swift
//  StreamChat
//
//  Created by Alexey Bukhtin on 04/06/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import Foundation
import MobileCoreServices

extension String {
    static let anyFileType: String = kUTTypeItem as String
    static let textFileType: String = kUTTypeText as String
    static let pdfFileType: String = kUTTypePDF as String
    static let imageFileType: String = kUTTypeImage as String
    static let movieFileType: String = kUTTypeMovie as String
}
