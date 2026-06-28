import SwiftUI

struct PlaybackControlLarge: View {
  let player: RadioPlayer
  let song: Song?

  init(_ player: RadioPlayer, _ song: Song?) {
    self.player = player
    self.song = song
  }

  @State private var artworkUrl: URL?

  var body: some View {
    VStack(spacing: 24) {
      ZStack {
        if let artworkUrl {
          WaterRippleSurface(artworkUrl: artworkUrl) {
            withAnimation(.smooth) {
              player.toggle()
            }
          }

        } else {
          Circle().fill(.secondary)
        }

        PlaybackIndicator(player.isPlaying)
      }
      .frame(width: 320)

      CurrentSongView(song)
    }
    .onAppear {
      pickArtwork()
    }
  }

  private func pickArtwork() {
    if artworkUrl == nil {
      artworkUrl = Constants.images.randomElement().flatMap {
        Constants.imagesUrl?.appendingPathComponent($0)
      }
    }
  }
}
