import SwiftUI

struct PlaybackIndicator: View {
  let isPlaying: Bool

  init(_ isPlaying: Bool) {
    self.isPlaying = isPlaying
  }

  var body: some View {
    Image(isPlaying ? .pause : .play)
      .shadow(radius: 10)
      .foregroundStyle(.white)
      .allowsHitTesting(false)
  }
}
