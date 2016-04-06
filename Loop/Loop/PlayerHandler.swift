import EZAudio

class PlayerHandler {
    static let shared = PlayerHandler()

    var delegate: EZAudioPlayerDelegate? {
        didSet {
            playerStack.delegate = delegate
        }
    }

    private let playerStack = PlayerStack()

    //
    func addFile(fileURL: NSURL) {
        playerStack.pushPlayer(forFile: fileURL)
    }

    func play() {
        playerStack.play()
    }

    func pause() {
        playerStack.pause()
    }

    func reset() {
        playerStack.reset()
    }
}

class PlayerStack {
    private var stack = [EZAudioPlayer]()

    private var state = EZAudioPlayerState.Playing

    var delegate: EZAudioPlayerDelegate? {
        didSet {
			updateDelegate()
        }
    }

    //
    func pushPlayer(forFile fileURL: NSURL) {
        let file = EZAudioFile(URL: fileURL)
        let player = EZAudioPlayer(audioFile: file)
        player.shouldLoop = true

        if state == .Playing {
            player.play()
        }

        stack.append(player)

		updateDelegate()
    }

    func pop() {
        let player = stack.popLast()
        player?.pause()
    }

    func play() {
        state = .Playing

        stack.forEach { player in
            player.play()
        }
    }

    func pause() {
        state = .Paused

        stack.forEach { player in
            player.pause()
        }
    }

    func reset() {
        state = .Playing

        stack.forEach { player in
            player.seekToFrame(0)
            player.play()
        }
    }

	private func updateDelegate() {
		stack.first?.delegate = self.delegate
	}
}
