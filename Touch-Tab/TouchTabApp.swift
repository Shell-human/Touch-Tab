import Cocoa
import SwiftUI
import Observation

// MARK: - Accessibility Permission State

/// Monitors and manages macOS Accessibility (AX) permission status.
/// All access is expected on the main thread (Timer fires on main RunLoop).
@Observable
class AppState {
    static let shared = AppState()
    var isTrusted = false
    private var permissionTimer: Timer?
    
    private init() {
        isTrusted = AXIsProcessTrusted()
    }
    
    /// Requests Accessibility permission with a system prompt dialog.
    /// Polls every second until granted, then invokes `completion` on the main thread.
    func requestPermission(completion: @escaping () -> Void) {
        permissionTimer?.invalidate()
        if isProcessTrustedWithPrompt() {
            isTrusted = true
            completion()
        } else {
            isTrusted = false
            permissionTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
                if AXIsProcessTrusted() {
                    self?.isTrusted = true
                    timer.invalidate()
                    self?.permissionTimer = nil
                    completion()
                }
            }
        }
    }
    
    private func isProcessTrustedWithPrompt() -> Bool {
        return AXIsProcessTrustedWithOptions([kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String : true] as CFDictionary)
    }
}

// MARK: - Preferences Window

/// Manages a single Preferences window instance, creating it lazily and cleaning up on close.
@MainActor
class PreferencesWindowController: NSObject, NSWindowDelegate {
    static let shared = PreferencesWindowController()
    private var window: NSWindow?
    
    func show() {
        if window == nil {
            let controller = NSHostingController(rootView: AboutView())
            let w = NSWindow(contentViewController: controller)
            w.styleMask = [.closable, .titled]
            w.title = ""
            w.isReleasedWhenClosed = false
            w.delegate = self
            self.window = w
        }
        window?.center()
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    func windowWillClose(_ notification: Notification) {
        window = nil
    }
}

// MARK: - App Delegate

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
        
        let menu = NSMenu()
        statusBarItem?.menu = menu
        
        updateStatusIcon()
    }
    
    private func updateStatusIcon() {
        guard let item = statusBarItem else { return }
        let isTrusted = AppState.shared.isTrusted
        let iconName = isTrusted ? "StatusIcon" : "StatusIcon-Warning"
        let pointSize: CGFloat = isTrusted ? 16 : 22
        
        let image = loadStatusBarIcon(named: iconName, pointSize: pointSize)
        if image == nil {
            debugPrint("Status bar icon image '\(iconName)' not found in bundle")
        }
        image?.isTemplate = true
        item.button?.image = image
        rebuildMenu()
    }
    
    private func loadStatusBarIcon(named name: String, pointSize: CGFloat) -> NSImage? {
        let image = NSImage(size: NSSize(width: pointSize, height: pointSize))
        
        // Load 1x representation
        if let path1x = Bundle.main.path(forResource: name, ofType: "png"),
           let img1x = NSImage(contentsOfFile: path1x),
           let rep1x = img1x.representations.first {
            rep1x.size = NSSize(width: pointSize, height: pointSize)
            image.addRepresentation(rep1x)
        }
        
        // Load 2x representation
        let name2x = name + "@2x"
        if let path2x = Bundle.main.path(forResource: name2x, ofType: "png"),
           let img2x = NSImage(contentsOfFile: path2x),
           let rep2x = img2x.representations.first {
            rep2x.size = NSSize(width: pointSize, height: pointSize)
            image.addRepresentation(rep2x)
        }
        
        if image.representations.isEmpty {
            return NSImage(named: name)
        }
        
        return image
    }
    
    private func rebuildMenu() {
        guard let item = statusBarItem, let menu = item.menu else { return }
        menu.removeAllItems()
        
        if !AppState.shared.isTrusted {
            let warningItem = NSMenuItem(
                title: NSLocalizedString("No Accessibility Access - Authorize...", comment: "Menu bar item shown when AX permission is missing"),
                action: #selector(openPrivacyAccessibility),
                keyEquivalent: ""
            )
            warningItem.target = self
            menu.addItem(warningItem)
            menu.addItem(NSMenuItem.separator())
        }
        
        let prefsItem = NSMenuItem(
            title: NSLocalizedString("Preferences...", comment: "Menu bar item to open the Preferences window"),
            action: #selector(openPreferences),
            keyEquivalent: ""
        )
        prefsItem.target = self
        menu.addItem(prefsItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let quitItem = NSMenuItem(
            title: NSLocalizedString("Quit", comment: "Menu bar item to quit the application"),
            action: #selector(quitApp),
            keyEquivalent: ""
        )
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

// MARK: - App Entry Point

@main
struct TouchTabApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        SwiftUI.Settings {
            EmptyView()
        }
    }
}

// MARK: - Bundle Helpers

extension Bundle {
    /// Returns the user-facing display name, falling back through CFBundleName to a hardcoded default.
    var displayName: String {
        object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
            ?? object(forInfoDictionaryKey: "CFBundleName") as? String
            ?? "Touch-Tab"
    }
    var version: String { object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "" }
}
