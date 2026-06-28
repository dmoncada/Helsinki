import SwiftUI

struct PastSongsView: View {
  let songs: [Song]

  init(_ songs: [Song]) {
    self.songs = songs
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("ÄSKEN SOI")
        .font(.panoBold(.headline))

      ForEach(songs.dropFirst().prefix(10)) { song in
        VStack(alignment: .leading) {
          SafeText(song.artist)
            .font(.pitchSemibold(.headline))
          SafeText(song.song)
            .font(.pitchRegular(.subheadline))
        }
      }
    }
  }
}
