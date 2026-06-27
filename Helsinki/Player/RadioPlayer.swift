import AVFoundation
import Combine

@MainActor
@Observable
final class RadioPlayer {
  private(set) var isPlaying = false

  private var statusTask: Task<Void, Never>?
  private var player: AVPlayer?

  func toggle() {
    isPlaying ? pause() : play()
  }

  func play() {
    guard let streamUrl = Constants.streamUrl else { return }

    configureAudioSession()

    let item = AVPlayerItem(url: streamUrl)
    let player = AVPlayer(playerItem: item)
    player.allowsExternalPlayback = false
    player.play()

    self.player = player
    isPlaying = true

    statusTask = Task { [weak self] in
      for await status in item.publisher(for: \.status).values {
        guard let self else { return }
        guard status == .failed else { continue }
        self.handleFailure()
        break
      }
    }
  }

  func pause() {
    teardown()
    isPlaying = false
    deactivateAudioSession()
  }

  private func handleFailure() {
    teardown()
    isPlaying = false
    deactivateAudioSession()
  }

  private func teardown() {
    statusTask?.cancel()
    statusTask = nil
    player?.pause()
    player = nil
  }

  private func configureAudioSession() {
    #if os(iOS)
      let session = AVAudioSession.sharedInstance()
      try? session.setCategory(.playback)
      try? session.setActive(true)
    #endif
  }

  private func deactivateAudioSession() {
    #if os(iOS)
      let session = AVAudioSession.sharedInstance()
      try? session.setActive(false, options: .notifyOthersOnDeactivation)
    #endif
  }
}
