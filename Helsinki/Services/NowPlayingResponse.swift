struct NowPlayingResponse: Decodable {
  let programs: Programs?
  let lastPlaying: [Song]?

  enum CodingKeys: String, CodingKey {
    case programs
    case lastPlaying = "last_playing"
  }
}

extension NowPlayingResponse {
  struct Programs: Decodable {
    let current: Program?
  }
}

extension NowPlayingResponse {
  init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)

    programs =
      try container
      .decodeIfPresent(Programs.self, forKey: .programs)

    lastPlaying = try container
      .decodeIfPresent([MaybeSong].self, forKey: .lastPlaying)?
      .compactMap(\.value)
  }

  // The Radio Helsinki API can sometimes return invalid
  // items in the list of songs. Decode safely.
  private struct MaybeSong: Decodable {
    let value: Song?

    init(from decoder: any Decoder) throws {
      value = try? Song(from: decoder)
    }
  }
}
