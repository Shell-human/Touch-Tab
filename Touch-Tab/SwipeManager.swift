import Cocoa
import Observation
import ServiceManagement

// MARK: - App Switcher (Keyboard Event Emitter)

/// Emits synthetic Cmd+Tab / Cmd+Shift+Tab keyboard events to drive the macOS App Switcher.
enum AppSwitcher {
    private static let keyboardEventSource = CGEventSource(stateID: .hidSystemState)
    private static let tabKey: CGKeyCode = 0x30
    private static let leftCommandKey: CGKeyCode = 0x37

    /// Releases the Command key to confirm the current App Switcher selection.
    static func selectInAppSwitcher() {
        postKeyEvent(key: leftCommandKey, down: false)
    }

    /// Sends Cmd+Tab to move forward in the App Switcher.
    static func cmdTab() {
        postKeyEvent(key: tabKey, down: true, flags: .maskCommand)
        postKeyEvent(key: tabKey, down: false, flags: .maskCommand)
    }

    /// Sends Cmd+Shift+Tab to move backward in the App Switcher.
    static func cmdShiftTab() {
        postKeyEvent(key: tabKey, down: true, flags: [.maskCommand, .maskShift])
        postKeyEvent(key: tabKey, down: false, flags: [.maskCommand, .maskShift])
    }

    private static func postKeyEvent(key: CGKeyCode, down: Bool, flags: CGEventFlags = []) {
        let event = CGEvent(keyboardEventSource: keyboardEventSource, virtualKey: key, keyDown: down)
        event?.flags = flags
        event?.post(tap: .cghidEventTap)
    }
}

// MARK: - Swipe Manager (Gesture → App Switch)

/// Intercepts 3-finger trackpad gestures via a CGEvent tap and translates them into App Switcher commands.
///
/// **Threading model**: The event tap callback runs on the same thread as the RunLoop it's attached to.
/// `start()` is called from a Timer on the main RunLoop, so all callbacks execute on the main thread.
enum SwipeManager {
    /// Minimum accumulated velocity before a swipe triggers an app switch.
    private static var accVelXThreshold: Double { Settings.shared.accVelXThreshold }
    /// Minimum time interval between consecutive app switches (debounce).
    private static var appSwitcherUIDelay: Double { Settings.shared.appSwitcherUIDelay }

    private static var eventTap: CFMachPort? = nil
    /// Running sum of horizontal velocity, reset after each threshold crossing or finger-count change.
    private static var accVelX: Double = 0
    private static var prevTouchPositions: [String: NSPoint] = [:]
    /// Timestamp of the first threshold crossing in the current gesture sequence.
    private static var startTime: Date? = nil
    /// Timestamp of the last processed touch event for frame-rate independent velocity calculations.
    private static var lastEventTimestamp: TimeInterval? = nil

    static func start() {
        guard eventTap == nil else {
            debugPrint("SwipeManager is already started")
            return
        }
        debugPrint("SwipeManager start")
        eventTap = CGEvent.tapCreate(
            tap: .cghidEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: NSEvent.EventTypeMask.gesture.rawValue,
            callback: { _, type, cgEvent, _ in
                SwipeManager.eventHandler(type, cgEvent: cgEvent)
            },
            userInfo: nil
        )
        guard let eventTap else {
            debugPrint("SwipeManager couldn't create event tap")
            showAccessibilityAlert()
            return
        }
        
        let runLoopSource = CFMachPortCreateRunLoopSource(nil, eventTap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: eventTap, enable: true)
    }
    
    private static func showAccessibilityAlert() {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = NSLocalizedString("Accessibility Permission Required", comment: "Alert title when event tap creation fails")
            alert.informativeText = NSLocalizedString("Touch-Tab needs Accessibility permission to detect trackpad gestures. Please authorize it in System Settings.", comment: "Alert body explaining why AX permission is needed")
            alert.alertStyle = .warning
            alert.addButton(withTitle: NSLocalizedString("Open System Settings", comment: "Button to open System Settings > Accessibility"))
            alert.addButton(withTitle: NSLocalizedString("Cancel", comment: "Button to dismiss the alert"))
            
            let response = alert.runModal()
            if response == .alertFirstButtonReturn {
                if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
                    NSWorkspace.shared.open(url)
                }
            }
        }
    }

    private static func eventHandler(_ eventType: CGEventType, cgEvent: CGEvent) -> Unmanaged<CGEvent>? {
        var swallow = false
        if eventType.rawValue == NSEvent.EventType.gesture.rawValue, let nsEvent = NSEvent(cgEvent: cgEvent) {
            swallow = touchEventHandler(nsEvent)
        } else if eventType == .tapDisabledByUserInput || eventType == .tapDisabledByTimeout {
            debugPrint("SwipeManager tap disabled", eventType.rawValue)
            if let eventTap {
                CGEvent.tapEnable(tap: eventTap, enable: true)
            }
        }
        return swallow ? nil : Unmanaged.passUnretained(cgEvent)
    }
    
    private static func touchEventHandler(_ nsEvent: NSEvent) -> Bool {
        let touches = nsEvent.allTouches()
        guard !touches.isEmpty else { return false }
        
        let touchesCount = touches.allSatisfy({ $0.phase == .ended }) ? 0 : touches.count

        switch touchesCount {
        case 2:
            clearEventState()
            return false
        case 3:
            return processThreeFingers(touches: touches, eventTimestamp: nsEvent.timestamp)
        default:
            processOtherFingers()
            return false
        }
    }

    private static func processThreeFingers(touches: Set<NSTouch>, eventTimestamp: TimeInterval) -> Bool {
        guard let velX = horizontalSwipeVelocity(touches: touches) else {
            updateTouchPositions(touches: touches)
            return false
        }
        updateTouchPositions(touches: touches)

        // Calculate time delta since the last event to achieve frame-rate independence.
        let dt: Double
        if let lastTime = lastEventTimestamp {
            dt = max(eventTimestamp - lastTime, 0.001) // Safeguard against division by zero
        } else {
            dt = 0.0166 // Assume standard 16.6ms (60Hz) frame interval for the first sample
        }
        lastEventTimestamp = eventTimestamp

        // Calculate speed in normalized coordinate units per second (independent of frame rate).
        let speed = Double(abs(velX)) / dt
        let accelFactor = Settings.shared.gestureAcceleration
        let dynamicMultiplier = 1.0 + (speed * DefaultSettings.accelSpeedScale * accelFactor)
        accVelX += Double(velX) * dynamicMultiplier
        if abs(accVelX) < accVelXThreshold {
            return true
        }

        if startTime == nil {
            startTime = Date()
        } else if let t = startTime {
            let interval = -t.timeIntervalSinceNow
            if interval < appSwitcherUIDelay {
                resetAccumulator()
                return true
            }
        }

        startOrContinueGesture()
        resetAccumulator()
        return true
    }

    private static func processOtherFingers() {
        guard startTime != nil else { return }
        endGesture()
        clearEventState()
        startTime = nil
    }

    private static func resetAccumulator() {
        accVelX = 0
    }

    private static func clearEventState() {
        accVelX = 0
        prevTouchPositions.removeAll()
        lastEventTimestamp = nil
    }

    private static func startOrContinueGesture() {
        if accVelX < 0 {
            AppSwitcher.cmdShiftTab()
        } else {
            AppSwitcher.cmdTab()
        }
    }

    private static func endGesture() {
        AppSwitcher.selectInAppSwitcher()
    }

    // MARK: Touch Velocity Calculation

    /// Records the current position of each active touch for velocity calculation on the next frame.
    private static func updateTouchPositions(touches: Set<NSTouch>) {
        for touch in touches {
            if touch.phase == .ended {
                prevTouchPositions.removeValue(forKey: "\(touch.identity)")
            } else {
                prevTouchPositions["\(touch.identity)"] = touch.normalizedPosition
            }
        }
    }

    /// Computes the average horizontal swipe velocity across all touches.
    /// Returns `nil` if fingers are moving in different directions or if vertical movement dominates.
    private static func horizontalSwipeVelocity(touches: Set<NSTouch>) -> Float? {
        var allRight = true
        var allLeft = true
        var sumVelX: Float = 0
        var sumVelY: Float = 0
        
        for touch in touches {
            let (velX, velY) = touchVelocity(touch)
            allRight = allRight && velX >= 0
            allLeft = allLeft && velX <= 0
            sumVelX += velX
            sumVelY += velY
        }
        
        guard allRight || allLeft else { return nil }

        let velX = sumVelX / Float(touches.count)
        let velY = sumVelY / Float(touches.count)
        guard abs(velX) > abs(velY) else { return nil }

        return velX
    }
    
    /// Returns the per-frame velocity delta for a single touch by comparing against its previous position.
    private static func touchVelocity(_ touch: NSTouch) -> (Float, Float) {
        guard let prevPosition = prevTouchPositions["\(touch.identity)"] else {
            return (0, 0)
        }
        let position = touch.normalizedPosition
        return (Float(position.x - prevPosition.x), Float(position.y - prevPosition.y))
    }
}

// MARK: - Default Settings Constants

enum DefaultSettings {
    /// Default swipe sensitivity threshold (lower = more sensitive).
    static let accVelXThreshold: Double = 0.045
    /// Default debounce delay between consecutive app switches.
    static let appSwitcherUIDelay: Double = 0.150
    /// Default gesture acceleration factor (1.0 = moderate acceleration).
    static let gestureAcceleration: Double = 0.5
    /// Whether the menu bar icon is visible by default.
    static let showMenuBarIcon = true
    /// Scales normalized speed (units/second) into a perceivable acceleration range.
    static let accelSpeedScale: Double = 0.83
}

// MARK: - Persisted Settings

@Observable
class Settings {
    static let shared = Settings()

    /// Minimum accumulated velocity to trigger an app switch. Lower = more sensitive.
    var accVelXThreshold: Double {
        didSet { UserDefaults.standard.set(accVelXThreshold, forKey: "accVelXThreshold") }
    }

    /// Debounce interval (seconds) between consecutive app switches.
    var appSwitcherUIDelay: Double {
        didSet { UserDefaults.standard.set(appSwitcherUIDelay, forKey: "appSwitcherUIDelay") }
    }

    /// Multiplier for dynamic gesture acceleration (0 = linear, higher = more aggressive).
    var gestureAcceleration: Double {
        didSet { UserDefaults.standard.set(gestureAcceleration, forKey: "gestureAcceleration") }
    }

    /// Whether the app should launch automatically at login.
    var isLaunchAtLoginEnabled: Bool {
        didSet {
            guard isLaunchAtLoginEnabled != oldValue else { return }
            let service = SMAppService.mainApp
            do {
                if isLaunchAtLoginEnabled {
                    if service.status != .enabled { try service.register() }
                } else {
                    if service.status == .enabled { try service.unregister() }
                }
            } catch {
                debugPrint("Failed to set launch status: \(error)")
                // Sync back to the actual system state without re-triggering didSet.
                let actual = service.status == .enabled
                if actual != isLaunchAtLoginEnabled {
                    isLaunchAtLoginEnabled = actual
                }
            }
        }
    }

    /// Whether the status bar icon is visible.
    var showMenuBarIcon: Bool {
        didSet { UserDefaults.standard.set(showMenuBarIcon, forKey: "showMenuBarIcon") }
    }

    private init() {
        // 1. Register defaults first so all keys have a baseline
        UserDefaults.standard.register(defaults: [
            "accVelXThreshold": DefaultSettings.accVelXThreshold,
            "appSwitcherUIDelay": DefaultSettings.appSwitcherUIDelay,
            "gestureAcceleration": DefaultSettings.gestureAcceleration,
            "showMenuBarIcon": DefaultSettings.showMenuBarIcon
        ])

        // 2. One-time migration: velocityMultiplier → gestureAcceleration
        if UserDefaults.standard.object(forKey: "gestureAcceleration") == nil,
           let oldVal = UserDefaults.standard.object(forKey: "velocityMultiplier") as? Double {
            let clamped = min(max(oldVal, 0.0), 5.0)
            UserDefaults.standard.set(clamped, forKey: "gestureAcceleration")
            UserDefaults.standard.removeObject(forKey: "velocityMultiplier")
        }

        // 3. Load persisted values
        self.accVelXThreshold = UserDefaults.standard.double(forKey: "accVelXThreshold")
        self.appSwitcherUIDelay = UserDefaults.standard.double(forKey: "appSwitcherUIDelay")
        self.gestureAcceleration = UserDefaults.standard.double(forKey: "gestureAcceleration")
        self.showMenuBarIcon = UserDefaults.standard.bool(forKey: "showMenuBarIcon")
        self.isLaunchAtLoginEnabled = SMAppService.mainApp.status == .enabled
    }

    func resetToDefaults() {
        accVelXThreshold = DefaultSettings.accVelXThreshold
        appSwitcherUIDelay = DefaultSettings.appSwitcherUIDelay
        gestureAcceleration = DefaultSettings.gestureAcceleration
        showMenuBarIcon = DefaultSettings.showMenuBarIcon
    }
}
