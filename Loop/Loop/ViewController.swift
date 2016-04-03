import Cocoa
import EZAudio

class ViewController: NSViewController {

    @IBOutlet weak var popupInputStream: NSPopUpButtonCell!
    @IBOutlet weak var recordButton: NSButton!

    // MARK: Overrides
    override func viewDidLoad() {
        super.viewDidLoad()

        setupNotifications()

        updateIoUi()
    }

    func applicationWillTerminate(notification: NSNotification) {
        LoopModel.shared.tearDown()
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
        popupInputStream.addItemsWithTitles(LoopModel.shared.allMicrophoneNames)

        if let currentMicrophoneName = LoopModel.shared.currentMicrophoneName {
            popupInputStream.selectItemWithTitle(currentMicrophoneName)
        }
    }

    // MARK: IBActions

    @IBAction func playButtonAction(sender: NSButton) {
        LoopModel.shared.play()
    }

    @IBAction func pauseButtonAction(sender: NSButton) {
        LoopModel.shared.pause()
    }

    @IBAction func resetButtonAction(sender: NSButton) {
        LoopModel.shared.reset()
    }

    @IBAction func recordButtonAction(sender: NSButton) {
        let isRecording = (sender.state == NSOnState)

        LoopModel.shared.toggleRecording(enabled: isRecording)

        if isRecording {
            recordButton.title = "Recording..."
        } else {
            recordButton.title = "Record"
        }
    }

    @IBAction func monitoringCheckboxAction(sender: NSButton) {
        let monitoringIsEnabled = (sender.state == NSOnState)

        LoopModel.shared.toggleMonitoring(enabled: monitoringIsEnabled)
    }

    @IBAction func updateButtonAction(sender: AnyObject) {
        updateIoUi()
    }

    @IBAction func popupInputStreamAction(sender: NSPopUpButton) {
        let selectedDeviceIndex = popupInputStream.indexOfSelectedItem
        LoopModel.shared.switchInputToDevice(atIndex: selectedDeviceIndex)
    }
}
