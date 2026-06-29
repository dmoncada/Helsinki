import SwiftUI

struct IosLayout: View {
  @Environment(RadioPlayer.self) private var player
  @Environment(NowPlayingViewModel.self) private var vm

  var body: some View {
    VStack(alignment: .leading) {
      CurrentProgramView(vm.program)

      PlaybackControlLarge(player, vm.image, vm.songs.first)
        .frame(
          maxWidth: .infinity,
          maxHeight: .infinity
        )
    }
    .padding()
    .withHelsinkiTopBar()
    .withHelsinkiBottomBar()
  }
}

#Preview(traits: .modifier(Dependencies())) {
  IosLayout()
}
