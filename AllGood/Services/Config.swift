//
//  Config.swift
//  AllGood
//
//  Created by Quinn Peterson on 10/1/25.
//

import Foundation

struct Config {
    static var apiBaseURL: String {
        getValue(for: "FIREBASE_FUNCTION_URL")
    }

    static var apiKey: String {
        getValue(for: "FIREBASE_FUNCTION_API_KEY")
    }

    private static func getValue(for key: String) -> String {
        guard let path = Bundle.main.path(forResource: "Config", ofType: "plist"),
              let dict = NSDictionary(contentsOfFile: path),
              let value = dict[key] as? String else {
            fatalError("Missing key: \(key)")
        }
        return value
    }
}
