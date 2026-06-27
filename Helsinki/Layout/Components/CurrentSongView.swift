import SwiftUI

struct CurrentSongView: View {
  let artist: String?
  let title: String?
  let alignment: HorizontalAlignment

  init(artist: String?, title: String?, alignment: HorizontalAlignment = .center) {
    self.artist = artist
    self.title = title
    self.alignment = alignment
  }

  var body: some View {
    VStack(alignment: alignment, spacing: 0) {
      Text("NYT SOI")
        .font(.panoBold(.headline))
      SafeText(artist)
        .font(.pitchSemibold(.subheadline))
      SafeText(title)
        .font(.pitchRegular(.subheadline))
    }
  }
}
