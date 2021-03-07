//
//  CombosableArchitectureApp.swift
//  CombosableArchitecture
//
//  Created by 이광용 on 2020/09/21.
//

import SwiftUI
import Core

@main
struct CombosableArchitectureApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView(
                store: Store(
                    initialValue: AppState(),
                    reducer: logging(activityFeed(appReducer)),
                    environment: .live
                )
            )
        }
    }
}
