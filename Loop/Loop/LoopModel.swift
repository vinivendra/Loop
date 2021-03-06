import EZAudio

class LoopModel: NSObject, EZMicrophoneDelegate, EZRecorderDelegate {

    static let shared = LoopModel()

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
    }

    func tearDown() {
        FileHandler.shared.tearDown()
    }

    // MARK: App Management
    func toggleRecording(enabled enabled: Bool) {
        RecorderHandler.shared.isRecording = enabled
    }

    func toggleMonitoring(enabled enabled: Bool) {
        IOHandler.shared.updatePassthrough(enabled: enabled)
    }

    func switchInputToDevice(atIndex selectedDeviceIndex: Int) {
        IOHandler.shared.switchInputToDevice(atIndex: selectedDeviceIndex)
    }

    // MARK: EZMicrophoneDelegate
    func microphone(microphone: EZMicrophone!,
        hasBufferList bufferList: UnsafeMutablePointer<AudioBufferList>,
        withBufferSize bufferSize: UInt32,
        withNumberOfChannels numberOfChannels: UInt32) {
            RecorderHandler.shared.receiveData(fromBufferList: bufferList,
                withBufferSize: bufferSize)
    }
}
