import SwiftUI

struct SafeText: View {
  let text: String?

  init(_ text: String?) {
    self.text = text
  }

  var body: some View {
    Text(text ?? "Unavailable")
      .opacity(text == nil ? 0 : 1)
      .minimumScaleFactor(0.9)
      .scaledToFit()
      .lineLimit(1)
  }
}
