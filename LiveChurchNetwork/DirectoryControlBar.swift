import SwiftUI

struct DirectoryControlBar: View {
    @Binding var selectedSort: String
    @Binding var viewDensity: String
    let onFiltersTap: () -> Void
    let sortOptions: [String]

    var body: some View {
        HStack(spacing: 8) {
            // Sort Menu
            Menu {
                ForEach(sortOptions, id: \.self) { option in
                    Button(action: {
                        selectedSort = option
                        HapticEngine.selection()
                    }) {
                        HStack {
                            Text(option)
                            if selectedSort == option {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                ControlPillLabel(label: selectedSort, isActive: false)
            }

            // Filters Button
            Button(action: {
                HapticEngine.selection()
                onFiltersTap()
            }) {
                ControlPillLabel(label: "Filters", isActive: false)
            }

            // View Density Toggle
            Menu {
                Button(action: {
                    viewDensity = "Comfortable"
                    HapticEngine.selection()
                }) {
                    HStack {
                        Text("Comfortable")
                        if viewDensity == "Comfortable" {
                            Image(systemName: "checkmark")
                        }
                    }
                }
                Button(action: {
                    viewDensity = "Compact"
                    HapticEngine.selection()
                }) {
                    HStack {
                        Text("Compact")
                        if viewDensity == "Compact" {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            } label: {
                ControlPillLabel(label: viewDensity == "Comfortable" ? "Grid" : "Compact", isActive: false)
            }

            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
    }
}

struct ControlPillLabel: View {
    let label: String
    let isActive: Bool

    var body: some View {
        Text(label)
            .font(.system(size: 13, weight: .bold))
            .foregroundColor(isActive ? Color.white : Color(red: 55/255, green: 65/255, blue: 81/255))
            .padding(.horizontal, 14)
            .frame(height: 36)
            .background(isActive ? Color(red: 31/255, green: 60/255, blue: 136/255) : Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 999))
            .overlay(
                RoundedRectangle(cornerRadius: 999)
                    .stroke(Color(red: 229/255, green: 231/255, blue: 235/255), lineWidth: 1)
            )
    }
}

#Preview {
    VStack(spacing: 12) {
        DirectoryControlBar(
            selectedSort: .constant("Recommended"),
            viewDensity: .constant("Comfortable"),
            onFiltersTap: { },
            sortOptions: ["Recommended", "Most Followed", "Recently Added", "A–Z", "Live Now"]
        )
        Spacer()
    }
    .padding(20)
    .background(Color(red: 250/255, green: 249/255, blue: 246/255))
}
