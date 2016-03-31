

import Cocoa
import EZAudio

class ViewController: NSViewController, EZMicrophoneDelegate {

    @IBOutlet weak var popupInputStream: NSPopUpButtonCell!

    var currentInputDevice: EZAudioDevice? {
        get {
            return currentMicrophone!.device
        }
        set {
            currentMicrophone = EZMicrophone(delegate: self)
            currentMicrophone?.device = newValue

            updatePassthrough()
        }
    }

    var currentMicrophone = EZMicrophone.sharedMicrophone()

    override func viewDidLoad() {
        super.viewDidLoad()

        for device in AudioHandler.inputDevices
        where device.name.containsString("USB") {
            currentInputDevice = device
            break
        }

        currentMicrophone.delegate = self

        updatePassthrough()

        updateIoUi()
    }

    func updateIoUi() {
        popupInputStream.removeAllItems()
        popupInputStream.addItemsWithTitles(AudioHandler.inputDeviceNames)

        if let currentMicrophoneName = currentInputDevice!.name {
            popupInputStream.selectItemWithTitle(currentMicrophoneName)
        }
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

    @IBAction func monitoringCheckboxAction(sender: NSButton) {

        let monitoringIsEnabled = (sender.state == NSOnState)

        updatePassthrough(enabled: monitoringIsEnabled)
    }

    @IBAction func updateButtonAction(sender: AnyObject) {
        updateIoUi()
    }

    @IBAction func popupInputStreamAction(sender: NSPopUpButton) {
        let selectedDeviceIndex = popupInputStream.indexOfSelectedItem
        let inputDevices: [EZAudioDevice] = EZAudioDevice.inputDevices() as! [EZAudioDevice]
        if let device = inputDevices[safe: selectedDeviceIndex] {
            currentInputDevice = device
        }
    }
}
