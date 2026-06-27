import SwiftUI

struct TopBarModifier: ViewModifier {
  func body(content: Content) -> some View {
    content
      .safeAreaBar(edge: .top, alignment: .leading) {
        RadioHelsinkiLogo()
          .foregroundStyle(.primary)
          .frame(maxWidth: 160)
          .padding()
      }
  }
}

extension View {
  func withHelsinkiTopBar() -> some View {
    modifier(TopBarModifier())
  }
}
