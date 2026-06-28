import SwiftUI

struct CurrentProgramView: View {
  let program: Program?

  init(_ program: Program?) {
    self.program = program
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      SafeText(program?.title?.uppercased())
        .font(.displayCondensedMedium(.largeTitle))
      SafeText(program?.schedule)
        .font(.panoBold(.title3))
    }
  }
}
