//
//  WolframAlphaHelper.swift
//  CombosableArchitecture
//
//  Created by 이광용 on 2020/09/21.
//

import Foundation
import Core

private struct WolframAlphaResult: Decodable {
  let queryresult: QueryResult

  struct QueryResult: Decodable {
    let pods: [Pod]

    struct Pod: Decodable {
      let primary: Bool?
      let subpods: [SubPod]

      struct SubPod: Decodable {
        let plaintext: String
      }
    }
  }
}

private func wolframAlpha(query: String) -> Effect<WolframAlphaResult?> {
    return Effect { callback in
        var components = URLComponents(string: "https://api.wolframalpha.com/v2/query")!
        components.queryItems = [
          URLQueryItem(name: "input", value: query),
          URLQueryItem(name: "format", value: "plaintext"),
          URLQueryItem(name: "output", value: "JSON"),
          URLQueryItem(name: "appid", value: "6H69Q3-828TKQJ4EP"),
        ]

        URLSession.shared.dataTask(with: components.url(relativeTo: nil)!) { data, response, error in
          callback(
            data
              .flatMap { try? JSONDecoder().decode(WolframAlphaResult.self, from: $0) }
          )
        }
        .resume()
    }
}

public func nthPrime(_ n: Int) -> Effect<Int?> {
    wolframAlpha(query: "prime \(n)")
        .map { result in
            result
                .flatMap {
                    $0.queryresult
                        .pods
                        .first(where: { $0.primary == true })?
                        .subpods
                        .first?
                        .plaintext
                }
                .flatMap(Int.init)
        }
}

//return [
//  Effect { callback in
//    nthPrime(n) { prime in
//      DispatchQueue.main.async {
//        callback(.nthPrimeResponse(prime))
//      }
//    }
//  }
//]
