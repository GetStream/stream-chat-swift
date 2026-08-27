//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import CryptoKit
import Foundation
import StreamChat
import StreamCore

public final class StreamVideoCache: @unchecked Sendable {
    public let maxSizeInBytes: Int
    let directory: URL

    private let queue = DispatchQueue(label: "io.getstream.StreamChatSwiftUI.StreamVideoCache", qos: .utility)

    init(directory: URL, maxSizeInBytes: Int) {
        self.directory = directory
        self.maxSizeInBytes = maxSizeInBytes
    }

    public convenience init(name: String, maxSizeInBytes: Int) {
        let base = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory())
        self.init(
            directory: base.appendingPathComponent(name, isDirectory: true),
            maxSizeInBytes: maxSizeInBytes
        )
    }

    func temporaryFileURL() throws -> URL {
        let directory = directory.appendingPathComponent("tmp", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory.appendingPathComponent(UUID().uuidString)
    }

    func completedFileURL(forKey key: String, fileExtension: String?) async -> URL? {
        await withCheckedContinuation { continuation in
            completedFileURL(forKey: key, fileExtension: fileExtension) {
                continuation.resume(returning: $0)
            }
        }
    }

    func completedFileURL(forKey key: String, fileExtension: String?, completion: @escaping @Sendable (URL?) -> Void) {
        queue.async {
            let url = self.fileURL(forKey: key, fileExtension: fileExtension)
            guard FileManager.default.fileExists(atPath: url.path) else {
                completion(nil)
                return
            }
            try? FileManager.default.setAttributes([.modificationDate: Date()], ofItemAtPath: url.path)
            completion(url)
        }
    }

    @discardableResult
    func storeCompletedFile(at tempURL: URL, forKey key: String, fileExtension: String?) async -> URL? {
        await withCheckedContinuation { continuation in
            storeCompletedFile(at: tempURL, forKey: key, fileExtension: fileExtension) {
                continuation.resume(returning: $0)
            }
        }
    }

    func storeCompletedFile(
        at tempURL: URL,
        forKey key: String,
        fileExtension: String?,
        completion: @escaping @Sendable (URL?) -> Void
    ) {
        queue.async {
            let size = (try? tempURL.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
            guard size > 0 else {
                try? FileManager.default.removeItem(at: tempURL)
                completion(nil)
                return
            }

            let destination = self.fileURL(forKey: key, fileExtension: fileExtension)
            do {
                try FileManager.default.createDirectory(at: self.directory, withIntermediateDirectories: true)
                if FileManager.default.fileExists(atPath: destination.path) {
                    try FileManager.default.removeItem(at: destination)
                    try FileManager.default.copyItem(at: tempURL, to: destination)
                } else {
                    try FileManager.default.copyItem(at: tempURL, to: destination)
                }
                try FileManager.default.setAttributes([.modificationDate: Date()], ofItemAtPath: destination.path)
            } catch {
                log.error("Failed to store completed video cache file: \(error)")
                completion(nil)
                return
            }

            self.evictIfNeeded(protecting: destination)
            completion(destination)
        }
    }

    func remove(forKey key: String, fileExtension: String?) async {
        await withCheckedContinuation { continuation in
            queue.async {
                try? FileManager.default.removeItem(at: self.fileURL(forKey: key, fileExtension: fileExtension))
                continuation.resume()
            }
        }
    }

    func removeAll() async {
        await withCheckedContinuation { continuation in
            queue.async {
                try? FileManager.default.removeItem(at: self.directory)
                continuation.resume()
            }
        }
    }

    private func evictIfNeeded(protecting protectedURL: URL) {
        var files = completedFiles()
        var totalSize = files.reduce(0) { $0 + $1.size }
        guard totalSize > maxSizeInBytes else { return }

        files.sort { $0.lastUsedAt < $1.lastUsedAt }
        var remainingCount = files.count
        for file in files where totalSize > maxSizeInBytes && remainingCount > 1 {
            guard file.url != protectedURL else { continue }
            try? FileManager.default.removeItem(at: file.url)
            totalSize -= file.size
            remainingCount -= 1
        }
    }

    private func completedFiles() -> [(url: URL, size: Int, lastUsedAt: Date)] {
        guard let urls = try? FileManager.default.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: [.fileSizeKey, .contentModificationDateKey, .isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) else {
            return []
        }

        return urls.compactMap { url in
            let values = try? url.resourceValues(forKeys: [.fileSizeKey, .contentModificationDateKey, .isRegularFileKey])
            guard values?.isRegularFile == true, let size = values?.fileSize else { return nil }
            return (url, size, values?.contentModificationDate ?? Date())
        }
    }

    private func fileURL(forKey key: String, fileExtension: String?) -> URL {
        directory.appendingPathComponent(Self.storageName(forKey: key, fileExtension: fileExtension))
    }

    private static func storageName(forKey key: String, fileExtension: String?) -> String {
        let hex = SHA256.hash(data: Data(key.utf8)).map { String(format: "%02x", $0) }.joined()
        if let fileExtension, !fileExtension.isEmpty {
            return "\(hex).\(fileExtension)"
        }
        return hex
    }
}
