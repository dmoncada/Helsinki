struct Song: Decodable, Identifiable {
  let id: String?
  let artist: String?
  let song: String?
  let album: String?
  let length: String?
  let start: Int?

  enum CodingKeys: String, CodingKey {
    case id, artist, song, album, length
    case start = "_start"
  }
}
