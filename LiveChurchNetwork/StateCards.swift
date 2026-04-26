import SwiftUI

// MARK: - Empty State Card (Standardized)

struct EmptyStateCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let primaryAction: (label: String, action: () -> Void)?
    let secondaryAction: (label: String, action: () -> Void)?

    var body: some View {
        VStack(spacing: 16) {
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color(red: 31/255, green: 60/255, blue: 136/255).opacity(0.08))
                        .frame(width: 52, height: 52)

                    Image(systemName: icon)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(Color(red: 31/255, green: 60/255, blue: 136/255))
                }

                VStack(spacing: 8) {
                    Text(title)
                        .font(.system(size: 17, weight: .black))
                        .foregroundColor(Color(red: 17/255, green: 24/255, blue: 39/255))
                        .lineLimit(2)

                    Text(subtitle)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color(red: 107/255, green: 114/255, blue: 128/255))
                        .multilineTextAlignment(.center)
                        .lineSpacing(1)
                }
            }

            if primaryAction != nil || secondaryAction != nil {
                VStack(spacing: 10) {
                    if let primary = primaryAction {
                        Button(action: {
                            HapticEngine.impact(.light)
                            primary.action()
                        }) {
                            Text(primary.label)
                                .font(.system(size: 14, weight: .black))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 40)
                                .background(Color(red: 31/255, green: 60/255, blue: 136/255))
                                .clipShape(RoundedRectangle(cornerRadius: 999))
                        }
                    }

                    if let secondary = secondaryAction {
                        Button(action: {
                            HapticEngine.impact(.light)
                            secondary.action()
                        }) {
                            Text(secondary.label)
                                .font(.system(size: 14, weight: .black))
                                .foregroundColor(Color(red: 31/255, green: 60/255, blue: 136/255))
                                .frame(maxWidth: .infinity)
                                .frame(height: 40)
                                .background(Color(red: 243/255, green: 244/255, blue: 246/255))
                                .clipShape(RoundedRectangle(cornerRadius: 999))
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(22)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color(red: 229/255, green: 231/255, blue: 235/255), lineWidth: 1)
        )
        .shadow(color: Color(red: 17/255, green: 24/255, blue: 39/255).opacity(0.05), radius: 8, x: 0, y: 2)
        .padding(.horizontal, 20)
    }
}

// MARK: - Error State Card (Standardized)

struct ErrorStateCard: View {
    let title: String
    let subtitle: String
    let primaryAction: (label: String, action: () -> Void)
    let secondaryAction: (label: String, action: () -> Void)?

    var body: some View {
        VStack(spacing: 16) {
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color(red: 31/255, green: 60/255, blue: 136/255).opacity(0.08))
                        .frame(width: 52, height: 52)

                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(Color(red: 31/255, green: 60/255, blue: 136/255))
                }

                VStack(spacing: 8) {
                    Text(title)
                        .font(.system(size: 17, weight: .black))
                        .foregroundColor(Color(red: 17/255, green: 24/255, blue: 39/255))
                        .lineLimit(2)

                    Text(subtitle)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color(red: 107/255, green: 114/255, blue: 128/255))
                        .multilineTextAlignment(.center)
                        .lineSpacing(1)
                }
            }

            VStack(spacing: 10) {
                Button(action: {
                    HapticEngine.impact(.light)
                    primaryAction.action()
                }) {
                    Text(primaryAction.label)
                        .font(.system(size: 14, weight: .black))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 40)
                        .background(Color(red: 31/255, green: 60/255, blue: 136/255))
                        .clipShape(RoundedRectangle(cornerRadius: 999))
                }

                if let secondary = secondaryAction {
                    Button(action: {
                        HapticEngine.impact(.light)
                        secondary.action()
                    }) {
                        Text(secondary.label)
                            .font(.system(size: 14, weight: .black))
                            .foregroundColor(Color(red: 31/255, green: 60/255, blue: 136/255))
                            .frame(maxWidth: .infinity)
                            .frame(height: 40)
                            .background(Color(red: 243/255, green: 244/255, blue: 246/255))
                            .clipShape(RoundedRectangle(cornerRadius: 999))
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(22)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color(red: 229/255, green: 231/255, blue: 235/255), lineWidth: 1)
        )
        .shadow(color: Color(red: 17/255, green: 24/255, blue: 39/255).opacity(0.05), radius: 8, x: 0, y: 2)
        .padding(.horizontal, 20)
    }
}

#Preview {
    VStack(spacing: 20) {
        EmptyStateCard(
            icon: "antenna.radiowaves.left.and.right",
            title: "No churches are live right now",
            subtitle: "Explore featured churches or check back during service times.",
            primaryAction: (label: "Browse Churches", action: {}),
            secondaryAction: nil
        )

        ErrorStateCard(
            title: "Something went wrong",
            subtitle: "We couldn't load this section. Please try again.",
            primaryAction: (label: "Retry", action: {}),
            secondaryAction: (label: "Go Back", action: {})
        )
    }
    .padding(20)
    .background(Color(red: 250/255, green: 249/255, blue: 246/255))
}
