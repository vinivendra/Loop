

import Cocoa
import EZAudio


class ViewController: NSViewController, EZMicrophoneDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()

        EZMicrophone.sharedMicrophone().delegate = self
        EZMicrophone.sharedMicrophone().startFetchingAudio()

        print("Using input device \(EZMicrophone.sharedMicrophone().device)")
        EZMicrophone.sharedMicrophone().output = EZOutput.sharedOutput()

        EZOutput.sharedOutput().startPlayback()

        print("Using output device \(EZOutput.sharedOutput().device)")

    }

    override var representedObject: AnyObject? {
        didSet {
        // Update the view, if already loaded.
        }
    }


}

