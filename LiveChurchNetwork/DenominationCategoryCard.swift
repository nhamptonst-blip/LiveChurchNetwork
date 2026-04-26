import SwiftUI

struct DenominationCategoryCard: View {
    let denomination: String
    let count: Int
    let isSelected: Bool
    let isFeatured: Bool
    let action: () -> Void
    @State private var isPressed = false

    var backgroundColor: Color {
        isFeatured ? Color(red: 31/255, green: 60/255, blue: 136/255).opacity(0.045) : Color.white
    }

    var borderColor: Color {
        isFeatured ? Color(red: 31/255, green: 60/255, blue: 136/255).opacity(0.12) : Color(red: 229/255, green: 231/255, blue: 235/255).opacity(0.9)
    }

    var countDisplay: String {
        if count > 0 {
            return "\(count) churches"
        }
        return "Explore churches"
    }

    var body: some View {
        Button(action: {
            HapticEngine.impact(.light)
            action()
        }) {
            ZStack(alignment: .topTrailing) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(denomination)
                        .font(.system(size: 15, weight: .black))
                        .tracking(-0.1)
                        .foregroundColor(Color(red: 17/255, green: 24/255, blue: 39/255))
                        .lineLimit(1)

                    Spacer()

                    Text(countDisplay)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Color(red: 107/255, green: 114/255, blue: 128/255))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .frame(height: 92)
                .padding(16)
                .background(backgroundColor)
                .clipShape(RoundedRectangle(cornerRadius: 24))
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(borderColor, lineWidth: 1)
                )
                .shadow(color: Color(red: 17/255, green: 24/255, blue: 39/255).opacity(0.05), radius: 10, x: 0, y: 2)

                // Top-right accent circle
                Circle()
                    .fill(Color(red: 31/255, green: 60/255, blue: 136/255).opacity(0.08))
                    .frame(width: 42, height: 42)
                    .padding(12)
            }
        }
        .buttonStyle(.plain)
        .scaleEffect(isPressed ? 0.97 : 1.0)
        .animation(.easeInOut(duration: 0.12), value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Browse \(denomination) churches")
        .accessibilityHint(count > 0 ? "\(count) churches available" : "")
    }
}

#Preview {
    VStack(spacing: 14) {
        HStack(spacing: 14) {
            DenominationCategoryCard(
                denomination: "Baptist",
                count: 2847,
                isSelected: false,
                isFeatured: false
            ) { }

            DenominationCategoryCard(
                denomination: "Non-Denominational",
                count: 3542,
                isSelected: false,
                isFeatured: true
            ) { }
        }

        HStack(spacing: 14) {
            DenominationCategoryCard(
                denomination: "Pentecostal",
                count: 1923,
                isSelected: false,
                isFeatured: false
            ) { }

            DenominationCategoryCard(
                denomination: "Methodist",
                count: 1456,
                isSelected: false,
                isFeatured: false
            ) { }
        }
    }
    .padding(20)
    .background(Color(red: 250/255, green: 249/255, blue: 246/255))
}
