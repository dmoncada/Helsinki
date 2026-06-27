import SwiftUI

struct CurrentProgramView: View {
  let title: String?
  let schedule: String?
  let alignment: HorizontalAlignment

  init(title: String?, schedule: String?, alignment: HorizontalAlignment = .center) {
    self.title = title
    self.schedule = schedule
    self.alignment = alignment
  }

  var body: some View {
    VStack(alignment: alignment, spacing: 0) {
      SafeText(title?.uppercased())
        .font(.displayCondensedMedium(.largeTitle))
      SafeText(schedule)
        .font(.panoBold(.title3))
    }
  }
}
