import Foundation

@MainActor
@Observable
final class NowPlayingViewModel {
  private let service = NowPlayingService()

  private(set) var program: Program?
  private(set) var songs: [Song] = []

  var programTitle: String? {
    program?.title
  }

  var programSchedule: String? {
    program?.schedule
  }

  var songArtist: String? {
    songs.first?.artist
  }

  var songTitle: String? {
    songs.first?.song
  }

  func poll(interval: Duration = .seconds(20)) async {
    while Task.isCancelled == false {
      try? await Task.sleep(for: interval)
      await load()
    }
  }

  func load() async {
    let response = await service.fetch()
    program = response?.programs?.current
    songs = response?.lastPlaying ?? []
  }
}

extension Program {
  var schedule: String? {
    guard
      let begin = Self.time(from: begin),
      let end = Self.time(from: end)
    else { return nil }

    return "\(begin)-\(end)"
  }

  fileprivate static func time(from raw: String?) -> String? {
    guard
      let raw,
      let date = try? Date(raw, strategy: parseStrategy)
    else { return nil }

    return date.formatted(
      Date.FormatStyle(locale: .init(identifier: "fi_FI"), timeZone: .gmt)
        .hour(.twoDigits(amPM: .omitted))
        .minute(.twoDigits)
    )
  }

  fileprivate static let parseStrategy = Date.ParseStrategy(
    format: """
      \(year: .defaultDigits)-\(month: .twoDigits)-\(day: .twoDigits) \
      \(hour: .twoDigits(clock: .twentyFourHour, hourCycle: .zeroBased)):\
      \(minute: .twoDigits):\(second: .twoDigits)
      """,
    locale: .init(identifier: "en_US_POSIX"),
    timeZone: .gmt
  )
}
