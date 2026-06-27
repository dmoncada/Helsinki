import SwiftUI

struct RadioHelsinkiLogo: View {
  var cycleInterval: Duration = .seconds(2)

  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  @State private var station: RadioHelsinkiStation = .helsinki
  @State private var size: CGSize = .zero

  private let aspectRatio: CGFloat = 837.0 / 208.0

  var body: some View {
    ZStack {
      Image(.Logo.logoBase)
        .resizable()
        .scaledToFit()

      CityBand(
        station: station,
        canvasHeight: size.height,
        reduceMotion: reduceMotion
      )
    }
    .aspectRatio(aspectRatio, contentMode: .fit)
    .onGeometryChange(for: CGSize.self) { proxy in
      proxy.size
    } action: { newSize in
      size = newSize
    }
    .accessibilityElement()
    .accessibilityLabel("Radio Helsinki, \(station.name)")
    .task {
      while Task.isCancelled == false {
        try? await Task.sleep(for: cycleInterval)
        withAnimation(.easeInOut(duration: 0.4)) {
          station = station.next
        }
      }
    }
  }
}

private struct CityBand: View {
  let station: RadioHelsinkiStation
  let canvasHeight: CGFloat
  let reduceMotion: Bool

  // Band geometry as fractions of the 837×208 canvas (from the SVG mask).
  private let bandTopFraction: CGFloat = 132.0 / 208.0
  private let bandHeightFraction: CGFloat = 75.5 / 208.0
  private let slideFraction: CGFloat = 80.0 / 208.0

  var body: some View {
    ZStack(alignment: .top) {
      Image(station.image)
        .resizable()
        .scaledToFit()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .transition(transition)
        .id(station)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .mask(alignment: .top) {
      Rectangle()
        .frame(height: canvasHeight * bandHeightFraction)
        .padding(.top, canvasHeight * bandTopFraction)
    }
  }

  private var transition: AnyTransition {
    if reduceMotion { return .opacity }
    let slide = canvasHeight * slideFraction
    return .asymmetric(
      insertion: .offset(y: -slide).combined(with: .opacity),
      removal: .offset(y: slide).combined(with: .opacity)
    )
  }
}

#Preview {
  RadioHelsinkiLogo()
    .foregroundStyle(.primary)
    .frame(width: 320)
    .padding()
}
