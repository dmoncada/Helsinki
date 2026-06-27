import SwiftUI

struct ContentView: View {
  @State private var player = RadioPlayer()
  @State private var viewModel = NowPlayingViewModel()

  var body: some View {
    Group {
      #if os(iOS)
        IosLayout()
      #else
        MacosLayout()
      #endif
    }
    .environment(player)
    .environment(viewModel)
  }
}

#Preview {
  ContentView()
}
