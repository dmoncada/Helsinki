import SwiftUI

struct PlaybackControlLarge: View {
  let player: RadioPlayer
  let image: Data?
  let song: Song?

  init(_ player: RadioPlayer, _ image: Data?, _ song: Song?) {
    self.player = player
    self.image = image
    self.song = song
  }

  var body: some View {
    VStack(spacing: 24) {
      ZStack {
        if let image {
          WaterRippleSurface(artwork: image) {
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
  }
}
