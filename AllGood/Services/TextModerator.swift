//
//  TextModerator.swift
//  AllGood
//
//  Created by Quinn Peterson on 10/1/25.
//

import Foundation

struct TextModerator {
    
    struct ResponseData: Codable {
        let allowed: Bool
    }
    
    static func checkText(_ text: String) async throws -> Bool {
        // build URL
        guard let url = URL(string: Config.apiBaseURL) else {
            throw URLError(.badURL)
        }
        
        // build request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue(Config.apiKey, forHTTPHeaderField: "x-api-key")
        
        // encode JSON body
        let body: [String: String] = ["text": text]
        request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
        
        let decoded = try JSONDecoder().decode(ResponseData.self, from: data)
        return decoded.allowed
    }
}

