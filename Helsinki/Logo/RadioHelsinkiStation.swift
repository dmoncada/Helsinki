import SwiftUI

/// The Radio Helsinki regional stations, in the order the brand logo cycles
/// through them. Each maps to a vector asset that shares the logo's full
/// 837×208 canvas so it overlays the static base perfectly.
enum RadioHelsinkiStation: Int, CaseIterable, Identifiable {
  case helsinki, oulu, turku, tampere, pori, jyvaskyla, lahti, joensuu, kuopio

  var id: Int { rawValue }

  var image: ImageResource {
    switch self {
    case .helsinki: .Logo.stationHelsinki
    case .oulu: .Logo.stationOulu
    case .turku: .Logo.stationTurku
    case .tampere: .Logo.stationTampere
    case .pori: .Logo.stationPori
    case .jyvaskyla: .Logo.stationJyvaskyla
    case .lahti: .Logo.stationLahti
    case .joensuu: .Logo.stationJoensuu
    case .kuopio: .Logo.stationKuopio
    }
  }

  var name: String {
    switch self {
    case .helsinki: "Helsinki"
    case .oulu: "Oulu"
    case .turku: "Turku"
    case .tampere: "Tampere"
    case .pori: "Pori"
    case .jyvaskyla: "Jyväskylä"
    case .lahti: "Lahti"
    case .joensuu: "Joensuu"
    case .kuopio: "Kuopio"
    }
  }

  var next: RadioHelsinkiStation {
    RadioHelsinkiStation(rawValue: (rawValue + 1) % Self.allCases.count) ?? .helsinki
  }
}
