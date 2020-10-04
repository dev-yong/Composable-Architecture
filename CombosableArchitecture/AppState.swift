//
//  AppState.swift
//  CombosableArchitecture
//
//  Created by 이광용 on 2020/09/21.
//

import SwiftUI

struct AppState {
    
   var count = 0
   var favoritePrimes: [Int] = []
   var loggedInUser: User?
   var activityFeed: [Activity] = []
}

struct User {
    
    let id: Int
    let name: String
    let bio: String
}

struct Activity {
  let timestamp: Date
  let type: ActivityType

  enum ActivityType {
    case addedFavoritePrime(Int)
    case removedFavoritePrime(Int)
  }
}
