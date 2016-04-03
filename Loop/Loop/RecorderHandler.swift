import EZAudio

class RecorderHandler {
    static let shared = RecorderHandler()

    private var recorder: EZRecorder?

    private var maxBufferSize: UInt32?

    private var isRecording = false

    var delegate: EZRecorderDelegate?

    //
    private init() { }

    func refreshRecorder() {
        if let microphone = IOHandler.shared.currentMicrophone {
            let description = microphone.audioStreamBasicDescription()

            recorder = EZRecorder(URL: FileHandler.shared.newTempFileURL(),
                clientFormat: description,
                fileType: .M4A,
                delegate: delegate)
        }
    }

    func receiveData(
        fromBufferList bufferList: UnsafeMutablePointer<AudioBufferList>,
        withBufferSize bufferSize: UInt32) {
            if isRecording {


                recorder?.appendDataFromBufferList(bufferList,
                    withBufferSize: bufferSize)
            }
    }

    func enableRecording(enabled: Bool) {
        if enabled {
            refreshRecorder()
        } else {
            recorder?.closeAudioFile()
        }

        isRecording = enabled
    }
}
