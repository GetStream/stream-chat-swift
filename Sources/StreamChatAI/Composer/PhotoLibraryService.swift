//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Photos
import StreamCore
import UIKit

@MainActor
final class PhotoLibraryService: ObservableObject {
    @Published private(set) var recentAssets: [PHAsset] = []

    private let imageManager = PHCachingImageManager()
    private nonisolated static let missingResourceErrorCode = PHPhotosError.missingResource.rawValue

    func prepare(limit: Int = 10) async {
        guard await requestAuthorizationIfNeeded() else {
            recentAssets = []
            return
        }

        let fetchOptions = PHFetchOptions()
        fetchOptions.fetchLimit = limit
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        let fetchResult = PHAsset.fetchAssets(with: .image, options: fetchOptions)

        var assets: [PHAsset] = []
        assets.reserveCapacity(fetchResult.count)
        fetchResult.enumerateObjects { asset, _, _ in
            assets.append(asset)
        }

        recentAssets = assets
    }

    func asset(for identifier: String) -> PHAsset? {
        let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: [identifier], options: nil)
        return fetchResult.firstObject
    }

    func data(for asset: PHAsset) async -> Data? {
        await withCheckedContinuation { continuation in
            let options = PHImageRequestOptions()
            options.isSynchronous = false
            options.deliveryMode = .opportunistic
            options.isNetworkAccessAllowed = true

            imageManager.requestImageDataAndOrientation(
                for: asset,
                options: options,
                resultHandler: Self.dataHandler(for: asset, request: PhotoRequest(continuation))
            )
        }
    }

    func fileURL(for asset: PHAsset) async -> URL? {
        await withCheckedContinuation { continuation in
            let options = PHContentEditingInputRequestOptions()
            options.isNetworkAccessAllowed = true
            options.canHandleAdjustmentData = { _ in true }

            asset.requestContentEditingInput(with: options) { input, _ in
                continuation.resume(returning: input?.fullSizeImageURL)
            }
        }
    }

    func thumbnail(for asset: PHAsset, targetSize: CGSize) async -> UIImage? {
        await withCheckedContinuation { continuation in
            let options = PHImageRequestOptions()
            options.isSynchronous = false
            options.deliveryMode = .opportunistic
            options.resizeMode = .fast
            options.isNetworkAccessAllowed = true

            imageManager.requestImage(
                for: asset,
                targetSize: targetSize,
                contentMode: .aspectFill,
                options: options,
                resultHandler: Self.thumbnailHandler(for: asset, request: PhotoRequest(continuation))
            )
        }
    }

    // Photos calls these handlers on a background queue while it downloads from iCloud, so
    // they are made outside the main actor.

    private nonisolated static func dataHandler(
        for asset: PHAsset,
        request: PhotoRequest<Data?>
    ) -> (Data?, String?, CGImagePropertyOrientation, [AnyHashable: Any]?) -> Void {
        { data, _, _, info in
            switch outcome(of: info, hasResult: data != nil, request: "data fetch") {
            case .result:
                request.resume(data)
            case .failed:
                request.resume(nil)
            case .fullSize:
                guard request.startFallback() else { return }
                fetchFullSizeData(for: asset, request: "full-size data") { request.resume($0) }
            case .wait:
                return
            }
        }
    }

    private nonisolated static func thumbnailHandler(
        for asset: PHAsset,
        request: PhotoRequest<UIImage?>
    ) -> (UIImage?, [AnyHashable: Any]?) -> Void {
        { image, info in
            switch outcome(of: info, hasResult: image != nil, request: "thumbnail") {
            case .result:
                request.resume(image)
            case .failed:
                request.resume(nil)
            case .fullSize:
                guard request.startFallback() else { return }
                fetchFullSizeData(for: asset, request: "full-size thumbnail") { data in
                    request.resume(data.flatMap(UIImage.init(data:)))
                }
            case .wait:
                return
            }
        }
    }

    /// What to do with what the image manager delivered.
    private enum RequestOutcome {
        /// Use the delivered result.
        case result
        /// Give up.
        case failed
        /// Read the full-size photo instead.
        case fullSize
        /// Wait for a better result than this degraded one.
        case wait
    }

    private nonisolated static func outcome(of info: [AnyHashable: Any]?, hasResult: Bool, request: String) -> RequestOutcome {
        if let error = info?[PHImageErrorKey] as? NSError,
           error.domain == PHPhotosErrorDomain,
           error.code == missingResourceErrorCode {
            return .fullSize
        }

        if (info?[PHImageCancelledKey] as? Bool) == true {
            return .failed
        }

        if let error = info?[PHImageErrorKey] as? Error {
            print("PhotoLibraryService \(request) error: \(error.localizedDescription)")
            return .failed
        }

        if hasResult {
            return .result
        }

        if (info?[PHImageResultIsDegradedKey] as? Bool) == true {
            return .wait
        }

        return .fullSize
    }

    private nonisolated static func fetchFullSizeData(for asset: PHAsset, request: String, resume: @escaping (Data?) -> Void) {
        let resources = PHAssetResource.assetResources(for: asset)
        guard let resource = resources.first(where: { $0.type == .photo || $0.type == .fullSizePhoto }) ?? resources.first else {
            resume(nil)
            return
        }

        let options = PHAssetResourceRequestOptions()
        options.isNetworkAccessAllowed = true

        var collected = Data()
        PHAssetResourceManager.default().requestData(for: resource, options: options) { chunk in
            collected.append(chunk)
        } completionHandler: { error in
            if let error {
                print("PhotoLibraryService \(request) error: \(error.localizedDescription)")
                resume(nil)
                return
            }
            resume(collected.isEmpty ? nil : collected)
        }
    }

    private func requestAuthorizationIfNeeded() async -> Bool {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)

        switch status {
        case .authorized, .limited:
            return true
        case .notDetermined:
            let newStatus = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
            return newStatus == .authorized || newStatus == .limited
        default:
            return false
        }
    }
}

// Photos can call a request's handler several times, from any queue: the request resumes its
// continuation once, and starts the full-size fallback once.
final class PhotoRequest<Value>: Sendable {
    private struct State {
        var continuation: CheckedContinuation<Value, Never>?
        var fallbackStarted = false
    }

    private let state: AllocatedUnfairLock<State>

    init(_ continuation: CheckedContinuation<Value, Never>) {
        state = AllocatedUnfairLock(State(continuation: continuation))
    }

    func resume(_ value: sending Value) {
        let continuation = state.withLock { state in
            defer { state.continuation = nil }
            return state.continuation
        }
        continuation?.resume(returning: value)
    }

    func startFallback() -> Bool {
        state.withLock { state in
            guard !state.fallbackStarted else { return false }
            state.fallbackStarted = true
            return true
        }
    }
}
