import SwiftUI

struct DenominationCategoryCard: View {
    let denomination: String
    let count: Int
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                Text(denomination)
                    .font(.system(size: 16, weight: .black))
                    .foregroundColor(Color(red: 17/255, green: 24/255, blue: 39/255))
                    .lineLimit(1)

                Spacer()

                HStack(spacing: 0) {
                    Text("\(count)")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Color(red: 107/255, green: 114/255, blue: 128/255))

                    Text(" churches")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Color(red: 107/255, green: 114/255, blue: 128/255))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: 86)
            .padding(16)
            .background(isSelected ? Color(red: 31/255, green: 60/255, blue: 136/255).opacity(0.1) : Color.white)
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        isSelected
                            ? Color(red: 31/255, green: 60/255, blue: 136/255).opacity(0.3)
                            : Color(red: 229/255, green: 231/255, blue: 235/255),
                        lineWidth: 1
                    )
            )
            .shadow(color: Color(red: 17/255, green: 24/255, blue: 39/255).opacity(0.05), radius: 8, x: 0, y: 2)
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
