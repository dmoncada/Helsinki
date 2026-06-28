import SwiftUI

struct PlaybackControlSmall: View {
  let player: RadioPlayer
  let program: Program?
  let song: Song?

  init(_ player: RadioPlayer, _ program: Program?, _ song: Song?) {
    self.player = player
    self.program = program
    self.song = song
  }

  var body: some View {
    HStack {
      PlaybackButton(player.isPlaying) {
        withAnimation(.smooth) {
          player.toggle()
        }
      }

      VStack(alignment: .leading, spacing: 0) {
        SafeText(program?.title)
          .font(.panoBold(.headline))
        SafeText(song?.artist)
          .font(.pitchSemibold(.subheadline))
        SafeText(song?.song)
          .font(.pitchRegular(.subheadline))
      }
    }
  }
}
