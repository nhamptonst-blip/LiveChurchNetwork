import SwiftUI

/// Comprehensive design system for Live Church Network
struct DesignSystem {
    // MARK: - Typography

    struct Typography {
        // Heading sizes
        static let heading1 = Font.system(size: 34, weight: .heavy)      // #111827, tracking -0.6
        static let heading2 = Font.system(size: 22, weight: .heavy)
        static let heading3 = Font.system(size: 18, weight: .bold)
        static let heading4 = Font.system(size: 16, weight: .bold)

        // Body text
        static let body = Font.system(size: 16, weight: .regular)
        static let bodyMedium = Font.system(size: 16, weight: .medium)
        static let bodySemibold = Font.system(size: 16, weight: .semibold)

        // Small text
        static let small = Font.system(size: 13, weight: .regular)
        static let smallMedium = Font.system(size: 13, weight: .medium)
        static let smallSemibold = Font.system(size: 13, weight: .semibold)

        // Micro text
        static let micro = Font.system(size: 11, weight: .regular)
        static let microMedium = Font.system(size: 11, weight: .medium)
        static let microBold = Font.system(size: 11, weight: .bold)

        // Caption
        static let caption = Font.system(size: 12, weight: .regular)
        static let captionMedium = Font.system(size: 12, weight: .medium)
    }

    // MARK: - Spacing

    struct Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 20
        static let xxl: CGFloat = 24
        static let xxxl: CGFloat = 32
        static let huge: CGFloat = 40
    }

    // MARK: - Corner Radius

    struct CornerRadius {
        static let small: CGFloat = 8
        static let medium: CGFloat = 12
        static let large: CGFloat = 14
        static let extraLarge: CGFloat = 16
        static let pill: CGFloat = 20
        static let circle: CGFloat = .infinity
    }

    // MARK: - Shadows

    struct Shadows {
        static let small = Shadow(color: Color.black.opacity(0.06), radius: 4, x: 0, y: 2)
        static let medium = Shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 3)
        static let large = Shadow(color: Color.black.opacity(0.10), radius: 12, x: 0, y: 4)
        static let none = Shadow(color: Color.clear, radius: 0, x: 0, y: 0)

        struct Shadow {
            let color: Color
            let radius: CGFloat
            let x: CGFloat
            let y: CGFloat
        }
    }

    // MARK: - Colors

    struct Colors {
        // Primary Brand
        static let primary = Color.lcNavy          // #1F3C88
        static let primaryDark = Color.lcNavyDark  // #162D6A
        static let accent = Color.lcGold           // #F0A500
        static let accentLight = Color.lcGoldLight // #FFF8E7
        static let secondary = Color.lcTeal        // #5B8FA8

        // Neutral
        static let background = Color.lcCream      // #FAF8F5
        static let surface = Color.white
        static let border = Color.lcBorder         // #E2DED8

        // Text
        static let textPrimary = Color.lcText      // #161616
        static let textSecondary = Color.lcText2   // #3E3E48
        static let textTertiary = Color.lcText3    // #80808C

        // Semantic
        static let success = Color.lcTeal
        static let error = Color(red: 239/255, green: 68/255, blue: 68/255)  // #EF4444
        static let warning = Color(red: 245/255, green: 158/255, blue: 11/255) // #F59E0B
        static let info = Color.primary

        // Interactive
        static let link = Color.lcNavy
        static let linkHover = Color.lcNavyDark
    }

    // MARK: - Component Styles

    struct Button {
        static let primaryHeight: CGFloat = 52
        static let secondaryHeight: CGFloat = 44
        static let smallHeight: CGFloat = 28

        static let primaryCornerRadius: CGFloat = CornerRadius.large
        static let pillCornerRadius: CGFloat = CornerRadius.pill

        static let primaryFont = Typography.bodySemibold
        static let secondaryFont = Typography.smallSemibold
    }

    struct Card {
        static let cornerRadius: CGFloat = CornerRadius.large
        static let padding: CGFloat = Spacing.lg
        static let shadow = Shadows.small
    }

    struct TextField {
        static let height: CGFloat = 54
        static let cornerRadius: CGFloat = CornerRadius.extraLarge
        static let borderWidth: CGFloat = 1
        static let borderColor = Colors.border
        static let padding: CGFloat = Spacing.lg
    }

    struct Badge {
        static let height: CGFloat = 20
        static let cornerRadius: CGFloat = CornerRadius.small
        static let font = Typography.microBold
    }

    struct Modal {
        static let cornerRadius: CGFloat = CornerRadius.large
        static let padding: CGFloat = Spacing.lg
        static let maxWidth: CGFloat = 600
    }

    // MARK: - Animation

    struct Animation {
        static let standard = SwiftUI.Animation.easeInOut(duration: 0.3)
        static let quick = SwiftUI.Animation.easeInOut(duration: 0.15)
        static let slow = SwiftUI.Animation.easeInOut(duration: 0.5)
        static let shimmer = SwiftUI.Animation.easeInOut(duration: 1.0).repeatForever(autoreverses: true)
    }

    // MARK: - Dimensions

    struct Dimensions {
        static let tabBarHeight: CGFloat = 78
        static let navigationBarHeight: CGFloat = 56
        static let imageAspectRatio: CGFloat = 16 / 9

        // Card sizes
        static let churchCardHeight: CGFloat = 240
        static let churchCardWidth: CGFloat = 168

        // Avatar sizes
        static let avatarSmall: CGFloat = 32
        static let avatarMedium: CGFloat = 48
        static let avatarLarge: CGFloat = 64
        static let avatarXL: CGFloat = 96
    }
}

// MARK: - View Extensions for Common Styles

extension View {
    // Primary button style
    func primaryButtonStyle() -> some View {
        self
            .font(DesignSystem.Button.primaryFont)
            .frame(height: DesignSystem.Button.primaryHeight)
            .background(DesignSystem.Colors.primary)
            .foregroundColor(.white)
            .cornerRadius(DesignSystem.Button.primaryCornerRadius)
    }

    // Secondary button style
    func secondaryButtonStyle() -> some View {
        self
            .font(DesignSystem.Button.secondaryFont)
            .frame(height: DesignSystem.Button.secondaryHeight)
            .background(Color.white)
            .foregroundColor(DesignSystem.Colors.primary)
            .border(DesignSystem.Colors.border, width: 1)
            .cornerRadius(DesignSystem.Button.primaryCornerRadius)
    }

    // Card style
    func cardStyle() -> some View {
        self
            .padding(DesignSystem.Card.padding)
            .background(DesignSystem.Colors.surface)
            .cornerRadius(DesignSystem.Card.cornerRadius)
            .shadow(color: DesignSystem.Shadows.small.color,
                    radius: DesignSystem.Shadows.small.radius,
                    x: DesignSystem.Shadows.small.x,
                    y: DesignSystem.Shadows.small.y)
    }

    // Section title style
    func sectionTitleStyle() -> some View {
        self
            .font(DesignSystem.Typography.heading2)
            .foregroundColor(DesignSystem.Colors.textPrimary)
    }

    // Heading style
    func headingStyle() -> some View {
        self
            .font(DesignSystem.Typography.heading1)
            .foregroundColor(DesignSystem.Colors.textPrimary)
    }

    // Body text style
    func bodyTextStyle() -> some View {
        self
            .font(DesignSystem.Typography.body)
            .foregroundColor(DesignSystem.Colors.textPrimary)
    }

    // Secondary text style
    func secondaryTextStyle() -> some View {
        self
            .font(DesignSystem.Typography.small)
            .foregroundColor(DesignSystem.Colors.textSecondary)
    }

    // Tertiary text style
    func tertiaryTextStyle() -> some View {
        self
            .font(DesignSystem.Typography.small)
            .foregroundColor(DesignSystem.Colors.textTertiary)
    }
}

// MARK: - Animation Helpers

extension SwiftUI.Animation {
    static let appStandard = DesignSystem.Animation.standard
    static let appQuick = DesignSystem.Animation.quick
    static let appSlow = DesignSystem.Animation.slow
}
