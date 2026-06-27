import SwiftUI

struct PlaybackIndicator: View {
  let isPlaying: Bool

  var body: some View {
    Image(isPlaying ? .pause : .play)
      .shadow(radius: 10)
      .foregroundStyle(.white)
      .accessibilityHidden(true)
      .allowsHitTesting(false)
  }
}
