import EZAudio

class IOHandler {
    var delegate: EZMicrophoneDelegate

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

    init(delegate: EZMicrophoneDelegate) {
        self.delegate = delegate

        for device in EZAudioDevice.inputDevices()
        where device.name.containsString("USB") {
            currentInputDevice = device
            break
        }

        currentMicrophone.delegate = delegate

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
