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

// MARK: - Design System: Typography

enum Typography {
    static let screenTitleSize: CGFloat = 34
    static let screenTitleWeight: Font.Weight = .black

    static let sectionTitleSize: CGFloat = 22
    static let sectionTitleWeight: Font.Weight = .black

    static let cardTitleSize: CGFloat = 16
    static let cardTitleWeight: Font.Weight = .black

    static let bodySize: CGFloat = 15
    static let bodyWeight: Font.Weight = .medium

    static let metaSize: CGFloat = 13
    static let metaWeight: Font.Weight = .medium

    static let buttonSize: CGFloat = 14
    static let buttonWeight: Font.Weight = .black
}

// MARK: - Design System: Spacing

enum Spacing {
    static let screenPadding: CGFloat = 20
    static let sectionTop: CGFloat = 32
    static let sectionGap: CGFloat = 12
    static let gridGap: CGFloat = 14
    static let cardRowGap: CGFloat = 18
}

// MARK: - Design System: Radius

enum CornerRadius {
    static let button: CGFloat = 16
    static let card: CGFloat = 22
    static let pill: CGFloat = 999
}

// MARK: - Design System: Shadows

enum ShadowStyle {
    static let subtle = (color: Color(red: 17/255, green: 24/255, blue: 39/255).opacity(0.05), radius: 8, x: CGFloat(0), y: CGFloat(2))
    static let prominent = (color: Color(red: 17/255, green: 24/255, blue: 39/255).opacity(0.10), radius: 12, x: CGFloat(0), y: CGFloat(2))
}
