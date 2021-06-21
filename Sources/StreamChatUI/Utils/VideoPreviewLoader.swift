//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import AVKit
import StreamChat
import UIKit

/// A protocol the video preview uploader implementation must conform to.
public protocol VideoPreviewLoader: AnyObject {
    /// Loads a preview for the video at given URL.
    /// - Parameters:
    ///   - url: A video URL.
    ///   - completion: A completion that is called when a preview is loaded. Must be invoked on main queue.
    func loadPreviewForVideo(at url: URL, completion: @escaping (Result<UIImage, Error>) -> Void)
}

/// The `VideoPreviewLoader` implemenation used by default.
final class DefaultVideoPreviewLoader: VideoPreviewLoader {
    private let cache: Cache<URL, UIImage>
    
    init(countLimit: Int = 50) {
        cache = .init(countLimit: countLimit)
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleMemoryWarning(_:)),
            name: UIApplication.didReceiveMemoryWarningNotification,
            object: nil
        )
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func loadPreviewForVideo(at url: URL, completion: @escaping (Result<UIImage, Error>) -> Void) {
        if let cached = cache[url] {
            return call(completion, with: .success(cached))
        }
        
        let asset = AVURLAsset(url: url)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        let frameTime = CMTime(seconds: 0.1, preferredTimescale: 600)
        
        imageGenerator.appliesPreferredTrackTransform = true
        imageGenerator.generateCGImagesAsynchronously(forTimes: [.init(time: frameTime)]) { [weak self] _, image, _, _, error in
            guard let self = self else { return }
            
            let result: Result<UIImage, Error>
            if let thumbnail = image {
                result = .success(.init(cgImage: thumbnail))
            } else if let error = error {
                result = .failure(error)
            } else {
                log.error("Both error and image are `nil`.")
                return
            }
            
            self.cache[url] = try? result.get()
            self.call(completion, with: result)
        }
    }
    
    private func call(_ completion: @escaping (Result<UIImage, Error>) -> Void, with result: Result<UIImage, Error>) {
        if Thread.current.isMainThread {
            completion(result)
        } else {
            DispatchQueue.main.async {
                completion(result)
            }
        }
    }
    
    @objc private func handleMemoryWarning(_ notification: NSNotification) {
        cache.removeAllObjects()
    }
}
