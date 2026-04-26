import SwiftUI

struct DenominationCategoryCard: View {
    let denomination: String
    let count: Int
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: {
            HapticEngine.selection()
            action()
        }) {
            VStack(alignment: .leading, spacing: 8) {
                Text(denomination)
                    .font(.system(size: 15, weight: .black))
                    .foregroundColor(Color(red: 17/255, green: 24/255, blue: 39/255))
                    .lineLimit(1)

                Spacer()

                HStack(spacing: 0) {
                    Text("\(count)")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Color(red: 107/255, green: 114/255, blue: 128/255))

                    Text(" churches")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Color(red: 107/255, green: 114/255, blue: 128/255))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: 88)
            .padding(16)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 22))
            .overlay(
                RoundedRectangle(cornerRadius: 22)
                    .stroke(Color(red: 229/255, green: 231/255, blue: 235/255).opacity(0.9), lineWidth: 1)
            )
            .shadow(color: Color(red: 17/255, green: 24/255, blue: 39/255).opacity(0.05), radius: 12, x: 0, y: 4)
            .scaleEffect(isSelected ? 0.97 : 1.0)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    VStack(spacing: 12) {
        HStack(spacing: 14) {
            DenominationCategoryCard(
                denomination: "Baptist",
                count: 2847,
                isSelected: false
            ) { }

            DenominationCategoryCard(
                denomination: "Non-Denominational",
                count: 3542,
                isSelected: true
            ) { }
        }

        HStack(spacing: 14) {
            DenominationCategoryCard(
                denomination: "Pentecostal",
                count: 1923,
                isSelected: false
            ) { }

            DenominationCategoryCard(
                denomination: "Methodist",
                count: 1456,
                isSelected: false
            ) { }
        }
    }
    .padding(20)
}
