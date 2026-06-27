import Foundation
import os

extension Logger.Helsinki.Category {
  fileprivate static let nowPlayingService = Self(rawValue: "nowPlaying")
}

final class NowPlayingService {
  private let logger = Logger(category: .nowPlayingService)

  private let userAgent =
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1 (KHTML, like Gecko) Version/17 Safari/605.1"

  func fetch() async -> NowPlayingResponse? {
    guard let endpoint = Constants.nowPlayingApi
    else { return nil }

    var request = URLRequest(url: endpoint)
    request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
    request.timeoutInterval = 10

    do {
      let (data, response) = try await URLSession.shared.data(for: request)
      if let httpResponse = response as? HTTPURLResponse {
        logger.log("Status code: \(httpResponse.statusCode)")
      }

      return try JSONDecoder().decode(NowPlayingResponse.self, from: data)

    } catch {
      if let urlError = error as? URLError {
        logger.error("Error code: \(urlError.errorCode)")
      } else {
        logger.error("Error: \(error)")
      }
      return nil
    }
  }
}
