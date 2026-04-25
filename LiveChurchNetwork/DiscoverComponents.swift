import SwiftUI

// MARK: - Shimmer Animation

extension View {
    func shimmer() -> some View {
        modifier(ShimmerModifier())
    }
}

struct ShimmerModifier: ViewModifier {
    @State private var isAnimating = false

    func body(content: Content) -> some View {
        content
            .opacity(isAnimating ? 0.6 : 1.0)
            .onAppear {
                withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                    isAnimating.toggle()
                }
            }
    }
}

// MARK: - Empty State

struct DiscoverEmptyState: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 48, weight: .light))
                .foregroundColor(DesignSystem.Colors.textTertiary)

            Text(title)
                .font(DesignSystem.Typography.heading3)
                .foregroundColor(DesignSystem.Colors.textPrimary)

            Text(subtitle)
                .font(DesignSystem.Typography.small)
                .foregroundColor(DesignSystem.Colors.textTertiary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
}

// MARK: - Church Card Skeleton

struct ChurchDiscoveryCardSkeleton: View {
    @State private var isAnimating = false

    var body: some View {
        VStack(spacing: 0) {
            // Cover image placeholder
            RoundedRectangle(cornerRadius: 0)
                .fill(DesignSystem.Colors.border.opacity(0.5))
                .frame(height: 130)

            // Avatar overlap zone
            ZStack {
                Color.clear.frame(height: 28)
                HStack {
                    Spacer()
                    Circle()
                        .fill(DesignSystem.Colors.border.opacity(0.5))
                        .frame(width: 44, height: 44)
                    Spacer()
                }
            }
            .frame(height: 44)

            // Content placeholders
            VStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(DesignSystem.Colors.border.opacity(0.5))
                    .frame(height: 12)
                    .frame(maxWidth: 120)

                RoundedRectangle(cornerRadius: 4)
                    .fill(DesignSystem.Colors.border.opacity(0.5))
                    .frame(height: 10)
                    .frame(maxWidth: 80)

                Spacer()

                RoundedRectangle(cornerRadius: 8)
                    .fill(DesignSystem.Colors.border.opacity(0.5))
                    .frame(height: 28)
            }
            .padding(.horizontal, 12)
            .padding(.top, 8)
            .padding(.bottom, 12)
        }
        .frame(height: 240)
        .background(DesignSystem.Colors.surface)
        .cornerRadius(DesignSystem.CornerRadius.large)
        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 3)
        .opacity(isAnimating ? 0.6 : 1.0)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
        }
    }
}

// MARK: - People Card Skeleton

struct PeopleDiscoveryCardSkeleton: View {
    @State private var isAnimating = false

    var body: some View {
        VStack(spacing: 0) {
            // Cover image placeholder
            RoundedRectangle(cornerRadius: 0)
                .fill(DesignSystem.Colors.border.opacity(0.5))
                .frame(height: 100)

            // Avatar overlap zone
            ZStack {
                Color.clear.frame(height: 30)
                HStack {
                    Spacer()
                    Circle()
                        .fill(DesignSystem.Colors.border.opacity(0.5))
                        .frame(width: 60, height: 60)
                    Spacer()
                }
            }
            .frame(height: 60)

            // Content placeholders
            VStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(DesignSystem.Colors.border.opacity(0.5))
                    .frame(height: 12)
                    .frame(maxWidth: 120)

                RoundedRectangle(cornerRadius: 4)
                    .fill(DesignSystem.Colors.border.opacity(0.5))
                    .frame(height: 10)
                    .frame(maxWidth: 80)

                Spacer()

                RoundedRectangle(cornerRadius: 8)
                    .fill(DesignSystem.Colors.border.opacity(0.5))
                    .frame(height: 32)
            }
            .padding(.horizontal, 12)
            .padding(.top, 8)
            .padding(.bottom, 12)
        }
        .frame(height: 250)
        .background(DesignSystem.Colors.surface)
        .cornerRadius(DesignSystem.CornerRadius.large)
        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 3)
        .opacity(isAnimating ? 0.6 : 1.0)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
        }
    }
}
