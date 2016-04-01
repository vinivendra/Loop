import Cocoa
import EZAudio

var fileID = 0

class ViewController: NSViewController, EZMicrophoneDelegate, EZRecorderDelegate {

    @IBOutlet weak var popupInputStream: NSPopUpButtonCell!
    @IBOutlet weak var recordButton: NSButton!

    lazy var tempDirectoryURL: NSURL = {
        let manager = NSFileManager.defaultManager()

        let desktopURL = NSURL(fileURLWithPath: "\(NSHomeDirectory())/Desktop")
        let tempURL = try? manager.URLForDirectory(.ItemReplacementDirectory,
            inDomain: .UserDomainMask,
            appropriateForURL: desktopURL,
            create: true)

        return tempURL ?? desktopURL
    }()

    var recorder: EZRecorder?

    var isRecording = false

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

    // MARK: Overrides
    override func viewDidLoad() {
        super.viewDidLoad()

        for device in EZAudioDevice.inputDevices()
        where device.name.containsString("USB") {
            currentInputDevice = device
            break
        }

        currentMicrophone.delegate = self

        updatePassthrough()

        updateIoUi()
    }

    // MARK: Setup and Update
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

    func setupNewRecorder() {
        fileID += 1

        let tempURL = tempDirectoryURL.URLByAppendingPathComponent("testfile\(fileID).m4a")

        print(tempURL)

        recorder = EZRecorder(URL: tempURL,
            clientFormat: currentMicrophone.audioStreamBasicDescription(),
            fileType: .M4A,
            delegate: self)
    }

    // MARK: EZMicrophoneDelegate

    func microphone(microphone: EZMicrophone!,
        hasBufferList bufferList: UnsafeMutablePointer<AudioBufferList>,
        withBufferSize bufferSize: UInt32,
        withNumberOfChannels numberOfChannels: UInt32) {
            if isRecording {
                recorder?.appendDataFromBufferList(bufferList, withBufferSize: bufferSize)
            }
    }

    // MARK: IBActions
    @IBAction func recordButtonAction(sender: NSButton) {
        isRecording = (sender.state == NSOnState)

        if isRecording {
            setupNewRecorder()
            recordButton.title = "Recording..."
        } else {
            recorder?.closeAudioFile()
            recordButton.title = "Record"
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
        let inputDevices: [EZAudioDevice] = EZAudioDevice.inputDevices()
        if let device = inputDevices[safe: selectedDeviceIndex] {
            currentInputDevice = device
        }
    }
}
