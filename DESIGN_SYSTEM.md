# Live Church Network Design System

Comprehensive design system for consistent UI/UX across the iOS app.

## Table of Contents

1. [Colors](#colors)
2. [Typography](#typography)
3. [Spacing](#spacing)
4. [Components](#components)
5. [Shadows & Elevation](#shadows--elevation)
6. [Corner Radius](#corner-radius)
7. [Animations](#animations)
8. [Best Practices](#best-practices)

---

## Colors

### Brand Colors

```swift
Color.lcNavy         // #1F3C88 - Primary brand color
Color.lcNavyDark     // #162D6A - Dark variant for gradients
Color.lcGold         // #F0A500 - Accent color
Color.lcGoldLight    // #FFF8E7 - Accent tint background
Color.lcTeal         // #5B8FA8 - Secondary accent
```

### Neutral Colors

```swift
Color.lcCream        // #FAF8F5 - App background
Color.white          // #FFFFFF - Card/surface background
Color.lcBorder       // #E2DED8 - Dividers & borders
```

### Text Colors

```swift
Color.lcText         // #161616 - Primary text (high contrast)
Color.lcText2        // #3E3E48 - Secondary text
Color.lcText3        // #80808C - Tertiary/muted text
```

### Using Colors

Always use `DesignSystem.Colors` constants:

```swift
Text("Hello")
    .foregroundColor(DesignSystem.Colors.textPrimary)

VStack {
    // content
}
.background(DesignSystem.Colors.surface)
```

---

## Typography

### Font Sizes & Weights

| Role | Size | Weight | Use Case |
|------|------|--------|----------|
| Heading 1 | 34pt | Heavy | Page titles |
| Heading 2 | 22pt | Heavy | Section titles |
| Heading 3 | 18pt | Bold | Subsections |
| Body | 16pt | Regular | Main text content |
| Body Medium | 16pt | Medium | List items |
| Small | 13pt | Regular | Secondary info |
| Micro | 11pt | Regular | Badges, captions |

### Using Typography

```swift
// Heading
Text("Find a Church")
    .font(DesignSystem.Typography.heading1)

// Body text
Text("Description")
    .font(DesignSystem.Typography.body)

// Or use view extensions for common patterns
Text("Find a Church")
    .headingStyle()
```

### Font Rules

1. Always use system fonts (no custom typefaces)
2. Maintain consistent weights: black, bold, semibold, medium, regular
3. Line spacing: 6pt for subtitles, 4pt for body (use .lineSpacing modifier)
4. Letter spacing: -0.6pt for large headings (use .tracking modifier)

---

## Spacing

### Scale

```swift
xs: 4pt    // Tight spacing
sm: 8pt    // Compact spacing
md: 12pt   // Default/medium
lg: 16pt   // Spacious
xl: 20pt   // Extra spacious
xxl: 24pt  // Large sections
xxxl: 32pt // Hero sections
```

### Usage Patterns

```swift
VStack(spacing: DesignSystem.Spacing.md) {
    // Items spaced 12pt apart
}

HStack(spacing: DesignSystem.Spacing.sm) {
    // Compact horizontal spacing
}

Text("Title")
    .padding(.horizontal, DesignSystem.Spacing.lg)
    .padding(.vertical, DesignSystem.Spacing.md)
```

### Common Paddings

- **Screen edges**: 20pt horizontal
- **Card padding**: 12-16pt
- **Section padding**: 20pt
- **Button padding**: 12pt horizontal, 10pt vertical (pills)

---

## Components

### Buttons

#### Primary Button (52pt height)

```swift
Button(action: {}) {
    Text("Get Started")
        .primaryButtonStyle()
}
```

- Background: Navy (#1F3C88)
- Text: White, 16pt Semibold
- Corner radius: 14pt
- Height: 52pt
- Padding: 16pt horizontal

#### Secondary Button (44pt height)

```swift
Button(action: {}) {
    Text("Cancel")
        .secondaryButtonStyle()
}
```

- Background: White
- Border: 1pt, #E2DED8
- Text: Navy, 13pt Semibold
- Corner radius: 14pt

#### Pill Buttons (28pt height)

For filter chips and toggles:

```swift
Button(action: {}) {
    HStack(spacing: 8) {
        Image(systemName: "location.fill")
        Text("Near Me")
    }
}
.padding(.horizontal, 14)
.padding(.vertical, 10)
.background(isActive ? Color.lcNavy : Color.white)
.foregroundColor(isActive ? .white : Color.lcNavy)
.cornerRadius(20)
```

- Height: 28-32pt
- Corner radius: 20pt (pill shape)
- Padding: 14pt horizontal, 10pt vertical
- Font: 14pt Semibold

### Cards

```swift
VStack(alignment: .leading, spacing: 12) {
    // Content
}
.cardStyle()
```

- Background: White
- Corner radius: 14pt
- Padding: 16pt
- Shadow: Small (opacity 0.06, 4pt radius)
- Border: None (use shadow for elevation)

### Text Fields

```swift
TextField("Search churches...", text: $query)
    .frame(height: DesignSystem.TextField.height)
    .padding(.horizontal, DesignSystem.TextField.padding)
    .background(Color.white)
    .border(DesignSystem.Colors.border, width: 1)
    .cornerRadius(DesignSystem.TextField.cornerRadius)
```

- Height: 54pt
- Corner radius: 18pt
- Border: 1pt, #E2DED8
- Padding: 16pt horizontal
- Font: 16pt Regular

### Badges

For status indicators (Live, Trending, New):

```swift
Text("LIVE")
    .font(DesignSystem.Typography.microBold)
    .foregroundColor(.white)
    .padding(.horizontal, 8)
    .padding(.vertical, 6)
    .background(Color.red.opacity(0.9))
    .cornerRadius(12)
```

- Font: 11pt Bold
- Padding: 8pt horizontal, 6pt vertical
- Corner radius: 12pt
- Common backgrounds: Red (#EF4444) for live, Orange for trending

---

## Shadows & Elevation

### Shadow Levels

```swift
// Small - Subtle depth
.shadow(color: Color.black.opacity(0.06), radius: 4, x: 0, y: 2)

// Medium - Standard elevation
.shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 3)

// Large - Strong elevation
.shadow(color: Color.black.opacity(0.10), radius: 12, x: 0, y: 4)
```

Or use the design system:

```swift
.shadow(color: DesignSystem.Shadows.small.color,
        radius: DesignSystem.Shadows.small.radius,
        x: DesignSystem.Shadows.small.x,
        y: DesignSystem.Shadows.small.y)
```

### Elevation Rules

- **Cards**: Small shadow (subtle depth)
- **Floating buttons**: Medium shadow
- **Modals**: Large shadow (strong separation)
- **List items**: No shadow (use borders or colors)

---

## Corner Radius

### Standard Sizes

```swift
small: 8pt           // Form inputs, small components
medium: 12pt         // List items, smaller cards
large: 14pt          // Primary cards, buttons
extraLarge: 16pt     // Large cards, modals
pill: 20pt           // Pill buttons, badges
```

### Usage

```swift
// Use constants, not magic numbers
.cornerRadius(DesignSystem.CornerRadius.large)

// Common pattern
VStack()
    .cornerRadius(DesignSystem.CornerRadius.large)
    .shadow(...)
```

---

## Animations

### Standard Animations

```swift
// Default: 0.3s ease-in-out
.animation(.appStandard, value: isActive)

// Quick: 0.15s (interactions)
.animation(.appQuick, value: isTapped)

// Slow: 0.5s (emphasis)
.animation(.appSlow, value: heroAnimation)

// Shimmer: 1.0s repeating
.shimmer()
```

### Animation Rules

- **Transitions**: Use `.appStandard`
- **Button interactions**: Use `.appQuick`
- **Hero animations**: Use `.appSlow`
- **Loading states**: Use `.shimmer()`
- **Tab switches**: Use `.appStandard`

---

## Best Practices

### 1. Always Use Design System Constants

❌ **Bad**
```swift
.padding(.horizontal, 20)
.font(.system(size: 22, weight: .heavy))
.cornerRadius(14)
.background(Color(red: 31/255, green: 60/255, blue: 136/255))
```

✅ **Good**
```swift
.padding(.horizontal, DesignSystem.Spacing.xl)
.font(DesignSystem.Typography.heading2)
.cornerRadius(DesignSystem.CornerRadius.large)
.background(DesignSystem.Colors.primary)
```

### 2. Use View Extensions for Common Patterns

❌ **Bad**
```swift
Text("Title")
    .font(.system(size: 34, weight: .heavy))
    .foregroundColor(Color.lcText)
```

✅ **Good**
```swift
Text("Title")
    .headingStyle()
```

### 3. Consistent Color Usage

- **Text**: Always use text hierarchy (primary/secondary/tertiary)
- **Backgrounds**: Use `.lcCream` for page bg, `.white` for surfaces
- **Accents**: Use `.lcNavy` for primary actions, `.lcGold` for highlights
- **Borders**: Always use `.lcBorder`

### 4. Spacing Rules

- **Screen edges**: 20pt padding
- **Between sections**: 20pt or 24pt
- **Within cards**: 12pt
- **Between form elements**: 12pt
- **Tight spacing**: 8pt (in lists, pills)

### 5. Hierarchy & Contrast

- Ensure 4.5:1 contrast ratio for text (WCAG AA)
- Use text hierarchy for readability
- Primary text: #161616
- Secondary text: #3E3E48
- Tertiary text: #80808C (max for body, min for labels)

### 6. Component Consistency

- All cards: same corner radius, shadow, padding
- All buttons: same height, spacing, font
- All badges: same styling regardless of purpose
- All sections: same title styling

### 7. Safe Areas

- Always use `.ignoresSafeArea()` only when needed (full background)
- Respect safe area for interactive elements
- Check both portrait and landscape

### 8. Responsive Design

- Use `frame(maxWidth: .infinity)` for full-width elements
- Padding adapts, font sizes stay consistent
- Test on iPhone 13-15 sizes (compact to regular)

---

## Example: Complete Component

```swift
VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
    // Header
    Text("Find a Church")
        .headingStyle()
    
    Text("Discover churches and communities")
        .secondaryTextStyle()
        .padding(.bottom, DesignSystem.Spacing.md)
    
    // Search field
    HStack(spacing: 12) {
        Image(systemName: "magnifyingglass")
            .foregroundColor(DesignSystem.Colors.textTertiary)
        
        TextField("Search...", text: $query)
            .font(DesignSystem.Typography.body)
    }
    .padding(.horizontal, DesignSystem.TextField.padding)
    .frame(height: DesignSystem.TextField.height)
    .background(DesignSystem.Colors.surface)
    .border(DesignSystem.Colors.border, width: 1)
    .cornerRadius(DesignSystem.TextField.cornerRadius)
    
    // CTA Button
    Button(action: {}) {
        Text("Explore")
            .primaryButtonStyle()
    }
}
.padding(DesignSystem.Spacing.xl)
.background(DesignSystem.Colors.background)
```

---

## Accessibility

- Use font sizes >= 12pt for body text
- Maintain 4.5:1 contrast for text
- Support Dynamic Type with `.font()` modifier
- Provide meaningful image descriptions
- Use `accessibilityLabel` for icons
- Support dark mode (system appearance)

---

## For Questions

Refer to:
- `DesignSystem.swift` - All design tokens & extensions
- `BrandColors.swift` - Color definitions
- `PerformanceConfig.swift` - Component sizing guides
- This file - Comprehensive guidelines
