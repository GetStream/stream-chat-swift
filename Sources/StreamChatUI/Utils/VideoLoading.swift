//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import AVKit
import StreamChat
import UIKit

/// A protocol the video loader must conform to.
public protocol VideoLoading: AnyObject {
    /// Loads a preview for the video at given URL.
    /// - Parameters:
    ///   - url: A video URL.
    ///   - completion: A completion that is called when a preview is loaded. Must be invoked on main queue.
    func loadPreviewForVideo(at url: URL, completion: @escaping (Result<UIImage, Error>) -> Void)
    
    /// Returns a video asset with the given URL.
    ///
    /// - Returns: The video asset.
    func videoAsset(at url: URL) -> AVURLAsset
}

public extension VideoLoading {
    func videoAsset(at url: URL) -> AVURLAsset {
        .init(url: url)
    }
}

/// The default `VideoLoading` implementation.
open class StreamVideoLoader: VideoLoading {
    private let cache: Cache<URL, UIImage>
    
    public init(cachedVideoPreviewsCountLimit: Int = 50) {
        cache = .init(countLimit: cachedVideoPreviewsCountLimit)
        
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
    
    open func loadPreviewForVideo(at url: URL, completion: @escaping (Result<UIImage, Error>) -> Void) {
        if let cached = cache[url] {
            return call(completion, with: .success(cached))
        }
        
        let asset = videoAsset(at: url)
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
    
    open func videoAsset(at url: URL) -> AVURLAsset {
        .init(url: url)
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
    
    @objc open func handleMemoryWarning(_ notification: NSNotification) {
        cache.removeAllObjects()
    }
}
