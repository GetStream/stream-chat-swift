//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import AVFoundation
import StreamChat
@testable import StreamChatUI
import XCTest

@MainActor final class StreamVideoCompressor_Tests: XCTestCase {
    private var temporaryDirectories: [URL] = []

    override func tearDown() {
        temporaryDirectories.forEach { try? FileManager.default.removeItem(at: $0) }
        temporaryDirectories = []
        super.tearDown()
    }

    func test_compressVideo_whenQualityIsMedium_thenTheResultIsASmallerPlayableVideo() async throws {
        let videoURL = try await makeVideo(width: 640, height: 480, numberOfFrames: 20, bitRate: 8_000_000)
        let compressor = StreamVideoCompressor(progressUpdateInterval: 0.005)
        nonisolated(unsafe) var reportedProgress: [Double] = []

        let compressedURL = try await compressor.compressVideo(at: videoURL, quality: .medium) {
            reportedProgress.append($0)
        }
        temporaryDirectories.append(compressedURL.deletingLastPathComponent())

        XCTAssertEqual(compressedURL.pathExtension, "mp4")
        XCTAssertEqual(reportedProgress.last, 1)
        // The progress must be polled while the export runs, not only reported once it finished.
        XCTAssertGreaterThan(reportedProgress.count, 1)
        XCTAssertTrue(reportedProgress.allSatisfy { $0 >= 0 && $0 <= 1 })
        let compressedTrack = await videoTrack(of: compressedURL)
        XCTAssertNotNil(compressedTrack)
        XCTAssertLessThan(try fileSize(of: compressedURL), try fileSize(of: videoURL))
    }

    func test_compressVideo_whenQualityIsOriginal_thenTheVideoKeepsItsResolution() async throws {
        let videoURL = try await makeVideo(width: 640, height: 480, numberOfFrames: 10, bitRate: 1_000_000)
        let compressor = StreamVideoCompressor()

        let compressedURL = try await compressor.compressVideo(at: videoURL, quality: .original) { _ in }
        temporaryDirectories.append(compressedURL.deletingLastPathComponent())

        let loadedTrack = await videoTrack(of: compressedURL)
        let track = try XCTUnwrap(loadedTrack)
        XCTAssertEqual(track.naturalSize, CGSize(width: 640, height: 480))
    }

    func test_compressVideo_whenTheQualityIsNotSupported_thenAnErrorIsThrown() async throws {
        let videoURL = try await makeVideo(width: 640, height: 480, numberOfFrames: 5, bitRate: 1_000_000)
        let compressor = StreamVideoCompressor()

        do {
            _ = try await compressor.compressVideo(
                at: videoURL,
                quality: .init(exportPreset: "StreamNotAnExportPreset")
            ) { _ in }
            XCTFail("The compression was expected to fail")
        } catch {
            XCTAssertTrue(error is VideoCompressionError)
        }
    }

    // MARK: - Helpers

    private func fileSize(of url: URL) throws -> Int64 {
        let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
        return try XCTUnwrap(attributes[.size] as? NSNumber).int64Value
    }

    private func videoTrack(of url: URL) async -> AVAssetTrack? {
        let asset = AVURLAsset(url: url)
        return await withCheckedContinuation { continuation in
            nonisolated(unsafe) let unsafeAsset = asset
            StreamAssetPropertyLoader().loadProperties([AssetProperty(\AVURLAsset.tracks)], of: asset) { _ in
                continuation.resume(returning: unsafeAsset.tracks(withMediaType: .video).first)
            }
        }
    }

    private func makeVideo(width: Int, height: Int, numberOfFrames: Int, bitRate: Int) async throws -> URL {
        let directory = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        temporaryDirectories.append(directory)
        let url = directory.appendingPathComponent("source.mov")

        let writer = try AVAssetWriter(outputURL: url, fileType: .mov)
        let input = AVAssetWriterInput(mediaType: .video, outputSettings: [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: width,
            AVVideoHeightKey: height,
            AVVideoCompressionPropertiesKey: [AVVideoAverageBitRateKey: bitRate]
        ])
        input.expectsMediaDataInRealTime = false
        let adaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: input, sourcePixelBufferAttributes: nil)
        writer.add(input)
        XCTAssertTrue(writer.startWriting())
        writer.startSession(atSourceTime: .zero)

        for frame in 0..<numberOfFrames {
            while !input.isReadyForMoreMediaData {
                try await Task.sleep(nanoseconds: 1_000_000)
            }
            let buffer = try makeNoisePixelBuffer(width: width, height: height)
            adaptor.append(buffer, withPresentationTime: CMTime(value: CMTimeValue(frame), timescale: 30))
        }
        input.markAsFinished()
        await writer.finishWriting()
        XCTAssertEqual(writer.status, .completed)
        return url
    }

    /// Creates a frame filled with noise, so that the video does not compress to almost nothing.
    private func makeNoisePixelBuffer(width: Int, height: Int) throws -> CVPixelBuffer {
        var pixelBuffer: CVPixelBuffer?
        let status = CVPixelBufferCreate(kCFAllocatorDefault, width, height, kCVPixelFormatType_32BGRA, nil, &pixelBuffer)
        XCTAssertEqual(status, kCVReturnSuccess)
        let buffer = try XCTUnwrap(pixelBuffer)

        CVPixelBufferLockBaseAddress(buffer, [])
        defer { CVPixelBufferUnlockBaseAddress(buffer, []) }
        let base = try XCTUnwrap(CVPixelBufferGetBaseAddress(buffer))
        arc4random_buf(base, CVPixelBufferGetBytesPerRow(buffer) * height)
        return buffer
    }
}
