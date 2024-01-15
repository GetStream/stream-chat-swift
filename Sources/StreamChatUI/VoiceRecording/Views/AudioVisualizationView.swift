//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import AVFoundation
import StreamChat
import UIKit

/// Sourced and modified from: https://github.com/bastienFalcou/SoundWave/blob/master/SoundWave/Classes/AudioVisualizationView.swift
open class AudioVisualizationView: _View, ComponentsProvider, AppearanceProvider {
    public enum AudioVisualizationMode {
        case read
        case write
    }

    public var content: [Float]? {
        didSet {
            updateContentIfNeeded()
        }
    }

    // MARK: - Configuration Properties

    /// The colour of the waveform bar that isn't part of the "played" duration.
    open var barColor: UIColor { appearance.colorPalette.textLowEmphasis }

    /// The colour of the waveform bar that is part of the "played" duration.
    open var highlightedBarColor: UIColor { appearance.colorPalette.accentPrimary }

    /// The colour of the waveform bar's background.
    open var barBackgroundColor: UIColor { appearance.colorPalette.background }

    /// The rendering mode of the waveform. On `.write` the view scrolls to accommodate new points
    /// while in `.read` it scales(up or down) all dataPoints to it's current size.
    open var audioVisualizationMode: AudioVisualizationMode = .read

    internal var meteringLevelBarWidth: CGFloat = 1.5 {
        didSet {
            setNeedsDisplay()
        }
    }

    internal var meteringLevelBarInterItem: CGFloat = 2.0 {
        didSet {
            setNeedsDisplay()
        }
    }

    internal var meteringLevelBarCornerRadius: CGFloat = 0.75 {
        didSet {
            setNeedsDisplay()
        }
    }

    /// Specify a `gradientPercentage` to have the width of gradient be that percentage of the view
    /// width (starting from left). The rest of the screen will be filled by the background colour to display nicely.
    internal var currentGradientPercentage: Float?

    private var meteringLevelsArray: [Float] = [] // Mutating recording array (values are percentage: 0.0 to 1.0)
    private var meteringLevelsClusteredArray: [Float] = [] // Generated read mode array (values are percentage: 0.0 to 1.0)
    private var currentMeteringLevelsArray: [Float] {
        if !meteringLevelsClusteredArray.isEmpty {
            return meteringLevelsClusteredArray
        }
        return meteringLevelsArray
    }

    // MARK: - Lifecycle

    override open func draw(_ rect: CGRect) {
        super.draw(rect)

        if let context = UIGraphicsGetCurrentContext() {
            drawLevelBarsMaskAndGradient(inContext: context)
        }
    }

    override open func updateContent() {
        if let meteringLevels = content {
            meteringLevelsClusteredArray = meteringLevels
            currentGradientPercentage = 0.0
        }
    }

    // MARK: - Record Mode Handling

    internal func reset() {
        content = nil
        currentGradientPercentage = nil
        meteringLevelsClusteredArray.removeAll()
        meteringLevelsArray.removeAll()
        setNeedsDisplay()
    }

    internal func add(meteringLevel: Float) {
        guard audioVisualizationMode == .write else {
            fatalError("trying to populate audio visualization view in read mode")
        }

        meteringLevelsArray.append(meteringLevel)
        setNeedsDisplay()
    }

    // MARK: - Mask + Gradient

    private func drawLevelBarsMaskAndGradient(inContext context: CGContext) {
        if currentMeteringLevelsArray.isEmpty {
            return
        }

        context.saveGState()

        UIGraphicsBeginImageContextWithOptions(frame.size, false, 0.0)

        let maskContext = UIGraphicsGetCurrentContext()

        barBackgroundColor.set()

        drawMeteringLevelBars(inContext: maskContext!)

        let mask = UIGraphicsGetCurrentContext()?.makeImage()
        UIGraphicsEndImageContext()

        context.clip(to: bounds, mask: mask!)

        drawGradient(inContext: context)

        context.restoreGState()
    }

    private func drawGradient(inContext context: CGContext) {
        if currentMeteringLevelsArray.isEmpty {
            return
        }

        context.saveGState()

        let startPoint = CGPoint(x: 0.0, y: centerY)
        var endPoint = CGPoint(x: xLeftMostBar() + meteringLevelBarWidth, y: centerY)

        if let gradientPercentage = currentGradientPercentage {
            endPoint = CGPoint(x: frame.size.width * CGFloat(gradientPercentage), y: centerY)
        }

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let colorLocations: [CGFloat] = [0.0, 1.0]
        let colors: [CGColor]

        let color = highlightedBarColor
        colors = [color.cgColor, color.cgColor]

        let gradient = CGGradient(colorsSpace: colorSpace, colors: colors as CFArray, locations: colorLocations)

        context.drawLinearGradient(gradient!, start: startPoint, end: endPoint, options: CGGradientDrawingOptions(rawValue: 0))

        context.restoreGState()

        if currentGradientPercentage != nil {
            drawPlainBackground(inContext: context, fillFromXCoordinate: endPoint.x)
        }
    }

    private func drawPlainBackground(inContext context: CGContext, fillFromXCoordinate xCoordinate: CGFloat) {
        context.saveGState()

        let squarePath = UIBezierPath()

        squarePath.move(to: CGPoint(x: xCoordinate, y: 0.0))
        squarePath.addLine(to: CGPoint(x: frame.size.width, y: 0.0))
        squarePath.addLine(to: CGPoint(x: frame.size.width, y: frame.size.height))
        squarePath.addLine(to: CGPoint(x: xCoordinate, y: frame.size.height))

        squarePath.close()
        squarePath.addClip()

        barColor.set()
        squarePath.fill()

        context.restoreGState()
    }

    // MARK: - Bars

    private func drawMeteringLevelBars(inContext context: CGContext) {
        if audioVisualizationMode == .write {
            let offset = max(currentMeteringLevelsArray.count - maximumNumberBars, 0)
            for index in offset..<currentMeteringLevelsArray.count {
                drawBar(
                    index - offset,
                    meteringLevelIndex: index,
                    context: context,
                    array: currentMeteringLevelsArray
                )
            }
        } else {
            let array = currentMeteringLevelsArray.count > maximumNumberBars
                ? currentMeteringLevelsArray.downsample(to: maximumNumberBars)
                : currentMeteringLevelsArray.upsample(to: maximumNumberBars)

            for index in 0..<array.count {
                drawBar(
                    index,
                    meteringLevelIndex: index,
                    context: context,
                    array: array
                )
            }
        }
    }

    private func drawBar(_ barIndex: Int, meteringLevelIndex: Int, context: CGContext, array: [Float]) {
        context.saveGState()

        let xPointForMeteringLevel = self.xPointForMeteringLevel(barIndex)
        let heightForMeteringLevel = self.heightForMeteringLevel(array[meteringLevelIndex])

        let barRect = CGRect(
            x: xPointForMeteringLevel,
            y: centerY - heightForMeteringLevel,
            width: meteringLevelBarWidth,
            height: heightForMeteringLevel * 2
        )
        let barPath: UIBezierPath = UIBezierPath(roundedRect: barRect, cornerRadius: meteringLevelBarCornerRadius)

        barBackgroundColor.set()
        barPath.fill()

        context.restoreGState()
    }

    // MARK: - Points Helpers

    private var centerY: CGFloat {
        frame.size.height / 2.0
    }

    private var maximumBarHeight: CGFloat {
        bounds.size.height
    }

    private var minimumBarHeight: CGFloat {
        1
    }

    private var maximumNumberBars: Int {
        Int(bounds.size.width / (meteringLevelBarWidth + meteringLevelBarInterItem))
    }

    private func xLeftMostBar() -> CGFloat {
        xPointForMeteringLevel(min(maximumNumberBars - 1, currentMeteringLevelsArray.count - 1))
    }

    private func heightForMeteringLevel(_ meteringLevel: Float) -> CGFloat {
        max(minimumBarHeight, (CGFloat(meteringLevel) * maximumBarHeight) / 2)
    }

    private func xPointForMeteringLevel(_ atIndex: Int) -> CGFloat {
        CGFloat(atIndex) * (meteringLevelBarWidth + meteringLevelBarInterItem)
    }
}
