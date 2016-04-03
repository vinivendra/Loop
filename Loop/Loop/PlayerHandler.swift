import EZAudio

class PlayerHandler {
    static let shared = PlayerHandler()

    var delegate: EZAudioPlayerDelegate? {
        didSet {
            player.delegate = delegate
        }
    }

    private let player: EZAudioPlayer = {
        let instance = EZAudioPlayer()
        instance.shouldLoop = true
        return instance
    }()

    //
    func setFile(fileURL: NSURL) {
        player.audioFile = EZAudioFile(URL: fileURL)
    }

    func play() {
        player.play()
    }

    func pause() {
        player.pause()
    }

    func reset() {
        player.seekToFrame(0)
        player.play()
    }
}
