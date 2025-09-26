//
//  AllGoodApp.swift
//  AllGood
//
//  Created by Quinn Peterson on 9/8/25.
//

import SwiftUI
import FirebaseCore
import FirebaseFirestore

@main
struct AllGoodApp: App {
    init() {
        if isRunningTests {
            // load the test plist
            if let filePath = Bundle.main.path(forResource: "GoogleService-Info-Test", ofType: "plist"),
               let options = FirebaseOptions(contentsOfFile: filePath) {
                FirebaseApp.configure(name: "test", options: options)
            }
        } else {
            // default prod config (GoogleService-Info.plist)
            FirebaseApp.configure()
        }
    }

    @StateObject private var authViewModel = AuthenticationViewModel()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(authViewModel)
        }
    }
}

var isRunningTests: Bool {
    return NSClassFromString("XCTestCase") != nil
}
