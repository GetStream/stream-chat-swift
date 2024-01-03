//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import AVFoundation

// MARK: - Protocol

/// Describes an object that can record audio
public protocol AudioRecording {
    /// A static function which returns an instance of the type conforming to `AudioRecording`
    init()

    /// Subscribes the provided object on AudioRecorder's updates
    func subscribe(_ subscriber: AudioRecordingDelegate)

    /// Begin the recording process and calls the completionHandler once all the permission requests
    /// have been answered.
    /// - Parameter completionHandler: The completionHandler to call once the recording has
    /// started successfully *only*. In the case of an error the completionHandler won't be called and the
    /// delegate will be informed of the error in the `didFail` method.
    /// - Note: If the recording permission has been answered before
    /// the completionHandler will be called immediately, otherwise it will be called once the user has
    /// replied on the request permission prompt.
    func beginRecording(_ completionHandler: @escaping (() -> Void))

    /// Pause the currently active recording process
    func pauseRecording()

    /// Resume a paused recording process
    func resumeRecording()

    /// Stop a recording process
    func stopRecording()
}

// MARK: - Implementation

/// Definition of a class to handle audio recording
open class StreamAudioRecorder: NSObject, AudioRecording, AVAudioRecorderDelegate, AppStateObserverDelegate {
    /// Contains the configuration properties required by the AudioRecorder
    public struct Configuration {
        /// The settings that will be used to create **internally** the AVAudioRecorder instances
        public var audioRecorderSettings: [String: Any]

        /// The path to which we would like to store temporary and finalised recording files.
        public var audioRecorderBaseStorageURL: URL

        /// The temporary name of the file to which AVAudioRecorder instances will store recordings.
        /// - Note: Upon recording completion the file will be moved to a new location using a UUID as
        /// file name.
        public var audioRecorderFileName: String

        /// The extension of the files (temporary and finalised) the `AudioRecorder` is managing.
        public var audioRecorderFileExtension: String

        /// The interval at which the `AudioPlayer` will be fetching updates on the active `AVAudioPlayer`
        /// meters.
        public var metersObserverInterval: TimeInterval

        /// The interval at which the `AudioPlayer` will be fetching updates on the duration of the
        /// recorded track.
        public var durationObserverInterval: TimeInterval

        public init(
            audioRecorderSettings: [String: Any],
            audioRecorderBaseStorageURL: URL,
            audioRecorderFileName: String,
            audioRecorderFileExtension: String,
            metersObserverInterval: TimeInterval,
            durationObserverInterval: TimeInterval
        ) {
            self.audioRecorderSettings = audioRecorderSettings
            self.audioRecorderBaseStorageURL = audioRecorderBaseStorageURL
            self.audioRecorderFileName = audioRecorderFileName
            self.audioRecorderFileExtension = audioRecorderFileExtension
            self.metersObserverInterval = metersObserverInterval
            self.durationObserverInterval = durationObserverInterval
        }

        /// The default Configuration that is being bused by `StreamAudioRecorder`
        public static let `default` = Configuration(
            audioRecorderSettings: [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 12000,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ],
            audioRecorderBaseStorageURL: FileManager.default.temporaryDirectory,
            audioRecorderFileName: "recording",
            audioRecorderFileExtension: "aac",
            metersObserverInterval: 0.1,
            durationObserverInterval: 0.5
        )
    }

    /// The object containing information regarding AVAudioRecorder settings, file names etc.
    private let configuration: Configuration

    /// The `audioSessionConfigurator` will be called when the recorder needs to request or resign
    /// the permission to record from the current `AudioSession`
    private var audioSessionConfigurator: AudioSessionConfiguring

    /// A normaliser that will be responsible to polish the powering meters as they will be send by
    /// the AVAudioRecorder
    private let audioRecorderMeterNormaliser: AudioValuePercentageNormaliser

    /// The provider that will be asked when a new AVAudioRecorder instance is required.
    private let audioRecorderAVProvider: (URL, [String: Any]) throws -> AVAudioRecorder

    /// Private property to store the current recording context
    private lazy var contextValueAccessor: AudioRecordingContextAccessor = .init(.initial)

    /// Describes the recorders's current recording state. The access to this property is thread-safe
    private(set) var context: AudioRecordingContext {
        get { contextValueAccessor.value }
        set {
            contextValueAccessor.value = newValue
            multicastDelegate.invoke { $0.audioRecorder(self, didUpdateContext: newValue) }
        }
    }

    /// property to access the current recording URL
    var recordingURL: URL? { audioRecorder?.url }

    /// If a recording session is in progress, this property holds a reference to the audio recorder used
    private var audioRecorder: AVAudioRecorder?

    private let appStateObserver: AppStateObserving

    /// If a recording session is in progress, this property holds a reference to the timer that is being used
    /// to receive the updated meters from the active `AVAudioRecorder` instance.
    private var metersObservingTimer: RepeatingTimerControl?

    /// If a recording session is in progress, this property holds a reference to the timer that is being used
    /// to observer the duration of the recorded track.
    private var durationObservingTimer: RepeatingTimerControl?

    /// The delegate to which the `AudioRecorder` will forward status updates
    private var multicastDelegate: MulticastDelegate<AudioRecordingDelegate>

    // MARK: - Lifecycle

    override public required convenience init() {
        self.init(configuration: .default)
    }

    /// Initialises a new instance of StreamAudioRecorder
    /// - Parameters:
    ///   - audioSessionConfigurator: The configurator to use to interact with `AVAudioSession`
    ///   - audioRecorderSettings: The settings that will be used any time a new `AVAudioRecorder` is instantiated
    ///   - audioFileName: The name of the file that will be used by every `AVAudioRecorder` instance to store in progress recordings.
    ///   - audioRecorderBaseStorageURL: The path in where we would like to store temporary and finalised recording files.
    ///   - audioRecorderMeterNormaliser: The normaliser that will be used to transform `AVAudioRecorder's` updated meter values.
    public convenience init(
        configuration: Configuration
    ) {
        self.init(
            configuration: configuration,
            audioSessionConfigurator: StreamAudioSessionConfigurator(),
            audioRecorderMeterNormaliser: AudioValuePercentageNormaliser(),
            appStateObserver: StreamAppStateObserver(),
            audioRecorderAVProvider: AVAudioRecorder.init
        )
    }

    internal init(
        configuration: Configuration,
        audioSessionConfigurator: AudioSessionConfiguring,
        audioRecorderMeterNormaliser: AudioValuePercentageNormaliser,
        appStateObserver: AppStateObserving,
        audioRecorderAVProvider: @escaping (URL, [String: Any]) throws -> AVAudioRecorder
    ) {
        self.audioSessionConfigurator = audioSessionConfigurator
        self.configuration = configuration
        self.audioRecorderMeterNormaliser = audioRecorderMeterNormaliser
        self.appStateObserver = appStateObserver
        self.audioRecorderAVProvider = audioRecorderAVProvider
        multicastDelegate = .init()

        super.init()

        setUp()
    }

    /// Provides a way to customise of the underline audioSessionConfiguration, in order to allow extension
    /// on the logic that handles the `AVAudioSession.shared`.
    /// - Parameters:
    ///     - audioSessionConfiguration: The new instance of the audioSessionConfigurator that will
    ///     be used whenever the player needs to interact with the `AVAudioSession.shared`.
    public func configure(_ audioSessionConfigurator: AudioSessionConfiguring) {
        self.audioSessionConfigurator = audioSessionConfigurator
    }

    // MARK: - AudioRecording

    open func subscribe(_ subscriber: AudioRecordingDelegate) {
        multicastDelegate.add(additionalDelegate: subscriber)
    }

    open func beginRecording(_ completionHandler: @escaping (() -> Void)) {
        do {
            /// Enable recording on `AudioSession`
            try audioSessionConfigurator.activateRecordingSession()

            /// Request record permission. The first time this will be executed, it will prompt the user
            /// to allow recording.
            audioSessionConfigurator.requestRecordPermission { [weak self] in
                self?.handleRecordRequest($0, completionHandler: completionHandler)
            }
        } catch {
            /// In case we failed to activate the `AudioSession` for recording, inform the delegates
            multicastDelegate.invoke {
                $0.audioRecorder(self, didFailWithError: error)
            }
        }
    }

    open func pauseRecording() {
        guard audioRecorder?.isRecording == true else {
            return
        }

        audioRecorder?.pause()
        context = .init(
            state: .paused,
            duration: context.duration,
            averagePower: context.averagePower
        )
    }

    open func resumeRecording() {
        guard audioRecorder?.isRecording == false else {
            return
        }
        do {
            /// Re-enable recording on `AudioSession`
            try audioSessionConfigurator.activateRecordingSession()

            if audioRecorder?.record() == false {
                throw AudioRecorderError.failedToResume()
            } else {
                context = .init(
                    state: .recording,
                    duration: context.duration,
                    averagePower: context.averagePower
                )
            }
        } catch {
            multicastDelegate.invoke {
                $0.audioRecorder(self, didFailWithError: error)
            }
        }
    }

    open func stopRecording() {
        /// If we are recording, we are going to stop
        if audioRecorder?.isRecording == true {
            audioRecorder?.stop()
        }

        /// Stop the active observers
        stopObservers()

        do {
            /// We will try to deactivate recording from the `AudioSession`
            try audioSessionConfigurator.deactivateRecordingSession()
        } catch {
            multicastDelegate.invoke {
                $0.audioRecorder(self, didFailWithError: error)
            }
        }
    }

    // MARK: - AVAudioRecorderDelegate

    open func audioRecorderDidFinishRecording(
        _ recorder: AVAudioRecorder,
        successfully flag: Bool
    ) {
        guard flag else {
            /// If the recording operation hasn't completed successfully, inform the delegates
            multicastDelegate.invoke {
                $0.audioRecorder(
                    self,
                    didFailWithError: AudioRecorderError.failedToSave()
                )
            }
            return
        }

        /// Create the location/filename where the finalised recording will be moved.
        let newLocation = configuration
            .audioRecorderBaseStorageURL
            .appendingPathComponent(UUID().uuidString) // Using UUID here ensures that there will be conflicts between file names
            .appendingPathExtension(configuration.audioRecorderFileExtension) // Use the file extension provided with configuration
        do {
            let data = try Data(contentsOf: recorder.url.standardizedFileURL)
            try data.write(to: newLocation)

            /// If we managed to move the recording its new location, inform the delegates
            multicastDelegate.invoke { $0.audioRecorder(self, didFinishRecordingAtURL: newLocation) }
        } catch {
            /// If we failed to move the recording its new location, inform the delegates
            multicastDelegate.invoke { $0.audioRecorder(self, didFailWithError: error) }
        }
    }

    open func audioRecorderBeginInterruption(
        _ recorder: AVAudioRecorder
    ) {
        /// If an interruption occurs (e.g. a phone call) then we want to stop the recording as we don't
        /// have the ability to pause and resume it afterwards.
        stopRecording()
    }

    open func audioRecorderEndInterruption(
        _ recorder: AVAudioRecorder,
        withOptions flags: Int
    ) {
        /// Once the interruption completes and the execution return back to us, we have an opportunity
        /// to resume the interrupted recording.
        /// - Note: As we don't currently support pause/resume on recording this is a No-Op call
        /* No-op */
    }

    open func audioRecorderEncodeErrorDidOccur(
        _ recorder: AVAudioRecorder,
        error: Error?
    ) {
        /// In case of an error we want to update the delegates with an error
        multicastDelegate.invoke {
            $0.audioRecorder(
                self,
                didFailWithError: error ?? AudioRecorderError.unknown()
            )
        }

        /// Due to the error, we are going to stop recording and deactivate recording on the `AudioSession`
        stopRecording()
    }

    // MARK: - AppStateObserverDelegate

    func applicationDidMoveToBackground() {
        /// If an we move to the background then we want to stop the recording as we don't
        /// have the ability to pause and resume it afterwards.
        stopRecording()
    }

    func applicationDidMoveToForeground() {
        /// Once we return to the foreground and the execution return back to us, we have an opportunity
        /// to resume the interrupted recording.
        /// - Note: As we don't currently support pause/resume on recording this is a No-Op call
        /* No-op */
    }

    // MARK: - Private Helpers

    private func setUp() {
        appStateObserver.subscribe(self)
    }

    /// Private method to create a new AVAudioRecorder instance
    private func makeAudioRecorder() throws -> AVAudioRecorder {
        let audioRecorder = try audioRecorderAVProvider(
            configuration
                .audioRecorderBaseStorageURL
                .appendingPathComponent("\(configuration.audioRecorderFileName).\(configuration.audioRecorderFileExtension)"),
            configuration.audioRecorderSettings
        )

        /// Configure the AVAudioRecorder instance
        audioRecorder.delegate = self
        audioRecorder.isMeteringEnabled = true
        audioRecorder.prepareToRecord()

        return audioRecorder
    }

    private func makeRepeatingTimerControl(
        with timeInterval: TimeInterval,
        queue: DispatchQueue = .main,
        onFire: @escaping () -> Void
    ) -> RepeatingTimerControl {
        DefaultTimer.scheduleRepeating(
            timeInterval: timeInterval,
            queue: queue,
            onFire: onFire
        )
    }

    private func handleRecordRequest(
        _ permissionGranted: Bool,
        completionHandler: @escaping () -> Void
    ) {
        do {
            guard permissionGranted else {
                throw AudioRecorderError.noRecordPermission()
            }

            audioRecorder = try makeAudioRecorder()

            if audioRecorder?.record() == true {
                context = .init(state: .recording, duration: 0, averagePower: 0)
                startObservers()
                completionHandler()
            } else {
                // This error may occur due to the audio file name.
                throw AudioRecorderError.failedToBegin()
            }
        } catch {
            multicastDelegate.invoke { $0.audioRecorder(self, didFailWithError: error) }
        }
    }

    // MARK: AudioRecorder observation

    private func startObservers() {
        guard audioRecorder != nil else { return }

        /// Ensure we start from a clean state
        stopObservers()

        /// Register the durationObserver
        durationObservingTimer = makeRepeatingTimerControl(
            with: configuration.durationObserverInterval
        ) { [weak self] in
            guard let audioRecorder = self?.audioRecorder else { return }
            self?.audioRecorderWillUpdateDuration(audioRecorder)
        }

        /// Register the metersObserver
        metersObservingTimer = makeRepeatingTimerControl(
            with: configuration.metersObserverInterval
        ) { [weak self] in
            guard let audioRecorder = self?.audioRecorder else { return }
            self?.audioRecorderWillUpdateMeters(audioRecorder)
        }

        durationObservingTimer?.resume()
        metersObservingTimer?.resume()
    }

    private func stopObservers() {
        durationObservingTimer?.suspend()
        durationObservingTimer = nil

        metersObservingTimer?.suspend()
        metersObservingTimer = nil
    }

    // MARK: Event Handlers

    private func audioRecorderWillUpdateDuration(_ audioRecorder: AVAudioRecorder) {
        guard audioRecorder.isRecording else {
            return
        }
        context = .init(
            state: context.state,
            duration: audioRecorder.currentTime,
            averagePower: context.averagePower
        )
    }

    private func audioRecorderWillUpdateMeters(_ audioRecorder: AVAudioRecorder) {
        guard audioRecorder.isRecording else {
            return
        }

        audioRecorder.updateMeters()

        context = .init(
            state: context.state,
            duration: context.duration,
            averagePower: audioRecorderMeterNormaliser.normalise(
                audioRecorder.averagePower(forChannel: 0)
            )
        )
    }
}

// MARK: - Error

/// An enum that acts as a namespace for various audio recording errors that might occur
public class AudioRecorderError: ClientError {
    /// An unknown error occurred
    public static func unknown(file: StaticString = #file, line: UInt = #line) -> AudioRecorderError { .init("An unknown error occurred.", file, line) }

    /// User has not granted permission to record audio
    public static func noRecordPermission(file: StaticString = #file, line: UInt = #line) -> AudioRecorderError { .init("Missing permission to record.", file, line) }

    /// Failed to begin audio recording
    public static func failedToBegin(file: StaticString = #file, line: UInt = #line) -> AudioRecorderError { .init("Failed to begin recording.", file, line) }

    /// Failed to resume audio recording
    public static func failedToResume(file: StaticString = #file, line: UInt = #line) -> AudioRecorderError { .init("Failed to resume recording.", file, line) }

    /// Failed to save audio recording
    public static func failedToSave(file: StaticString = #file, line: UInt = #line) -> AudioRecorderError { .init("Failed to save recording.", file, line) }
}
