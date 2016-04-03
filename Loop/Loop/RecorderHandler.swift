import EZAudio

protocol RecorderHandlerDelegate: EZRecorderDelegate {
    func recorderShouldLoop(recorder: EZRecorder!)
}

class RecorderHandler {
    static let shared = RecorderHandler()

    private var recorder: EZRecorder?

    private var maxBufferSize: UInt32?
    private var currentBufferSize: UInt32 = 0

    private var isRecording = false

    var delegate: RecorderHandlerDelegate?

    //
    private init() { }

    func enableRecording(enabled: Bool) {
        if enabled {
            startRecording()
        } else {
            stopRecording()
        }

        isRecording = enabled
    }

    func receiveData(
        fromBufferList bufferList: UnsafeMutablePointer<AudioBufferList>,
        withBufferSize bufferSize: UInt32) {
            if isRecording {
                if let maxBufferSize = maxBufferSize {
                    if currentBufferSize + bufferSize > maxBufferSize {
                        delegate?.recorderShouldLoop(recorder)
                    }
                }

                currentBufferSize += bufferSize

                recorder?.appendDataFromBufferList(bufferList,
                    withBufferSize: bufferSize)
            }
    }
}

private extension RecorderHandler {
    private func stopRecording() {
        recorder?.closeAudioFile()

        maxBufferSize = maxBufferSize ?? currentBufferSize
    }

    private func startRecording() {
        if let microphone = IOHandler.shared.currentMicrophone {
            currentBufferSize = 0

            let description = microphone.audioStreamBasicDescription()

            recorder = EZRecorder(URL: FileHandler.shared.newTempFileURL(),
                clientFormat: description,
                fileType: .M4A,
                delegate: delegate)
        }
    }
}
