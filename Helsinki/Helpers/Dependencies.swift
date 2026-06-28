import SwiftUI

struct Dependencies: PreviewModifier {
  @State private var player = RadioPlayer()
  @State private var viewModel = NowPlayingViewModel()

  func body(content: Content, context: Void) -> some View {
    content
      .task {
        await viewModel.poll(interval: .seconds(3600))
      }
      .environment(player)
      .environment(viewModel)
  }
}
