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

// MARK: - Empty State Action

struct DiscoverEmptyStateAction {
    let label: String
    let action: () -> Void
}

// MARK: - Empty State

struct DiscoverEmptyState: View {
    let icon: String
    let title: String
    let subtitle: String
    var actions: [DiscoverEmptyStateAction] = []

    var body: some View {
        VStack(spacing: 16) {
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

            if !actions.isEmpty {
                VStack(spacing: 10) {
                    ForEach(0..<actions.count, id: \.self) { index in
                        Button(action: actions[index].action) {
                            Text(actions[index].label)
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(Color(red: 31/255, green: 60/255, blue: 136/255))
                                .frame(maxWidth: 260)
                                .frame(height: 38)
                                .background(Color.white)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color(red: 31/255, green: 60/255, blue: 136/255), lineWidth: 1)
                                )
                        }
                    }
                }
                .padding(.horizontal, 32)
            }
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

// MARK: - Directory Church Card Skeleton

struct DirectoryChurchCardSkeleton: View {
    @State private var isAnimating = false

    var body: some View {
        VStack(spacing: 0) {
            // Cover image placeholder
            RoundedRectangle(cornerRadius: 0)
                .fill(DesignSystem.Colors.border.opacity(0.5))
                .frame(height: 112)

            // Logo overlap zone
            ZStack {
                Color.clear.frame(height: 22)
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
            VStack(alignment: .leading, spacing: 8) {
                Spacer()
                    .frame(height: 4)

                RoundedRectangle(cornerRadius: 4)
                    .fill(DesignSystem.Colors.border.opacity(0.5))
                    .frame(height: 12)
                    .frame(maxWidth: 140)

                RoundedRectangle(cornerRadius: 4)
                    .fill(DesignSystem.Colors.border.opacity(0.5))
                    .frame(height: 10)
                    .frame(maxWidth: 100)

                RoundedRectangle(cornerRadius: 4)
                    .fill(DesignSystem.Colors.border.opacity(0.5))
                    .frame(height: 9)
                    .frame(maxWidth: 80)

                Spacer()

                RoundedRectangle(cornerRadius: 999)
                    .fill(DesignSystem.Colors.border.opacity(0.5))
                    .frame(height: 32)
            }
            .padding(.horizontal, 12)
            .padding(.top, 0)
            .padding(.bottom, 12)
        }
        .frame(minHeight: 230)
        .background(DesignSystem.Colors.surface)
        .cornerRadius(22)
        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 3)
        .opacity(isAnimating ? 0.6 : 1.0)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
        }
    }
}

// MARK: - People Social Card Skeleton

struct PeopleSocialCardSkeleton: View {
    @State private var isAnimating = false

    var body: some View {
        HStack(spacing: 12) {
            // Avatar — 64pt circle
            Circle()
                .fill(DesignSystem.Colors.border.opacity(0.5))
                .frame(width: 64, height: 64)

            // Content area
            VStack(alignment: .leading, spacing: 4) {
                // Name bar
                RoundedRectangle(cornerRadius: 4)
                    .fill(DesignSystem.Colors.border.opacity(0.5))
                    .frame(height: 14)
                    .frame(maxWidth: 120)

                // Church/denomination bar
                RoundedRectangle(cornerRadius: 4)
                    .fill(DesignSystem.Colors.border.opacity(0.5))
                    .frame(height: 11)
                    .frame(maxWidth: 90)

                // Bio bar
                RoundedRectangle(cornerRadius: 4)
                    .fill(DesignSystem.Colors.border.opacity(0.5))
                    .frame(height: 11)
                    .frame(maxWidth: 160)

                Spacer()
            }

            // Button placeholder — 72pt wide
            RoundedRectangle(cornerRadius: 8)
                .fill(DesignSystem.Colors.border.opacity(0.5))
                .frame(width: 72, height: 34)

            Spacer()
        }
        .frame(minHeight: 100)
        .padding(14)
        .background(Color.white)
        .cornerRadius(22)
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .stroke(Color(red: 229/255, green: 231/255, blue: 235/255), lineWidth: 1)
        )
        .shadow(color: Color(red: 17/255, green: 24/255, blue: 39/255).opacity(0.05), radius: 8, x: 0, y: 2)
        .opacity(isAnimating ? 0.6 : 1.0)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
        }
    }
}

// MARK: - Error State

struct DiscoverErrorState: View {
    let onRetry: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            VStack(spacing: 12) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 48, weight: .light))
                    .foregroundColor(DesignSystem.Colors.textTertiary)

                Text("Something went wrong")
                    .font(DesignSystem.Typography.heading3)
                    .foregroundColor(DesignSystem.Colors.textPrimary)

                Text("We couldn't load the content. Please check your connection and try again.")
                    .font(DesignSystem.Typography.small)
                    .foregroundColor(DesignSystem.Colors.textTertiary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Button(action: onRetry) {
                Text("Retry")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: 260)
                    .frame(height: 38)
                    .background(Color(red: 31/255, green: 60/255, blue: 136/255))
                    .cornerRadius(16)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
}
