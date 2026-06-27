struct Program: Decodable {
  let title: String?
  let hosts: [Host]?
  let begin: String?
  let end: String?

  enum CodingKeys: String, CodingKey {
    case title = "program_title"
    case hosts = "program_hosts"
    case begin
    case end
  }
}
