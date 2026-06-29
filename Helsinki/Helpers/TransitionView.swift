import SwiftUI

struct TransitionView<Content1: View, Content2: View, T: Transition>: View {
  let showFirst: Bool
  let animation: Animation
  let transition: T

  @ViewBuilder let first: () -> Content1
  @ViewBuilder let second: () -> Content2

  init(
    showFirst: Bool,
    animation: Animation,
    transition: T = .opacity,
    @ViewBuilder first: @escaping () -> Content1,
    @ViewBuilder second: @escaping () -> Content2
  ) {
    self.showFirst = showFirst
    self.animation = animation
    self.transition = transition
    self.first = first
    self.second = second
  }

  var body: some View {
    Group {
      if showFirst {
        first().transition(transition)
      } else {
        second().transition(transition)
      }
    }
    .animation(animation, value: showFirst)
  }
}

#if DEBUG
  private struct BackgroundWrapper<Background: ShapeStyle>: ViewModifier {
    let background: Background

    func body(content: Content) -> some View {
      ZStack {
        Rectangle()
          .fill(background)
          .ignoresSafeArea()

        content
      }
    }
  }

  extension View {
    fileprivate func withBackground<Background: ShapeStyle>(
      _ background: Background
    ) -> some View {
      modifier(BackgroundWrapper(background: background))
    }
  }

  #Preview {
    @Previewable @State var showFirst = true

    TransitionView(
      showFirst: showFirst,
      animation: .easeInOut
    ) {
      Text("First")
        .withBackground(.red)
    } second: {
      Text("Second")
        .withBackground(.blue)
    }
    .task {
      while Task.isCancelled == false {
        try? await Task.sleep(for: .seconds(3))
        withAnimation {
          showFirst.toggle()
        }
      }
    }
  }
#endif
