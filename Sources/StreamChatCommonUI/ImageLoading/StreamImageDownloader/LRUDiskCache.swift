//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import CryptoKit
import Foundation
import StreamChat

/// A thread-safe, size-bounded disk cache with least-recently-used (LRU) eviction.
/// All instances serialize file operations on a shared queue. Completion handlers are always called asynchronously on the shared background queue.
final class LRUDiskCache: @unchecked Sendable {
    let maxSizeInBytes: Int
    let directory: URL
    private var trackedSize: Int?

    private static let queue = DispatchQueue(label: "io.getstream.StreamChatCommonUI.LRUDiskCache", qos: .utility)

    init(directory: URL, maxSizeInBytes: Int) {
        self.directory = directory
        self.maxSizeInBytes = max(0, maxSizeInBytes)
    }

    convenience init(name: String, maxSizeInBytes: Int) {
        let base = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory())
        self.init(
            directory: base.appendingPathComponent(name, isDirectory: true),
            maxSizeInBytes: maxSizeInBytes
        )
    }

    func data(forKey key: String, completion: @escaping @Sendable (Data?) -> Void) {
        Self.queue.async {
            guard self.maxSizeInBytes > 0 else {
                completion(nil)
                return
            }
            let name = Self.storageName(forKey: key)
            let url = self.directory.appendingPathComponent(name)

            guard let data = try? Data(contentsOf: url) else {
                try? FileManager.default.removeItem(at: url)
                completion(nil)
                return
            }
            guard data.count <= self.maxSizeInBytes else {
                try? FileManager.default.removeItem(at: url)
                completion(nil)
                return
            }

            let now = Date()
            try? FileManager.default.setAttributes([.modificationDate: now], ofItemAtPath: url.path)
            if self.trackedSize == nil || self.trackedSize ?? 0 > self.maxSizeInBytes {
                self.evictFilesIfNeeded(protecting: url)
            }
            completion(data)
        }
    }

    func store(_ data: Data, forKey key: String, completion: (@Sendable (Error?) -> Void)? = nil) {
        Self.queue.async {
            guard !data.isEmpty else {
                completion?(ClientError.DiskCacheEmptyData())
                return
            }
            guard data.count <= self.maxSizeInBytes else {
                completion?(ClientError.DiskCacheEntryExceedsSizeLimit())
                return
            }
            let name = Self.storageName(forKey: key)
            let destination = self.directory.appendingPathComponent(name)

            do {
                try FileManager.default.createDirectory(at: self.directory, withIntermediateDirectories: true)
                try data.write(to: destination, options: .atomic)
                try? FileManager.default.setAttributes([.modificationDate: Date()], ofItemAtPath: destination.path)
                if let trackedSize = self.trackedSize, trackedSize + data.count <= self.maxSizeInBytes {
                    self.trackedSize = trackedSize + data.count
                } else {
                    self.evictFilesIfNeeded(protecting: destination)
                }
                completion?(nil)
            } catch {
                log.error("Failed to store data in disk cache: \(error)")
                completion?(error)
            }
        }
    }

    func remove(forKey key: String, completion: (@Sendable () -> Void)? = nil) {
        Self.queue.async {
            let name = Self.storageName(forKey: key)
            try? FileManager.default.removeItem(at: self.directory.appendingPathComponent(name))
            self.trackedSize = nil
            completion?()
        }
    }

    func removeAll(completion: (@Sendable () -> Void)? = nil) {
        Self.queue.async {
            try? FileManager.default.removeItem(at: self.directory)
            self.trackedSize = nil
            completion?()
        }
    }

    private func evictFilesIfNeeded(protecting protectedURL: URL) {
        let files = (try? FileManager.default.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: [.fileSizeKey, .contentModificationDateKey],
            options: [.skipsHiddenFiles]
        )) ?? []
        let entries = files.compactMap { url -> (url: URL, size: Int, lastUsedAt: Date)? in
            let values = try? url.resourceValues(forKeys: [.fileSizeKey, .contentModificationDateKey])
            guard let size = values?.fileSize else { return nil }
            return (url, size, values?.contentModificationDate ?? .distantPast)
        }.sorted {
            if $0.url == protectedURL { return false }
            if $1.url == protectedURL { return true }
            if $0.lastUsedAt == $1.lastUsedAt {
                return $0.url.lastPathComponent < $1.url.lastPathComponent
            }
            return $0.lastUsedAt < $1.lastUsedAt
        }
        var totalSize = entries.reduce(0) { $0 + $1.size }
        for entry in entries where totalSize > maxSizeInBytes {
            try? FileManager.default.removeItem(at: entry.url)
            totalSize -= entry.size
        }
        trackedSize = totalSize
    }

    /// File-system safe name for key.
    private static func storageName(forKey key: String) -> String {
        SHA256.hash(data: Data(key.utf8)).map { String(format: "%02x", $0) }.joined()
    }
}

extension ClientError {
    final class DiskCacheEmptyData: ClientError, @unchecked Sendable {}
    final class DiskCacheEntryExceedsSizeLimit: ClientError, @unchecked Sendable {}
}
