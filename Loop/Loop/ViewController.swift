

import Cocoa


class ViewController: NSViewController, NSWindowDelegate {

    var window: NSWindow!

    let backgroundView = SolidView()


    override func viewDidLoad() {
        super.viewDidLoad()

        self.window = NSApplication.sharedApplication().windows.first!

        self.window.delegate = self

        backgroundView.frame = view.bounds
        view.addSubview(backgroundView)


        //
        let dial = DialView(frame: NSRect(x: 10, y: 10, width: 100, height: 100))
        view.addSubview(dial)
    }

    func windowDidResize(notification: NSNotification) {
        backgroundView.frame = view.bounds
        view.addSubview(backgroundView)
    }
}

