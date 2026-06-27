import SwiftUI

struct IosLayout: View {
  @Environment(RadioPlayer.self) private var player
  @Environment(NowPlayingViewModel.self) private var viewModel

  @State private var artworkUrl: URL?

  var body: some View {
    VStack(alignment: .leading) {
      CurrentProgramView(
        title: viewModel.programTitle,
        schedule: viewModel.programSchedule,
        alignment: .leading
      )

      VStack(spacing: 24) {
        ZStack {
          if let artworkUrl {
            WaterRippleSurface(artworkUrl: artworkUrl) {
              togglePlayback()
            }

          } else {
            Circle().fill(.secondary)
          }

          PlaybackIndicator(isPlaying: player.isPlaying)
        }
        .frame(maxWidth: 320)
        .aspectRatio(1, contentMode: .fit)
        .accessibilityAddTraits(.isButton)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(player.isPlaying ? "Pause" : "Play")
        .accessibilityAction(.default, togglePlayback)

        CurrentSongView(
          artist: viewModel.songArtist,
          title: viewModel.songTitle
        )
      }
      .frame(
        maxWidth: .infinity,
        maxHeight: .infinity
      )
    }
    .frame(
      maxWidth: .infinity,
      maxHeight: .infinity
    )
    .padding()
    .withHelsinkiTopBar()
    .withHelsinkiBottomBar()
    .onAppear { pickArtwork() }
    .task { await viewModel.poll() }
  }

  private func pickArtwork() {
    if artworkUrl == nil {
      artworkUrl = Constants.images.randomElement().flatMap {
        Constants.imagesUrl?.appendingPathComponent($0)
      }
    }
  }

  private func togglePlayback() {
    withAnimation(.smooth) {
      player.toggle()
    }
  }
}
