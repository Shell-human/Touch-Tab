import SwiftUI

struct AboutView: View {
    @State private var settings = Settings.shared
    @State private var appState = AppState.shared
    
    var body: some View {
        @Bindable var settings = settings
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 16) {

                // Header / App Info (Centered)
                HStack {
                    Spacer()
                    VStack(alignment: .center, spacing: 4) {
                        Text(Bundle.main.displayName)
                            .font(.system(size: 15, weight: .bold))
                        Text(String(format: NSLocalizedString("Version %@", comment: ""), Bundle.main.version))
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
                .padding(.bottom, 4)
                
                Divider()
                
                // Warning Banner if not trusted
                if !appState.isTrusted {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 6) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                                .imageScale(.small)
                            Text(NSLocalizedString("Accessibility Access Required", comment: ""))
                                .font(.system(size: 11, weight: .bold))
                        }
                        Text(NSLocalizedString("Please authorize Touch-Tab in System Settings to enable trackpad gesture switching.", comment: ""))
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                            .lineLimit(nil)
                            .fixedSize(horizontal: false, vertical: true)
                        Button(NSLocalizedString("Open System Settings", comment: "")) {
                            let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
                            NSWorkspace.shared.open(url)
                        }
                        .buttonStyle(BorderedButtonStyle())
                        .controlSize(.mini)
                    }
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(6)
                    
                    Divider()
                }
                
                // Settings Sliders
                VStack(alignment: .leading, spacing: 12) {
                    Text(NSLocalizedString("Preferences", comment: ""))
                        .font(.system(size: 13, weight: .semibold))
                    
                    // Toggle Options
                    VStack(alignment: .leading, spacing: 8) {
                        Toggle(NSLocalizedString("Launch at Login", comment: ""), isOn: $settings.isLaunchAtLoginEnabled)
                            .font(.system(size: 12))
                        Toggle(NSLocalizedString("Show Icon in Menu Bar", comment: ""), isOn: $settings.showMenuBarIcon)
                            .font(.system(size: 12))
                    }
                    .padding(.bottom, 4)
                    
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(NSLocalizedString("Swipe Sensitivity", comment: ""))
                                .font(.system(size: 12))
                            Spacer()
                            Text(String(format: "%.3f", settings.accVelXThreshold))
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }
                        Slider(
                            value: $settings.accVelXThreshold,
                            in: 0.01...0.08,
                            step: 0.005
                        )
                        HStack {
                            Text(NSLocalizedString("Faster (0.01)", comment: ""))
                                .font(.system(size: 9))
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(NSLocalizedString("Slower (0.08)", comment: ""))
                                .font(.system(size: 9))
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // Delay Slider
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(NSLocalizedString("Switching Delay", comment: ""))
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
                            Text(NSLocalizedString("Instant (0ms)", comment: ""))
                                .font(.system(size: 9))
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(NSLocalizedString("Slower (300ms)", comment: ""))
                                .font(.system(size: 9))
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // Gesture Acceleration Slider
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(NSLocalizedString("Gesture Acceleration", comment: ""))
                                .font(.system(size: 12))
                            Spacer()
                            Text(String(format: "%.1fx", settings.gestureAcceleration))
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }
                        Slider(
                            value: $settings.gestureAcceleration,
                            in: 0.0...5.0,
                            step: 0.5
                        )
                        HStack {
                            Text(NSLocalizedString("Linear (0.0x)", comment: ""))
                                .font(.system(size: 9))
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(NSLocalizedString("Maximum (5.0x)", comment: ""))
                                .font(.system(size: 9))
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // Reset Button
                    HStack {
                        Spacer()
                        Button(action: {
                            settings.resetToDefaults()
                        }) {
                            Label(NSLocalizedString("Reset to Defaults", comment: ""), systemImage: "arrow.counterclockwise")
                        }
                        .controlSize(.small)
                    }
                    .padding(.top, 4)
                }
                
                Divider()
                
                // Footer
                HStack {
                    Spacer()
                    Button(NSLocalizedString("Quit", comment: "")) {
                        NSApplication.shared.terminate(nil)
                    }
                    .controlSize(.small)
                }
            }
            .padding(20)
        }
        .frame(width: 320, height: appState.isTrusted ? 470 : 590)
    }
}
