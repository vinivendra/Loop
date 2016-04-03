import EZAudio

class LoopModel: NSObject {

    static let shared = LoopModel()

    var isReadyForRecording = false
    var isFirstRecording = true

    var currentMicrophoneName: String? {
        get {
            return IOHandler.shared.currentInputDevice?.name
        }
    }

    var allMicrophoneNames: [String] {
        return AudioHandler.inputDeviceNames
    }

    // MARK: Lifecycle
    private override init() {
        super.init()

        IOHandler.shared.delegate = self
        RecorderHandler.shared.delegate = self
        PlayerHandler.shared.delegate = self
    }

    func tearDown() {
        FileHandler.shared.tearDown()
    }

    // MARK: App Management
    func play() {
        PlayerHandler.shared.play()
    }

    func pause() {
        PlayerHandler.shared.pause()
    }

    func reset() {
        PlayerHandler.shared.reset()
    }

    func toggleRecording(enabled enabled: Bool) {
        if enabled {
            if isFirstRecording {
                RecorderHandler.shared.enableRecording(true)
            } else {
                isReadyForRecording = true
            }
        } else {
            RecorderHandler.shared.enableRecording(false)

            let fileURL = FileHandler.shared.currentTempFileURL()
            PlayerHandler.shared.addFile(fileURL)

            if isFirstRecording {
                isFirstRecording = false
                RecorderHandler.shared.updateMaxRecordingDuration()
            }
        }
    }

    func toggleMonitoring(enabled enabled: Bool) {
        IOHandler.shared.updatePassthrough(enabled: enabled)
    }

    func switchInputToDevice(atIndex selectedDeviceIndex: Int) {
        IOHandler.shared.switchInputToDevice(atIndex: selectedDeviceIndex)
    }
}

extension LoopModel: EZMicrophoneDelegate {
    func microphone(microphone: EZMicrophone!,
        hasBufferList bufferList: UnsafeMutablePointer<AudioBufferList>,
        withBufferSize bufferSize: UInt32,
        withNumberOfChannels numberOfChannels: UInt32) {
            RecorderHandler.shared.receiveData(fromBufferList: bufferList,
                withBufferSize: bufferSize)
    }
}

extension LoopModel: RecorderHandlerDelegate {
    func recorderShouldLoop(recorder: EZRecorder!) {
        RecorderHandler.shared.enableRecording(false)
        let fileURL = FileHandler.shared.currentTempFileURL()
        PlayerHandler.shared.addFile(fileURL)
        RecorderHandler.shared.enableRecording(true)
    }
}

extension LoopModel: EZAudioPlayerDelegate {
    func audioPlayer(audioPlayer: EZAudioPlayer!,
        reachedEndOfAudioFile audioFile: EZAudioFile!) {
            if isReadyForRecording {
                RecorderHandler.shared.enableRecording(true)
                isReadyForRecording = false
            }
    }
}
