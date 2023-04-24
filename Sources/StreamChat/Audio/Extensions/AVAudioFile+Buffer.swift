//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import AVFoundation

/// Source: https://github.com/bastienFalcou/SoundWave
extension AVAudioFile {
    /// Returns a 2D array of floating-point values representing the waveform data of the audio file
    /// - Throws: An error if there is an issue reading the audio file or creating a buffer
    /// - Returns: A 2D array of floating-point values representing the waveform data of the audio file
    func buffer() throws -> [[Float]] {
        let frameCount = UInt32(length)

        /// Create an AVAudioFormat object with the specified parameters
        guard let format = AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: fileFormat.sampleRate,
            channels: fileFormat.channelCount,
            interleaved: false
        ) else {
            /// Return an empty array if the format cannot be created
            return []
        }

        /// Create an AVAudioPCMBuffer object with the specified format and frame capacity
        guard let buffer = AVAudioPCMBuffer(
            pcmFormat: format,
            frameCapacity: UInt32(length)
        ) else {
            /// Return an empty array if the buffer cannot be created
            return []
        }

        /// Read the audio file data into the buffer and return the analyzed data
        do {
            try read(into: buffer, frameCount: frameCount)
            return analyse(buffer: buffer)
        } catch {
            log.error(error)
            return []
        }
    }

    /// Analyses the data in the specified AVAudioPCMBuffer object and returns the result as a 2D array
    /// of floating-point values
    private func analyse(buffer: AVAudioPCMBuffer) -> [[Float]] {
        let channelCount = Int(buffer.format.channelCount)
        let frameLength = Int(buffer.frameLength)

        /// Create a 2D array of floating-point values with the specified dimensions
        var result = Array(
            repeating: [Float](
                repeatElement(0, count: frameLength)
            ),
            count: channelCount
        )

        for channel in 0..<channelCount {
            for sampleIndex in 0..<frameLength {
                /// Get the float channel data for the specified channel
                guard let floatChannelData = buffer.floatChannelData else {
                    continue
                }

                /// Calculate the square root of the sample value divided by the buffer frame length
                /// and convert to decibels
                let squareRoot = sqrt(
                    floatChannelData[channel][sampleIndex * buffer.stride] / Float(buffer.frameLength)
                )
                let dbPower = 20 * log10(squareRoot)
                result[channel][sampleIndex] = dbPower
            }
        }
        return result
    }
}
