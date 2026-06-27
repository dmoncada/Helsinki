import SwiftUI

struct BottomBarModifier: ViewModifier {
  @Environment(RadioPlayer.self) private var player
  @Environment(NowPlayingViewModel.self) private var viewModel

  func body(content: Content) -> some View {
    content
      .safeAreaBar(edge: .bottom, alignment: .leading) {
        HStack {
          PlaybackButton(isPlaying: player.isPlaying) {
            withAnimation(.smooth) {
              player.toggle()
            }
          }

          VStack(alignment: .leading, spacing: 0) {
            SafeText(viewModel.programTitle)
              .font(.panoBold(.headline))
            SafeText(viewModel.songArtist)
              .font(.pitchSemibold(.subheadline))
            SafeText(viewModel.songTitle)
              .font(.pitchRegular(.subheadline))
          }
          .frame(maxHeight: .infinity)
        }
        .frame(height: 60)
        .padding()
      }
  }
}

extension View {
  func withHelsinkiBottomBar() -> some View {
    modifier(BottomBarModifier())
  }
}
