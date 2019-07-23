//
//  URL+Media.swift
//  StreamChat
//
//  Created by Alexey Bukhtin on 23/07/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import UIKit
import AVFoundation

extension URL {
    /// A frame position.
    public enum FramePosition {
        case index(at: Float64)
        case first
        case middle
        case last
    }
    
    /// Get an image frame from a video file.
    ///
    /// - Parameter position: a frame position.
    /// - Returns: an image frame.
    public func videoFrame(at position: FramePosition) -> UIImage? {
        let asset = AVAsset(url: self)
        let duration = CMTimeGetSeconds(asset.duration)
        
        guard duration > 0 else {
            return nil
        }
        
        let fromTime: Float64
        
        switch position {
        case .index(let time):
            fromTime = max(0, min(time, duration))
        case .first:
            fromTime = 0
        case .middle:
            fromTime = duration / 2
        case .last:
            fromTime = duration - 0.1
        }
        
        let time = CMTimeMakeWithSeconds(fromTime, preferredTimescale: 600)
        
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        
        if let cgImage = try? generator.copyCGImage(at: time, actualTime: nil) {
            return UIImage(cgImage: cgImage)
        }
        
        return nil
    }
}
