import os

extension Logger {
  enum Helsinki {
    struct Category: RawRepresentable, Hashable {
      let rawValue: String
    }
  }

  private enum Constants {
    static let subsystem = "com.dmoncada.Helsinki"
  }

  init(category: Helsinki.Category) {
    self.init(subsystem: Constants.subsystem, category: category.rawValue)
  }
}
