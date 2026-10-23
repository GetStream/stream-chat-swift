//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Metal
@testable import StreamChatAI
import XCTest

@MainActor
final class VoiceVisualizationRenderer_Tests: XCTestCase {
    private let size = 96
    private let blue = SIMD3<Float>(218 / 360, 1, 1)

    func test_uniforms_matchTheShaderLayout() {
        XCTAssertEqual(MemoryLayout<VoiceVisualizationUniforms>.offset(of: \.col4), 64)
        XCTAssertEqual(MemoryLayout<VoiceVisualizationUniforms>.offset(of: \.resolution), 80)
        XCTAssertEqual(MemoryLayout<VoiceVisualizationUniforms>.offset(of: \.time), 104)
        XCTAssertEqual(MemoryLayout<VoiceVisualizationUniforms>.offset(of: \.scale), 164)
        XCTAssertEqual(MemoryLayout<VoiceVisualizationUniforms>.stride, 176)
    }

    func test_shaders_compileForEveryStyle() async throws {
        let renderer = try makeRenderer()

        await renderer.load()

        for style in VoiceVisualizationStyle.allCases {
            XCTAssertTrue(renderer.canDraw(style), "\(style)")
        }
    }

    func test_glow_drawsAColoredGlobeInTheMiddle() async throws {
        let pixels = try await render(.glow)

        let center = pixel(pixels, x: size / 2, y: size / 2)
        XCTAssertGreaterThan(center.alpha, 100)
        XCTAssertGreaterThan(center.blue, center.red)
        XCTAssertEqual(pixel(pixels, x: 0, y: 0).alpha, 0)
        XCTAssertEqual(pixel(pixels, x: size - 1, y: size / 2).alpha, 0)
    }

    func test_wave_drawsALineAcrossTheMiddle() async throws {
        let pixels = try await render(.wave)

        // The line is about a pixel thick at this size, so its antialiased peak stays faint.
        let column = (0..<size).map { pixel(pixels, x: size / 2, y: $0).alpha }
        XCTAssertGreaterThan(column.max() ?? 0, 60)
        XCTAssertEqual(column.prefix(size / 4).max(), 0)
        XCTAssertEqual(column.suffix(size / 4).max(), 0)
        let edge = (0..<size).map { pixel(pixels, x: 2, y: $0).alpha }
        XCTAssertEqual(edge.max(), 0)
    }

    // MARK: - Helpers

    private struct Pixel {
        let blue: UInt8
        let green: UInt8
        let red: UInt8
        let alpha: UInt8
    }

    private func makeRenderer() throws -> VoiceVisualizationRenderer {
        let device = try XCTUnwrap(MTLCreateSystemDefaultDevice(), "Metal is unavailable")
        return VoiceVisualizationRenderer(device: device)
    }

    private func render(_ style: VoiceVisualizationStyle) async throws -> [UInt8] {
        let renderer = try makeRenderer()
        await renderer.load()
        let device = renderer.device

        let descriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: VoiceVisualizationRenderer.pixelFormat,
            width: size,
            height: size,
            mipmapped: false
        )
        descriptor.usage = [.renderTarget]
        descriptor.storageMode = .private
        let texture = try XCTUnwrap(device.makeTexture(descriptor: descriptor))
        let bytesPerRow = size * 4
        let readback = try XCTUnwrap(device.makeBuffer(length: bytesPerRow * size, options: .storageModeShared))

        let pass = MTLRenderPassDescriptor()
        pass.colorAttachments[0].texture = texture
        pass.colorAttachments[0].loadAction = .clear
        pass.colorAttachments[0].clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 0)
        pass.colorAttachments[0].storeAction = .store

        let driver = VoiceVisualizationDriver(
            input: .init(state: .idle, colors: [blue], expressivity: 1, audioLevel: nil, reduceMotion: false)
        )
        let uniforms = driver.uniforms(resolution: [Float(size), Float(size)], dark: false)
        let buffer = try XCTUnwrap(renderer.commandBuffer(drawing: style, with: uniforms, into: pass))
        let blit = try XCTUnwrap(buffer.makeBlitCommandEncoder())
        blit.copy(
            from: texture,
            sourceSlice: 0,
            sourceLevel: 0,
            sourceOrigin: MTLOrigin(x: 0, y: 0, z: 0),
            sourceSize: MTLSize(width: size, height: size, depth: 1),
            to: readback,
            destinationOffset: 0,
            destinationBytesPerRow: bytesPerRow,
            destinationBytesPerImage: bytesPerRow * size
        )
        blit.endEncoding()
        buffer.commit()
        buffer.waitUntilCompleted()
        XCTAssertNil(buffer.error)

        return Array(UnsafeBufferPointer(start: readback.contents().assumingMemoryBound(to: UInt8.self), count: bytesPerRow * size))
    }

    private func pixel(_ pixels: [UInt8], x: Int, y: Int) -> Pixel {
        let offset = (y * size + x) * 4
        return Pixel(blue: pixels[offset], green: pixels[offset + 1], red: pixels[offset + 2], alpha: pixels[offset + 3])
    }
}
