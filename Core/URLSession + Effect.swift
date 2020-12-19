//
//  URLSession + Effect.swift
//  Core
//
//  Created by 이광용 on 2020/12/19.
//

import Foundation
import Combine

public typealias DataTaskResopnse = (Data?, URLResponse?, Error?)

extension URLSession {
    
    public func dataTask(request: URL) -> Effect<DataTaskResopnse> {
      return Effect { callback in
        self.dataTask(with: request) { data, response, error in
          callback((data, response, error))
        }.resume()
      }
    }

}

extension Effect where A == DataTaskResopnse {
    
    public func decode<B: Decodable, D: TopLevelDecoder>(
        as type: B.Type,
        using decoder: D
    ) -> Effect<B?> where D.Input == Data {
    return self.map { data, _, _ in
      data
        .flatMap { try? decoder.decode(B.self, from: $0) }
    }
  }
    
}
