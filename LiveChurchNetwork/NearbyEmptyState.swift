import SwiftUI

struct NearbyPermissionState: View {
    let onEnable: () -> Void

    var body: some View {
        VStack(alignment: .center, spacing: 16) {
            Image(systemName: "location.circle.fill")
                .font(.system(size: 48, weight: .light))
                .foregroundColor(Color(red: 31/255, green: 60/255, blue: 136/255))

            VStack(alignment: .center, spacing: 8) {
                Text("Turn on location to find nearby churches")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(Color(red: 17/255, green: 24/255, blue: 39/255))

                Text("See churches near you, local livestreams, and faith communities in your area.")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(Color(red: 107/255, green: 114/255, blue: 128/255))
                    .multilineTextAlignment(.center)
            }

            Button(action: {
                HapticEngine.impact(.light)
                onEnable()
            }) {
                Text("Enable Location")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(Color(red: 31/255, green: 60/255, blue: 136/255))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
        }
        .padding(22)
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color(red: 229/255, green: 231/255, blue: 235/255), lineWidth: 1)
        )
        .shadow(color: Color(red: 17/255, green: 24/255, blue: 39/255).opacity(0.05), radius: 12, x: 0, y: 2)
        .padding(.horizontal, 20)
    }
}

struct NearbyEmptyState: View {
    let onExpandRadius: () -> Void
    let onBrowseFeatured: () -> Void

    var body: some View {
        VStack(alignment: .center, spacing: 16) {
            Image(systemName: "building.circle.fill")
                .font(.system(size: 48, weight: .light))
                .foregroundColor(Color(red: 107/255, green: 114/255, blue: 128/255))

            VStack(alignment: .center, spacing: 8) {
                Text("No churches found nearby")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(Color(red: 17/255, green: 24/255, blue: 39/255))

                Text("Try expanding your radius or browse featured churches.")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(Color(red: 107/255, green: 114/255, blue: 128/255))
                    .multilineTextAlignment(.center)
            }

            HStack(spacing: 12) {
                Button(action: {
                    HapticEngine.impact(.light)
                    onExpandRadius()
                }) {
                    Text("Expand Radius")
                        .font(.system(size: 13, weight: .bold))
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .foregroundColor(.white)
                        .background(Color(red: 31/255, green: 60/255, blue: 136/255))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }

                Button(action: {
                    HapticEngine.impact(.light)
                    onBrowseFeatured()
                }) {
                    Text("Browse Featured")
                        .font(.system(size: 13, weight: .bold))
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .foregroundColor(Color(red: 31/255, green: 60/255, blue: 136/255))
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color(red: 229/255, green: 231/255, blue: 235/255), lineWidth: 1)
                        )
                }
            }
        }
        .padding(22)
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color(red: 229/255, green: 231/255, blue: 235/255), lineWidth: 1)
        )
        .shadow(color: Color(red: 17/255, green: 24/255, blue: 39/255).opacity(0.05), radius: 12, x: 0, y: 2)
        .padding(.horizontal, 20)
    }
}

struct ExpandRadiusPrompt: View {
    let onExpand: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Want to see more churches?")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(Color(red: 17/255, green: 24/255, blue: 39/255))

                Text("Expand your search radius to discover more nearby communities.")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(Color(red: 107/255, green: 114/255, blue: 128/255))
            }

            Button(action: {
                HapticEngine.impact(.light)
                onExpand()
            }) {
                Text("Expand Radius")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 40)
                    .background(Color(red: 31/255, green: 60/255, blue: 136/255))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .stroke(Color(red: 229/255, green: 231/255, blue: 235/255), lineWidth: 1)
        )
        .shadow(color: Color(red: 17/255, green: 24/255, blue: 39/255).opacity(0.05), radius: 12, x: 0, y: 2)
        .padding(.horizontal, 20)
    }
}

#Preview {
    VStack(spacing: 20) {
        NearbyPermissionState(onEnable: {})
        NearbyEmptyState(onExpandRadius: {}, onBrowseFeatured: {})
        ExpandRadiusPrompt(onExpand: {})
    }
    .padding(20)
    .background(Color(red: 250/255, green: 249/255, blue: 246/255))
}
