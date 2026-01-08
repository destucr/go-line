import SwiftUI
import UIKit

struct MetroTheme {
    
    // MARK: - Color Palette (Light Mode / Swiss Style)
    
    // Backgrounds: Clean, Paper-like
    static let mainBackground = Color(red: 0.96, green: 0.96, blue: 0.94) // Off-white
    static let cardBackground = Color.white
    
    // Ink: High Contrast
    static let inkBlack = Color(red: 0.05, green: 0.05, blue: 0.05) // Near Black
    static let inkGray = Color(red: 0.4, green: 0.4, blue: 0.4) // Secondary Text
    
    // Functional Signals (High Saturation)
    static let safetyYellow = Color(red: 1.0, green: 0.8, blue: 0.0) // Attention
    static let alertRed = Color(red: 0.85, green: 0.25, blue: 0.2) // Critical
    static let goGreen = Color(red: 0.0, green: 0.65, blue: 0.4) // Good
    static let electricBlue = Color(red: 0.0, green: 0.35, blue: 0.85) // Info/Active
    
    // UIKit Equivalents
    static let uiBackground = UIColor(red: 0.96, green: 0.96, blue: 0.94, alpha: 1.0)
    static let uiInkBlack = UIColor(red: 0.05, green: 0.05, blue: 0.05, alpha: 1.0)
    static let uiSafetyYellow = UIColor(red: 1.0, green: 0.8, blue: 0.0, alpha: 1.0)
    
    // MARK: - Typography
    // Swiss Style: Helvetica-ish, Tight spacing
    
    static func titleFont(size: CGFloat) -> Font {
        return .system(size: size, weight: .black, design: .default)
    }
    
    static func signageFont(size: CGFloat) -> Font {
        return .system(size: size, weight: .bold, design: .default) // Changed from rounded to default for sharper Swiss look
    }
    
    static func dataFont(size: CGFloat) -> Font {
        return .system(size: size, weight: .bold, design: .monospaced)
    }
    
    // MARK: - Layout Constants
    static let cornerRadius: CGFloat = 0.0 // Square corners for "Ticket/Sign" feel
    static let strokeWidth: CGFloat = 3.0
}

// MARK: - View Modifiers

struct MetroCardStyle: ViewModifier {
    var borderColor: Color = MetroTheme.inkBlack
    
    func body(content: Content) -> some View {
        content
            .padding()
            .background(MetroTheme.cardBackground)
            .border(borderColor, width: MetroTheme.strokeWidth)
            .compositingGroup() // Force flattening before shadow
            .shadow(color: .black.opacity(0.1), radius: 0, x: 4, y: 4) // Hard shadow
    }
}

extension View {
    func metroCardStyle(borderColor: Color = MetroTheme.inkBlack) -> some View {
        self.modifier(MetroCardStyle(borderColor: borderColor))
    }
}
