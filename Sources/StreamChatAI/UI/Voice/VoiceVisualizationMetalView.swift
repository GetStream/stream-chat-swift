//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import MetalKit
import UIKit

// Touches outside the shape pass through to whatever is behind the view.
final class VoiceVisualizationMetalView: MTKView {
    let style: VoiceVisualizationStyle

    var input: VoiceVisualizationDriver.Input {
        get { driver.input }
        set { driver.input = newValue }
    }

    var isDark = false

    private var driver: VoiceVisualizationDriver
    private let renderer: VoiceVisualizationRenderer?
    private var lastFrame: CFTimeInterval?
    private var isInBackground = false
    private var hasDrawn = false

    init(style: VoiceVisualizationStyle, input: VoiceVisualizationDriver.Input) {
        self.style = style
        driver = VoiceVisualizationDriver(input: input, levelResponse: style.levelResponse)
        renderer = VoiceVisualizationRenderer.shared
        super.init(frame: .zero, device: renderer?.device)
        colorPixelFormat = VoiceVisualizationRenderer.pixelFormat
        clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 0)
        framebufferOnly = true
        isOpaque = false
        backgroundColor = .clear
        enableSetNeedsDisplay = false
        preferredFramesPerSecond = 60
        isPaused = true
        // Hidden until the first frame, which fades in rather than popping in once the shaders
        // have compiled.
        alpha = 0
        renderer?.prepare()

        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapped)))
        addGestureRecognizer(UIHoverGestureRecognizer(target: self, action: #selector(hovered)))
        let notifications = NotificationCenter.default
        notifications.addObserver(
            self,
            selector: #selector(enteredBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        notifications.addObserver(
            self,
            selector: #selector(enteringForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
    }

    @available(*, unavailable)
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        let displayScale = traitCollection.displayScale
        if window != nil && displayScale > 0 {
            contentScaleFactor = min(displayScale, style.maximumScale)
        }
        updatePaused()
    }

    override func draw(_ rect: CGRect) {
        let now = CACurrentMediaTime()
        driver.advance(by: lastFrame.map { now - $0 } ?? 0)
        lastFrame = now

        guard
            let renderer,
            renderer.canDraw(style),
            let pass = currentRenderPassDescriptor,
            let drawable = currentDrawable
        else { return }
        let resolution = SIMD2(Float(drawableSize.width), Float(drawableSize.height))
        let uniforms = driver.uniforms(resolution: resolution, dark: isDark)
        guard let buffer = renderer.commandBuffer(drawing: style, with: uniforms, into: pass) else { return }
        buffer.present(drawable)
        buffer.commit()

        if !hasDrawn {
            hasDrawn = true
            UIView.animate(withDuration: 0.3, delay: 0, options: [.allowUserInteraction]) {
                self.alpha = 1
            }
        }
    }

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        style.contains(normalized(point))
    }

    // `point` centred and normalized to the shorter side, with y up, as the shaders read it.
    func normalized(_ point: CGPoint) -> SIMD2<Float> {
        let side = max(min(bounds.width, bounds.height), 1)
        return SIMD2(Float((point.x - bounds.midX) / side), Float((bounds.midY - point.y) / side))
    }

    private func updatePaused() {
        let paused = window == nil || isInBackground
        if !paused && isPaused {
            // Resuming starts the clock afresh rather than leaping over the pause.
            lastFrame = nil
        }
        isPaused = paused
    }

    @objc private func tapped(_ recognizer: UITapGestureRecognizer) {
        driver.tap(at: normalized(recognizer.location(in: self)))
    }

    @objc private func hovered(_ recognizer: UIHoverGestureRecognizer) {
        switch recognizer.state {
        case .began, .changed:
            let point = normalized(recognizer.location(in: self))
            driver.hover(at: style.contains(point) ? point : nil)
        default:
            driver.hover(at: nil)
        }
    }

    @objc private func enteredBackground() {
        isInBackground = true
        updatePaused()
    }

    @objc private func enteringForeground() {
        isInBackground = false
        updatePaused()
    }
}
