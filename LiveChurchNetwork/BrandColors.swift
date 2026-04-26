import SwiftUI
import UIKit

extension Color {
    // Brand
    static let lcNavy      = Color(red: 31/255,  green: 60/255,  blue: 136/255)
    static let lcNavyDark  = Color(red: 22/255,  green: 45/255,  blue: 106/255)
    static let lcGold      = Color(red: 240/255, green: 165/255, blue: 0/255)
    static let lcGoldLight = Color(red: 255/255, green: 248/255, blue: 231/255)
    static let lcTeal      = Color(red: 91/255,  green: 143/255, blue: 168/255)

    // Backgrounds
    static let lcCream     = Color(red: 250/255, green: 249/255, blue: 246/255)

    // Typography — pure charcoal hierarchy for strong contrast
    static let lcText      = Color(red: 22/255,  green: 22/255,  blue: 22/255)   // #161616 near-black
    static let lcText2     = Color(red: 62/255,  green: 62/255,  blue: 72/255)   // #3E3E48 dark gray
    static let lcText3     = Color(red: 128/255, green: 128/255, blue: 140/255)  // #80808C medium gray

    // Borders
    static let lcBorder    = Color(red: 226/255, green: 222/255, blue: 216/255)
}

// MARK: - UIColor equivalents for UIKit appearance APIs

extension UIColor {
    static let lcNavy     = UIColor(red: 31/255,  green: 60/255,  blue: 136/255, alpha: 1)
    static let lcGold     = UIColor(red: 240/255, green: 165/255, blue: 0/255,   alpha: 1)
    static let lcText     = UIColor(red: 22/255,  green: 22/255,  blue: 22/255,  alpha: 1)
    static let lcText3    = UIColor(red: 128/255, green: 128/255, blue: 140/255, alpha: 1)
}
