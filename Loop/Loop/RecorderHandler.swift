import EZAudio

class RecorderHandler {
    static let shared = RecorderHandler()

    private var recorder: EZRecorder?

    var isRecording = false {
        didSet {
            if isRecording {
                refreshRecorder()
            } else {
                recorder?.closeAudioFile()
            }
        }
    }

    var delegate: EZRecorderDelegate?

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
}
