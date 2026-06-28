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

    let item = AVPlayerItem(url: streamUrl)
    let player = AVPlayer(playerItem: item)
    player.allowsExternalPlayback = false

    self.player = player
    isPlaying = true

    statusTask = Task { [weak self] in
      await Self.activateAudioSession()
      if Task.isCancelled { return }
      player.play()

      for await status in item.publisher(for: \.status).values {
        guard let self else { return }
        guard status == .failed else { continue }
        pause()
        break
      }
    }
  }

  func pause() {
    teardown()
    isPlaying = false
    Task { await Self.deactivateAudioSession() }
  }

  private func teardown() {
    statusTask?.cancel()
    statusTask = nil
    player?.pause()
    player = nil
  }

  @concurrent
  private nonisolated static func activateAudioSession() async {
    #if os(iOS)
      let session = AVAudioSession.sharedInstance()
      try? session.setCategory(.playback)
      try? session.setActive(true)
    #endif
  }

  @concurrent
  private nonisolated static func deactivateAudioSession() async {
    #if os(iOS)
      let session = AVAudioSession.sharedInstance()
      try? session.setActive(false)
    #endif
  }
}
