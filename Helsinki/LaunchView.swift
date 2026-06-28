import SwiftUI

struct LaunchView: View {
  var body: some View {
    ZStack {
      Color
        .splash
        .ignoresSafeArea()

      Image(.Logo.logo)
        .resizable()
        .scaledToFit()
        .frame(width: 300)
        .foregroundStyle(.black)
    }
  }
}

#Preview {
  LaunchView()
}
