import SwiftUI

struct PlaybackButton: View {
  let isPlaying: Bool
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      CircularRing()
        .overlay {
          Image(isPlaying ? .pause : .play)
            .resizable()
            .scaledToFit()
            .scaleEffect(0.35)
        }
        .contentShape(.circle)
    }
    .buttonStyle(.plain)
  }
}

private struct CircularRing: View {
  var body: some View {
    Circle()
      .fill(.foreground)
      .overlay {
        Circle()
          .scaleEffect(0.85)
          .blendMode(.destinationOut)
      }
      .compositingGroup()
  }
}

#Preview {
  let playing = false

  VStack {
    PlaybackButton(isPlaying: playing) {}
      .frame(width: 60, height: 60)

    PlaybackButton(isPlaying: playing) {}
      .frame(width: 120, height: 120)

    PlaybackButton(isPlaying: playing) {}
      .frame(width: 180, height: 180)
      .foregroundStyle(.tint)
  }
}
