import Cocoa
import SwiftUI
import Observation

@Observable
class AppState {
    static let shared = AppState()
    var isTrusted = false
    
    private init() {
        isTrusted = AXIsProcessTrusted()
    }
    
    func checkPermission() {
        isTrusted = AXIsProcessTrusted()
    }
    
    func requestPermission(completion: @escaping () -> Void) {
        if isProcessTrustedWithPrompt() {
            isTrusted = true
            completion()
        } else {
            isTrusted = false
            Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
                if AXIsProcessTrusted() {
                    self.isTrusted = true
                    timer.invalidate()
                    completion()
                }
            }
        }
    }
    
    private func isProcessTrustedWithPrompt() -> Bool {
        let isAccessibilityPermissionGranted = AXIsProcessTrustedWithOptions([kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String : true] as CFDictionary)
        if isAccessibilityPermissionGranted {
            return true
        } else {
            // Trigger OS permission dialog from sandbox
            _ = CGEvent.tapCreate(
                tap: .cghidEventTap,
                place: .headInsertEventTap,
                options: .defaultTap,
                eventsOfInterest: NSEvent.EventTypeMask.gesture.rawValue,
                callback: { _, _, event, _ in Unmanaged.passUnretained(event) },
                userInfo: nil
            )
            return false
        }
    }
}

class PreferencesWindowController: NSObject {
    static let shared = PreferencesWindowController()
    private var window: NSWindow?
    
    func show() {
        if window == nil {
            let controller = NSHostingController(rootView: AboutView())
            let w = NSWindow(contentViewController: controller)
            w.styleMask = [.closable, .titled]
            w.title = ""
            self.window = w
        }
        window?.center()
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}

@main
struct TouchTabApp: App {
    @State private var appState = AppState.shared
    
    init() {
        AppState.shared.requestPermission {
            SwipeManager.start()
        }
    }
    
    var body: some Scene {
        MenuBarExtra {
            if !appState.isTrusted {
                Button("No Accessibility Access - Authorize...") {
                    openPrivacyAccessibility()
                }
                Divider()
            }
            
            Button("Preferences...") {
                openPreferences()
            }
            Divider()
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
        } label: {
            Image(nsImage: NSImage(named: appState.isTrusted ? "StatusIcon" : "StatusIcon-Warning") ?? NSImage())
        }
    }
    
    private func openPrivacyAccessibility() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
        NSWorkspace.shared.open(url)
    }
    
    private func openPreferences() {
        PreferencesWindowController.shared.show()
    }
}

extension Bundle {
    var displayName: String { object(forInfoDictionaryKey: "CFBundleDisplayName") as? String ?? "" }
    var version: String { object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "" }
    var build: String { object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "" }
    var copyright: String { object(forInfoDictionaryKey: "NSHumanReadableCopyright") as? String ?? "" }
}
