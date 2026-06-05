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
            w.isReleasedWhenClosed = false
            self.window = w
        }
        window?.center()
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusBarItem: NSStatusItem?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        AppState.shared.requestPermission {
            SwipeManager.start()
        }
        
        observeSettings()
        observeAppState()
        updateStatusBarItemVisibility()
        
        // Auto-open Preferences on launch
        openPreferences()
    }
    
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        openPreferences()
        return true
    }
    
    private func observeAppState() {
        withObservationTracking {
            _ = AppState.shared.isTrusted
        } onChange: {
            DispatchQueue.main.async {
                self.updateStatusIcon()
                self.observeAppState()
            }
        }
    }
    
    private func observeSettings() {
        withObservationTracking {
            _ = Settings.shared.showMenuBarIcon
        } onChange: {
            DispatchQueue.main.async {
                self.updateStatusBarItemVisibility()
                self.observeSettings()
            }
        }
    }
    
    private func updateStatusBarItemVisibility() {
        if Settings.shared.showMenuBarIcon {
            if statusBarItem == nil {
                createStatusBarItem()
            }
        } else {
            if let item = statusBarItem {
                NSStatusBar.system.removeStatusItem(item)
                statusBarItem = nil
            }
        }
    }
    
    private func createStatusBarItem() {
        statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusBarItem?.behavior = .removalAllowed
        
        let menu = NSMenu()
        statusBarItem?.menu = menu
        
        updateStatusIcon()
    }
    
    private func updateStatusIcon() {
        guard let item = statusBarItem else { return }
        let iconName = AppState.shared.isTrusted ? "StatusIcon" : "StatusIcon-Warning"
        item.button?.image = NSImage(named: iconName)
        rebuildMenu()
    }
    
    private func rebuildMenu() {
        guard let item = statusBarItem, let menu = item.menu else { return }
        menu.removeAllItems()
        
        if !AppState.shared.isTrusted {
            let warningItem = NSMenuItem(title: "No Accessibility Access - Authorize...", action: #selector(openPrivacyAccessibility), keyEquivalent: "")
            warningItem.target = self
            menu.addItem(warningItem)
            menu.addItem(NSMenuItem.separator())
        }
        
        let prefsItem = NSMenuItem(title: "Preferences...", action: #selector(openPreferences), keyEquivalent: "")
        prefsItem.target = self
        menu.addItem(prefsItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let quitItem = NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "")
        quitItem.target = self
        menu.addItem(quitItem)
    }
    
    @objc private func openPrivacyAccessibility() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
        NSWorkspace.shared.open(url)
    }
    
    @objc private func openPreferences() {
        PreferencesWindowController.shared.show()
    }
    
    @objc private func quitApp() {
        NSApplication.shared.terminate(nil)
    }
}

@main
struct TouchTabApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        SwiftUI.Settings {
            EmptyView()
        }
    }
}

extension Bundle {
    var displayName: String { object(forInfoDictionaryKey: "CFBundleDisplayName") as? String ?? "" }
    var version: String { object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "" }
    var build: String { object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "" }
    var copyright: String { object(forInfoDictionaryKey: "NSHumanReadableCopyright") as? String ?? "" }
}
