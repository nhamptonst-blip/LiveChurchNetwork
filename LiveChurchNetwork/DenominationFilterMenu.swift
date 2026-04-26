import SwiftUI

struct DenominationFilterMenu: View {
    @Binding var selectedDenomination: String?
    let denominationCounts: [String: Int]
    let denominationCategories: [String]

    var selectedLabel: String {
        if let selected = selectedDenomination {
            return selected
        }
        return "All Denominations"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Browse by Denomination")
                    .font(.system(size: 22, weight: .black))
                    .foregroundColor(Color(red: 17/255, green: 24/255, blue: 39/255))

                Text("Find churches by tradition and worship style")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color(red: 107/255, green: 114/255, blue: 128/255))
            }
            .padding(.horizontal, 20)

            // Dropdown menu button
            Menu {
                // "All Denominations" option
                Button(action: {
                    selectedDenomination = nil
                    HapticEngine.selection()
                }) {
                    HStack {
                        Text("All Denominations")
                        if selectedDenomination == nil {
                            Image(systemName: "checkmark")
                                .foregroundColor(Color(red: 31/255, green: 60/255, blue: 136/255))
                        }
                    }
                }

                Divider()

                // Individual denomination options
                ForEach(denominationCategories, id: \.self) { denomination in
                    Button(action: {
                        selectedDenomination = denomination
                        HapticEngine.selection()
                    }) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(denomination)
                                let count = denominationCounts[denomination] ?? 0
                                if count > 0 {
                                    Text("\(count) churches")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(Color(red: 107/255, green: 114/255, blue: 128/255))
                                }
                            }
                            Spacer()
                            if selectedDenomination == denomination {
                                Image(systemName: "checkmark")
                                    .foregroundColor(Color(red: 31/255, green: 60/255, blue: 136/255))
                            }
                        }
                    }
                }
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Selected Filter")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(Color(red: 107/255, green: 114/255, blue: 128/255))

                        Text(selectedLabel)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(Color(red: 17/255, green: 24/255, blue: 39/255))
                            .lineLimit(1)
                    }

                    Spacer()

                    Image(systemName: "chevron.down")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color(red: 107/255, green: 114/255, blue: 128/255))
                }
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .padding(.horizontal, 14)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color(red: 229/255, green: 231/255, blue: 235/255), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 20)
        }
        .padding(.vertical, 20)
    }
}

#Preview {
    DenominationFilterMenu(
        selectedDenomination: .constant("Baptist"),
        denominationCounts: [
            "Non-Denominational": 245,
            "Baptist": 189,
            "Catholic": 156,
            "Pentecostal": 98,
            "Methodist": 67
        ],
        denominationCategories: [
            "Non-Denominational", "Baptist", "Catholic",
            "Pentecostal", "Methodist", "Lutheran"
        ]
    )
    .padding()
}
