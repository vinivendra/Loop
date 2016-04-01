import Cocoa
import EZAudio

var fileID = 0

class ViewController: NSViewController,
EZMicrophoneDelegate,
EZRecorderDelegate {

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

    var ioHandler: IOHandler?

    // MARK: Overrides
    override func viewDidLoad() {
        super.viewDidLoad()

        setupNotifications()

        ioHandler = IOHandler(delegate: self)

        updateIoUi()
    }

    func applicationWillTerminate(notification: NSNotification) {
        // Delete temp folder
        let manager = NSFileManager.defaultManager()
        _ = try? manager.removeItemAtURL(tempDirectoryURL)
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

        if let currentMicrophoneName = ioHandler?.currentInputDevice?.name {
            popupInputStream.selectItemWithTitle(currentMicrophoneName)
        }
    }

    func setupNewRecorder() {
        if let microphone = ioHandler?.currentMicrophone {
            fileID += 1

            let filePath = "testfile\(fileID).m4a"
            let tempURL = tempDirectoryURL.URLByAppendingPathComponent(filePath)

            recorder = EZRecorder(URL: tempURL,
                clientFormat: microphone.audioStreamBasicDescription(),
                fileType: .M4A,
                delegate: self)
        }
    }

    // MARK: EZMicrophoneDelegate

    func microphone(microphone: EZMicrophone!,
        hasBufferList bufferList: UnsafeMutablePointer<AudioBufferList>,
        withBufferSize bufferSize: UInt32,
        withNumberOfChannels numberOfChannels: UInt32) {
            if isRecording {
                recorder?.appendDataFromBufferList(bufferList,
                    withBufferSize: bufferSize)
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

        ioHandler?.updatePassthrough(enabled: monitoringIsEnabled)
    }

    @IBAction func updateButtonAction(sender: AnyObject) {
        updateIoUi()
    }

    @IBAction func popupInputStreamAction(sender: NSPopUpButton) {
        let selectedDeviceIndex = popupInputStream.indexOfSelectedItem
        let inputDevices: [EZAudioDevice] = EZAudioDevice.inputDevices()
        if let device = inputDevices[safe: selectedDeviceIndex] {
            ioHandler?.currentInputDevice = device
        }
    }
}
