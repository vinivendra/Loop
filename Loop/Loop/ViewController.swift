import Cocoa
import EZAudio

class ViewController: NSViewController,
EZMicrophoneDelegate,
EZRecorderDelegate {

    @IBOutlet weak var popupInputStream: NSPopUpButtonCell!
    @IBOutlet weak var recordButton: NSButton!

    // MARK: Overrides
    override func viewDidLoad() {
        super.viewDidLoad()

        setupNotifications()

        IOHandler.shared.delegate = self
		RecorderHandler.shared.delegate = self

        updateIoUi()
    }

    func applicationWillTerminate(notification: NSNotification) {
        FileHandler.shared.tearDown()
    }

    // MARK: Setup and Update
    func setupNotifications() {
        let notificationCenter = NSNotificationCenter.defaultCenter()
        notificationCenter.addObserver(self,
            selector: #selector(ViewController.applicationWillTerminate(_:)),
            name: NSApplicationWillTerminateNotification,
            object: nil)
    }

    func updateIoUi() {
        popupInputStream.removeAllItems()
        popupInputStream.addItemsWithTitles(AudioHandler.inputDeviceNames)

        if let currentInputDevice = IOHandler.shared.currentInputDevice {
            popupInputStream.selectItemWithTitle(currentInputDevice.name)
        }
    }

    func setupNewRecorder() {
        RecorderHandler.shared.refreshRecorder()
    }

    // MARK: EZMicrophoneDelegate

    func microphone(microphone: EZMicrophone!,
        hasBufferList bufferList: UnsafeMutablePointer<AudioBufferList>,
        withBufferSize bufferSize: UInt32,
        withNumberOfChannels numberOfChannels: UInt32) {
            RecorderHandler.shared.receiveData(fromBufferList: bufferList,
                withBufferSize: bufferSize)
    }

    // MARK: IBActions
    @IBAction func recordButtonAction(sender: NSButton) {
        let isRecording = (sender.state == NSOnState)

        RecorderHandler.shared.isRecording = isRecording

        if isRecording {
            recordButton.title = "Recording..."
        } else {
            recordButton.title = "Record"
        }
    }

    @IBAction func monitoringCheckboxAction(sender: NSButton) {

        let monitoringIsEnabled = (sender.state == NSOnState)

        IOHandler.shared.updatePassthrough(enabled: monitoringIsEnabled)
    }

    @IBAction func updateButtonAction(sender: AnyObject) {
        updateIoUi()
    }

    @IBAction func popupInputStreamAction(sender: NSPopUpButton) {
        let selectedDeviceIndex = popupInputStream.indexOfSelectedItem
        let inputDevices: [EZAudioDevice] = EZAudioDevice.inputDevices()
        if let device = inputDevices[safe: selectedDeviceIndex] {
            IOHandler.shared.currentInputDevice = device
        }
    }
}
