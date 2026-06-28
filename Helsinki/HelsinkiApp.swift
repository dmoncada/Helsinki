import SwiftUI

@main
struct HelsinkiApp: App {
  @State private var player = RadioPlayer()
  @State private var viewModel = NowPlayingViewModel()
  @State private var isLaunching = true

  var body: some Scene {
    WindowGroup {
      TransitionView(
        showFirst: isLaunching,
        animation: .easeInOut(duration: 0.5)
      ) {
        LaunchView()
      } second: {
        ContentView()
      }
      .task {
        await viewModel.load()
        try? await Task.sleep(for: .seconds(1))
        withAnimation { isLaunching = false }
      }
    }
    .environment(player)
    .environment(viewModel)
  }
}
