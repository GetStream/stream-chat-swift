//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import XCTest

/// The system document picker (`UIDocumentPickerViewController`) presented by the composer.
enum DocumentPickerPage {
    static var browseTab: XCUIElement { app.buttons["Browse"].firstMatch }
    static var openButton: XCUIElement { app.buttons["Open"].firstMatch }

    static var onMyDeviceLocation: XCUIElement {
        app.cells.matching(NSPredicate(format: "label BEGINSWITH 'On My'")).firstMatch
    }

    static func file(named name: String) -> XCUIElement {
        app.cells.matching(NSPredicate(format: "label BEGINSWITH %@", name)).firstMatch
    }
}

/// Files that the e2e tests make available in the simulator's "On My iPhone" Files location.
enum LocalFiles {
    static let pdfNames = ["e2e_file_1", "e2e_file_2"]

    /// Writes the test PDFs into the simulator's local file provider storage, so the document picker can list them.
    static func seed(file: StaticString = #filePath, line: UInt = #line) {
        let home = NSHomeDirectory()
        guard let dataRange = home.range(of: "/data/") else {
            XCTFail("Not running in a simulator: \(home)", file: file, line: line)
            return
        }
        let appGroups = String(home[..<dataRange.upperBound]) + "Containers/Shared/AppGroup"
        let fileManager = FileManager.default
        let groups = (try? fileManager.contentsOfDirectory(atPath: appGroups)) ?? []
        let localStorage = groups.first { group in
            let metadata = NSDictionary(contentsOfFile: "\(appGroups)/\(group)/.com.apple.mobile_container_manager.metadata.plist")
            return metadata?["MCMMetadataIdentifier"] as? String == "group.com.apple.FileProvider.LocalStorage"
        }
        guard let localStorage else {
            XCTFail("Local file provider storage is not found in \(appGroups)", file: file, line: line)
            return
        }
        let storage = "\(appGroups)/\(localStorage)/File Provider Storage"
        do {
            try fileManager.createDirectory(atPath: storage, withIntermediateDirectories: true)
        } catch {
            XCTFail("Could not create \(storage): \(error)", file: file, line: line)
            return
        }
        let pdf = Data("%PDF-1.4\n%%EOF\n".utf8)
        for name in pdfNames {
            XCTAssertTrue(
                fileManager.createFile(atPath: "\(storage)/\(name).pdf", contents: pdf),
                "Could not write \(name).pdf",
                file: file,
                line: line
            )
        }
    }
}
