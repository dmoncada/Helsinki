import SwiftUI

struct PlaybackButton: View {
  let isPlaying: Bool
  let action: () -> Void

  init(_ isPlaying: Bool, action: @escaping () -> Void) {
    self.isPlaying = isPlaying
    self.action = action
  }

  var body: some View {
    Button(action: action) {
      ZStack {
        CircularRing()

        Image(isPlaying ? .pause : .play)
          .resizable()
          .scaledToFit()
          .scaleEffect(0.35)
      }
    }
    .buttonStyle(.plain)
  }
}

private struct CircularRing: View {
  var body: some View {
    ZStack {
      Circle().fill(.foreground)
      Circle().fill(.background).scaleEffect(0.85)
    }
  }
}

#Preview {
  @Previewable @State var playing = false

  VStack {
    PlaybackButton(playing) { playing.toggle() }
      .frame(width: 60, height: 60)

    PlaybackButton(playing) { playing.toggle() }
      .frame(width: 120, height: 120)

    PlaybackButton(playing) { playing.toggle() }
      .frame(width: 180, height: 180)
      .foregroundStyle(.tint)
  }
}
