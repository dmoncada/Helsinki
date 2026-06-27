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
