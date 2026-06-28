import AVFoundation
import Combine
import MediaPlayer

@MainActor
@Observable
final class RadioPlayer {
  private(set) var isPlaying = false

  private var statusTask: Task<Void, Never>?
  private var player: AVPlayer?

  init() {
    configureRemoteCommands()
  }

  func toggle() {
    isPlaying ? pause() : play()
  }

  func play() {
    guard let streamUrl = Constants.streamUrl else { return }

    let item = AVPlayerItem(url: streamUrl)
    let player = AVPlayer(playerItem: item)
    player.allowsExternalPlayback = false
    player.play()

    self.player = player
    self.isPlaying = true
    self.updateNowPlayingInfo()

    statusTask = Task { [weak self] in
      await Self.activateAudioSession()
      if Task.isCancelled { return }

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
    updateNowPlayingInfo()
    Task { await Self.deactivateAudioSession() }
  }

  private func teardown() {
    statusTask?.cancel()
    statusTask = nil
    player?.pause()
    player = nil
  }

  private func configureRemoteCommands() {
    let center = MPRemoteCommandCenter.shared()

    center.playCommand.addTarget { [weak self] _ in
      guard let self, !isPlaying else { return .commandFailed }
      play()
      return .success
    }

    center.pauseCommand.addTarget { [weak self] _ in
      guard let self, isPlaying else { return .commandFailed }
      pause()
      return .success
    }

    center.togglePlayPauseCommand.addTarget { [weak self] _ in
      guard let self else { return .commandFailed }
      toggle()
      return .success
    }

    center.nextTrackCommand.isEnabled = false
    center.previousTrackCommand.isEnabled = false
    center.changePlaybackPositionCommand.isEnabled = false
  }

  private func updateNowPlayingInfo() {
    MPNowPlayingInfoCenter.default().nowPlayingInfo = [
      MPMediaItemPropertyTitle: "Radio Helsinki",
      MPNowPlayingInfoPropertyIsLiveStream: true,
      MPNowPlayingInfoPropertyPlaybackRate: isPlaying ? 1.0 : 0.0
    ]
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
