import SwiftUI

// MARK: - Shared feedback-state primitives
//
// Loading skeletons, empty states, and error states with retry. Use these
// everywhere so the visual language is consistent across feed, notifications,
// messages, inbox, and dashboards.
//
// Mirrors the web app's src/components/states.tsx shapes so a screen feels
// identical on either platform when content is missing or in flight.

// MARK: - Skeleton primitives

/// A single shimmery rounded rect. Compose for richer shapes.
struct LCSkeleton: View {
    let width: CGFloat?
    let height: CGFloat
    let cornerRadius: CGFloat
    @State private var pulse = false

    init(width: CGFloat? = nil, height: CGFloat = 12, cornerRadius: CGFloat = 6) {
        self.width = width
        self.height = height
        self.cornerRadius = cornerRadius
    }

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(Color.lcBorder.opacity(pulse ? 0.35 : 0.6))
            .frame(width: width, height: height)
            .frame(maxWidth: width == nil ? .infinity : nil)
            .onAppear {
                withAnimation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true)) {
                    pulse = true
                }
            }
    }
}

/// Circle skeleton — for avatars and icon slots.
struct LCSkeletonCircle: View {
    let size: CGFloat
    @State private var pulse = false

    init(size: CGFloat = 40) { self.size = size }

    var body: some View {
        Circle()
            .fill(Color.lcBorder.opacity(pulse ? 0.35 : 0.6))
            .frame(width: size, height: size)
            .onAppear {
                withAnimation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true)) {
                    pulse = true
                }
            }
    }
}

/// Row-shaped skeleton stack inside a card. Use during list loading.
struct LCListSkeleton: View {
    let rows: Int

    init(rows: Int = 5) { self.rows = rows }

    var body: some View {
        VStack(spacing: 0) {
            ForEach(0..<rows, id: \.self) { i in
                HStack(alignment: .top, spacing: 14) {
                    LCSkeletonCircle(size: 40)
                    VStack(alignment: .leading, spacing: 8) {
                        LCSkeleton(width: 140, height: 12)
                        LCSkeleton(height: 10)
                        LCSkeleton(width: 80, height: 9)
                            .padding(.top, 2)
                    }
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                if i < rows - 1 {
                    Divider().padding(.leading, 70)
                }
            }
        }
        .background(Color.white)
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.lcBorder, lineWidth: 1)
        )
        .padding(16)
    }
}

/// Post-card-shaped skeleton for the feed.
struct LCPostCardSkeleton: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                LCSkeletonCircle(size: 40)
                VStack(alignment: .leading, spacing: 6) {
                    LCSkeleton(width: 120, height: 12)
                    LCSkeleton(width: 80, height: 9)
                }
                Spacer()
            }
            LCSkeleton(height: 12)
            LCSkeleton(height: 12)
            LCSkeleton(width: 220, height: 12)
            HStack(spacing: 16) {
                LCSkeleton(width: 50, height: 22, cornerRadius: 11)
                LCSkeleton(width: 50, height: 22, cornerRadius: 11)
                LCSkeleton(width: 50, height: 22, cornerRadius: 11)
            }
            .padding(.top, 4)
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.lcBorder, lineWidth: 1)
        )
    }
}

/// Stack of post-card skeletons for the feed.
struct LCFeedSkeleton: View {
    let count: Int
    init(count: Int = 3) { self.count = count }

    var body: some View {
        VStack(spacing: 14) {
            ForEach(0..<count, id: \.self) { _ in
                LCPostCardSkeleton()
            }
        }
        .padding(.horizontal, 16)
    }
}

// MARK: - Empty state

struct LCEmptyAction: Identifiable {
    let id = UUID()
    let label: String
    let action: () -> Void
    let isPrimary: Bool

    init(_ label: String, isPrimary: Bool = true, action: @escaping () -> Void) {
        self.label = label
        self.isPrimary = isPrimary
        self.action = action
    }
}

struct LCEmptyState: View {
    let icon: String          // SF Symbol name
    let title: String
    let subtitle: String?
    let actions: [LCEmptyAction]

    init(icon: String, title: String, subtitle: String? = nil, actions: [LCEmptyAction] = []) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.actions = actions
    }

    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.lcNavy.opacity(0.08))
                    .frame(width: 60, height: 60)
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(.lcNavy)
            }
            .padding(.bottom, 4)

            Text(title)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.lcText)
                .multilineTextAlignment(.center)

            if let subtitle {
                Text(subtitle)
                    .font(.system(size: 13))
                    .foregroundColor(.lcText3)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }

            if !actions.isEmpty {
                HStack(spacing: 10) {
                    ForEach(actions) { action in
                        Button(action: action.action) {
                            Text(action.label)
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(action.isPrimary ? .white : .lcText)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(
                                    action.isPrimary
                                    ? AnyView(Color.lcNavy)
                                    : AnyView(Color.white.overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(Color.lcBorder, lineWidth: 1)
                                    ))
                                )
                                .cornerRadius(10)
                        }
                    }
                }
                .padding(.top, 6)
            }
        }
        .padding(.vertical, 32)
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 16)
    }
}

// MARK: - Error state

struct LCErrorState: View {
    let title: String
    let message: String
    let onRetry: (() -> Void)?

    init(
        title: String = "Something went wrong",
        message: String = "We couldn't load this right now. Try again in a moment.",
        onRetry: (() -> Void)? = nil
    ) {
        self.title = title
        self.message = message
        self.onRetry = onRetry
    }

    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.red.opacity(0.10))
                    .frame(width: 60, height: 60)
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 22))
                    .foregroundColor(.red)
            }
            .padding(.bottom, 4)

            Text(title)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.lcText)
                .multilineTextAlignment(.center)

            Text(message)
                .font(.system(size: 13))
                .foregroundColor(.lcText3)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            if let onRetry {
                Button(action: onRetry) {
                    Text("Try Again")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.lcNavy)
                        .cornerRadius(10)
                }
                .padding(.top, 6)
            }
        }
        .padding(.vertical, 32)
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 16)
    }
}
