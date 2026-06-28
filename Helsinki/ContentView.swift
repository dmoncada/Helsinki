import SwiftUI

struct ContentView: View {
  @Environment(NowPlayingViewModel.self) private var vm

  var body: some View {
    Group {
      #if os(iOS)
        IosLayout()
      #else
        MacosLayout()
      #endif
    }
    .task { await vm.poll() }
  }
}

#Preview(traits: .modifier(Dependencies())) {
  ContentView()
}
