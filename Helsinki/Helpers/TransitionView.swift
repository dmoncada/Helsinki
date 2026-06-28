import SwiftUI

struct TransitionView<Content1: View, Content2: View>: View {
  let showFirst: Bool
  let animation: Animation

  @ViewBuilder let first: () -> Content1
  @ViewBuilder let second: () -> Content2

  var body: some View {
    Group {
      if showFirst {
        first().transition(.opacity)
      } else {
        second().transition(.opacity)
      }
    }
    .animation(animation, value: showFirst)
  }
}
