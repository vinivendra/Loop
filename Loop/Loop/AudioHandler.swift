

import EZAudio


class AudioHandler {

    static var inputDevices: [EZAudioDevice] {
        get {
            return EZAudioDevice.inputDevices() as! [EZAudioDevice]
        }
    }

    static var inputDeviceNames: [String] {
        get {
            let devices = EZAudioDevice.inputDevices() as! [EZAudioDevice]
            return devices.map { $0.name }
        }
    }

    static var outputDeviceNames: [String] {
        get {
            let devices = EZAudioDevice.outputDevices() as! [EZAudioDevice]
            return devices.map { $0.name }
        }
    }

    static func inputDevice(forName name: String) -> EZAudioDevice? {
        let devices = EZAudioDevice.inputDevices() as! [EZAudioDevice]
        return devices.filter { $0.name == name }.first
    }

    static func outputDevice(forName name: String) -> EZAudioDevice? {
        let devices = EZAudioDevice.outputDevices() as! [EZAudioDevice]
        return devices.filter { $0.name == name }.first
    }
}

