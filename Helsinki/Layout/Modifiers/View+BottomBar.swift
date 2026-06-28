import SwiftUI

struct BottomBarModifier: ViewModifier {
  @Environment(RadioPlayer.self) private var player
  @Environment(NowPlayingViewModel.self) private var vm

  func body(content: Content) -> some View {
    content
      .safeAreaBar(edge: .bottom, alignment: .leading) {
        PlaybackControlSmall(
          player,
          vm.program,
          vm.songs.first
        )
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

#Preview(traits: .modifier(Dependencies())) {
  Text("Hello, world!")
    .frame(
      maxWidth: .infinity,
      maxHeight: .infinity
    )
    .withHelsinkiBottomBar()
}
