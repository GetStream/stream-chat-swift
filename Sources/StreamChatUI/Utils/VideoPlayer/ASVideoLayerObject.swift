//
//  ASVideoLayerObject.swift
//  Timeless-wallet
//
//  Created by Parth Kshatriya on 19/11/21.
//
//

import UIKit
import AVFoundation

open class ASVideoLayerObject: NSObject {
    var layer = AVPlayerLayer()
    var used = false
    override init() {
        layer.backgroundColor = UIColor.clear.cgColor
        layer.videoGravity = AVLayerVideoGravity.resize
    }
}

public struct VideoLayers {
    var layers = [ASVideoLayerObject]()
    init() {
        for _ in 0..<1 {
            layers.append(ASVideoLayerObject())
        }
    }

    func getLayerForParentLayer(parentLayer: CALayer) -> AVPlayerLayer {
        for videoObject in layers where videoObject.layer.superlayer == parentLayer {
            return videoObject.layer
        }
        return getFreeVideoLayer()
    }

    func getFreeVideoLayer() -> AVPlayerLayer {
        for videoObject in layers where videoObject.used == false {
            videoObject.used = true
            return videoObject.layer
        }
        return layers[0].layer
    }

    func freeLayer(layerToFree: AVPlayerLayer) {
        for videoObject in layers where videoObject.layer == layerToFree {
            videoObject.used = false
            videoObject.layer.player = nil
            if videoObject.layer.superlayer != nil {
                videoObject.layer.removeFromSuperlayer()
            }
            break
        }
    }
}
