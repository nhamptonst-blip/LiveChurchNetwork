import SwiftUI

struct NearbyControls: View {
    @Binding var selectedRadius: Double
    @Binding var selectedSort: String
    @Binding var showFilterSheet: Bool

    private let radiusOptions = [5.0, 10.0, 25.0, 50.0]
    private let sortOptions = ["Closest", "Most Followed", "Live Now", "Recommended"]

    var body: some View {
        HStack(spacing: 8) {
            // Radius selector
            Menu {
                ForEach(radiusOptions, id: \.self) { radius in
                    Button(action: {
                        selectedRadius = radius
                        HapticEngine.selection()
                    }) {
                        HStack {
                            Text("\(Int(radius)) Miles")
                            if selectedRadius == radius {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                ControlPill(label: "\(Int(selectedRadius)) Miles", isActive: false)
            }

            // Sort selector
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
                ControlPill(label: selectedSort, isActive: false)
            }

            // Filters
            Button(action: {
                showFilterSheet = true
                HapticEngine.selection()
            }) {
                ControlPill(label: "Filters", isActive: false)
            }

            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }
}

struct ControlPill: View {
    let label: String
    let isActive: Bool

    var body: some View {
        Text(label)
            .font(.system(size: 12, weight: .bold))
            .foregroundColor(isActive ? Color.white : Color(red: 55/255, green: 65/255, blue: 81/255))
            .padding(.horizontal, 12)
            .frame(height: 34)
            .background(isActive ? Color(red: 31/255, green: 60/255, blue: 136/255) : Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 999))
            .overlay(
                RoundedRectangle(cornerRadius: 999)
                    .stroke(Color(red: 229/255, green: 231/255, blue: 235/255), lineWidth: 1)
            )
    }
}

struct NearbyViewToggle: View {
    @Binding var showMap: Bool

    var body: some View {
        HStack(spacing: 4) {
            Button(action: {
                showMap = false
                HapticEngine.selection()
            }) {
                Text("List")
                    .font(.system(size: 13, weight: .bold))
                    .frame(maxWidth: .infinity)
                    .frame(height: 36)
                    .foregroundColor(showMap ? Color(red: 107/255, green: 114/255, blue: 128/255) : Color(red: 31/255, green: 60/255, blue: 136/255))
                    .background(showMap ? Color.clear : Color.white)
            }

            Button(action: {
                showMap = true
                HapticEngine.selection()
            }) {
                Text("Map")
                    .font(.system(size: 13, weight: .bold))
                    .frame(maxWidth: .infinity)
                    .frame(height: 36)
                    .foregroundColor(showMap ? Color(red: 31/255, green: 60/255, blue: 136/255) : Color(red: 107/255, green: 114/255, blue: 128/255))
                    .background(showMap ? Color.white : Color.clear)
            }
        }
        .frame(height: 38)
        .background(Color(red: 243/255, green: 244/255, blue: 246/255))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
    }
}

#Preview {
    VStack(spacing: 16) {
        NearbyControls(selectedRadius: .constant(10), selectedSort: .constant("Closest"), showFilterSheet: .constant(false))

        NearbyViewToggle(showMap: .constant(false))
    }
    .padding(20)
    .background(Color(red: 250/255, green: 249/255, blue: 246/255))
}
