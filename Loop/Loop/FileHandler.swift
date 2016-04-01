import Cocoa

class FileHandler {
    static let shared = FileHandler()

    private var fileID = 0

    private lazy var tempDirectoryURL: NSURL = {
        let manager = NSFileManager.defaultManager()

        let desktopURL = NSURL(fileURLWithPath: "\(NSHomeDirectory())/Desktop")
        let tempURL = try? manager.URLForDirectory(
                .ItemReplacementDirectory,
            inDomain: .UserDomainMask,
            appropriateForURL: desktopURL,
            create: true)
        return tempURL ?? desktopURL
    }()

    private init() { }

    func tearDown() {
        // Delete temp folder
        let manager = NSFileManager.defaultManager()
        _ = try? manager.removeItemAtURL(tempDirectoryURL)
    }

    func newTempFileURL() -> NSURL {
        fileID += 1

        let filePath = "testfile\(fileID).m4a"
        let tempURL = tempDirectoryURL.URLByAppendingPathComponent(filePath)

        return tempURL
    }
}
