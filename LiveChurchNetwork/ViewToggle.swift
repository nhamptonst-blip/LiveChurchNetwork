import SwiftUI

enum ViewMode {
    case grid
    case list
    case map
}

struct ViewToggleControl: View {
    @Binding var viewMode: ViewMode

    var body: some View {
        HStack(spacing: 4) {
            // Grid button
            Button {
                viewMode = .grid
            } label: {
                Image(systemName: "square.grid.2x2")
                    .font(.system(size: 14, weight: .bold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(viewMode == .grid ? Color.white : Color.clear)
                    .foregroundColor(viewMode == .grid ? Color(red: 31/255, green: 60/255, blue: 136/255) : Color(red: 107/255, green: 114/255, blue: 128/255))
                    .shadow(color: viewMode == .grid ? Color.black.opacity(0.08) : Color.clear, radius: 2, x: 0, y: 1)
            }

            // List button
            Button {
                viewMode = .list
            } label: {
                Image(systemName: "list.bullet")
                    .font(.system(size: 14, weight: .bold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(viewMode == .list ? Color.white : Color.clear)
                    .foregroundColor(viewMode == .list ? Color(red: 31/255, green: 60/255, blue: 136/255) : Color(red: 107/255, green: 114/255, blue: 128/255))
                    .shadow(color: viewMode == .list ? Color.black.opacity(0.08) : Color.clear, radius: 2, x: 0, y: 1)
            }

            // Map button
            Button {
                viewMode = .map
            } label: {
                Image(systemName: "map")
                    .font(.system(size: 14, weight: .bold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(viewMode == .map ? Color.white : Color.clear)
                    .foregroundColor(viewMode == .map ? Color(red: 31/255, green: 60/255, blue: 136/255) : Color(red: 107/255, green: 114/255, blue: 128/255))
                    .shadow(color: viewMode == .map ? Color.black.opacity(0.08) : Color.clear, radius: 2, x: 0, y: 1)
            }
        }
        .frame(height: 40)
        .background(Color(red: 243/255, green: 244/255, blue: 246/255))
        .cornerRadius(14)
        .padding(.horizontal, 20)
    }
}
