import EZAudio

class IOHandler {
    static let shared = IOHandler()

	var delegate: EZMicrophoneDelegate? {
		didSet {
			currentMicrophone.delegate = delegate
		}
	}

    var currentInputDevice: EZAudioDevice? {
        get {
            return currentMicrophone!.device
        }
        set {
            currentMicrophone = EZMicrophone(delegate: delegate)
            currentMicrophone?.device = newValue

            updatePassthrough()
        }
    }

    var currentMicrophone = EZMicrophone.sharedMicrophone()

    private init() {
        for device in EZAudioDevice.inputDevices()
        where device.name.containsString("USB") {
            currentInputDevice = device
            break
        }

        updatePassthrough()
    }

    func updatePassthrough(enabled enabled: Bool = true) {
        if enabled {
            currentMicrophone.startFetchingAudio()
            currentMicrophone.output = EZOutput.sharedOutput()
            EZOutput.sharedOutput().startPlayback()
        } else {
            currentMicrophone.stopFetchingAudio()
            currentMicrophone.output = nil
            EZOutput.sharedOutput().stopPlayback()
        }
    }
}
