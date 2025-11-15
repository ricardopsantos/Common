import SwiftUI

public extension Color {
    /// Generates a random color with full opacity.
    /// Ensures the result is not too dark or too bright.
    static var random: Color {
        let red = Double.random(in: 0.1 ... 0.9)
        let green = Double.random(in: 0.1 ... 0.9)
        let blue = Double.random(in: 0.1 ... 0.9)

        return Color(red: red, green: green, blue: blue)
    }
}
