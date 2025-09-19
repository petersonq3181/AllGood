//
//  ColorTheme.swift
//  AllGood
//
//  Created by Quinn Peterson on 9/19/25.
//

import SwiftUI

protocol ColorThemeProtocol {
    var primary: Color { get }
    var secondary: Color { get }
    var tertiary: Color { get }
    var quaternary: Color { get }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)

        let r, g, b, a: UInt64
        switch hex.count {
        case 6: // RGB (no alpha)
            (r, g, b, a) = (int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF, 255)
        case 8: // RGBA
            (r, g, b, a) = (int >> 24 & 0xFF, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (r, g, b, a) = (1, 1, 1, 1)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

struct ColorThemeA: ColorThemeProtocol {
    var primary: Color = Color(hex: "#D00000")
    var secondary: Color = Color(hex: "#1B282E")
    var tertiary: Color = Color(hex: "#3F88C5")
    var quaternary: Color = Color(hex: "#576F76")
}

private struct ColorThemeKey: EnvironmentKey {
    static let defaultValue: ColorThemeProtocol = ColorThemeA()
}

extension EnvironmentValues {
    var colorTheme: ColorThemeProtocol {
        get { self[ColorThemeKey.self] }
        set { self[ColorThemeKey.self] = newValue }
    }
}

