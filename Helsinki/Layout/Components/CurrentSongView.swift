import SwiftUI

struct CurrentSongView: View {
  let song: Song?

  init(_ song: Song?) {
    self.song = song
  }

  var body: some View {
    VStack(alignment: .center, spacing: 0) {
      Text("NYT SOI")
        .font(.panoBold(.headline))
      SafeText(song?.artist)
        .font(.pitchSemibold(.subheadline))
      SafeText(song?.song)
        .font(.pitchRegular(.subheadline))
    }
  }
}
