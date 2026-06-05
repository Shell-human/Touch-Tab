import SwiftUI

struct AboutView: View {
    @ObservedObject var settings = Settings.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header / App Info
            HStack(alignment: .center, spacing: 16) {
                Image(nsImage: NSImage(named: BundleInfo.iconName()) ?? NSImage())
                    .resizable()
                    .frame(width: 48, height: 48)
                VStack(alignment: .leading, spacing: 2) {
                    Text(BundleInfo.displayName())
                        .font(.system(size: 15, weight: .bold))
                    Text("Version \(BundleInfo.version()) (\(BundleInfo.build()))")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
            }
            .padding(.bottom, 4)
            
            Divider()
            
            // Settings Sliders
            VStack(alignment: .leading, spacing: 12) {
                Text("Preferences")
                    .font(.system(size: 13, weight: .semibold))
                
                // Sensitivity Slider
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Swipe Sensitivity")
                            .font(.system(size: 12))
                        Spacer()
                        Text(String(format: "%.3f", settings.accVelXThreshold))
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                    Slider(
                        value: Binding(
                            get: { Double(settings.accVelXThreshold) },
                            set: { settings.accVelXThreshold = Float($0) }
                        ),
                        in: 0.01...0.08,
                        step: 0.005
                    )
                    HStack {
                        Text("Faster (0.01)")
                            .font(.system(size: 9))
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("Slower (0.08)")
                            .font(.system(size: 9))
                            .foregroundColor(.secondary)
                    }
                }
                
                // Delay Slider
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Switching Delay")
                            .font(.system(size: 12))
                        Spacer()
                        Text(String(format: "%.0f ms", settings.appSwitcherUIDelay * 1000))
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                    Slider(
                        value: $settings.appSwitcherUIDelay,
                        in: 0.0...0.3,
                        step: 0.025
                    )
                    HStack {
                        Text("Instant (0ms)")
                            .font(.system(size: 9))
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("Slower (300ms)")
                            .font(.system(size: 9))
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Divider()
            
            // Footer
            HStack {
                Text(BundleInfo.copyright())
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                Spacer()
                Button("Quit") {
                    NSApplication.shared.terminate(nil)
                }
                .controlSize(.small)
            }
        }
        .padding(20)
        .frame(width: 320)
    }
}

struct AboutView_Previews: PreviewProvider {
    static var previews: some View {
        AboutView()
    }
}
