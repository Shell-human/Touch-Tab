import Cocoa
import Observation
import ServiceManagement

enum AppSwitcher {
    private static let keyboardEventSource = CGEventSource(stateID: .hidSystemState)
    private static let tabKey: CGKeyCode = 0x30
    private static let leftCommandKey: CGKeyCode = 0x37

    static func selectInAppSwitcher() {
        postKeyEvent(key: leftCommandKey, down: false)
    }

    static func cmdTab() {
        postKeyEvent(key: tabKey, down: true, flags: .maskCommand)
        postKeyEvent(key: tabKey, down: false, flags: .maskCommand)
    }

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

enum SwipeManager {
    private static var accVelXThreshold: Float { Settings.shared.accVelXThreshold }
    private static var appSwitcherUIDelay: Double { Settings.shared.appSwitcherUIDelay }

    private static var eventTap: CFMachPort? = nil
    private static var accVelX: Float = 0
    private static var prevTouchPositions: [String: NSPoint] = [:]
    private static var startTime: Date? = nil

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
            alert.messageText = NSLocalizedString("Accessibility Permission Required", comment: "")
            alert.informativeText = NSLocalizedString("Touch-Tab needs Accessibility permission to detect trackpad gestures. Please authorize it in System Settings.", comment: "")
            alert.alertStyle = .warning
            alert.addButton(withTitle: NSLocalizedString("Open System Settings", comment: ""))
            alert.addButton(withTitle: NSLocalizedString("Cancel", comment: ""))
            
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
            return processThreeFingers(touches: touches)
        default:
            processOtherFingers()
            return false
        }
    }

    private static func processThreeFingers(touches: Set<NSTouch>) -> Bool {
        guard let velX = horizontalSwipeVelocity(touches: touches) else {
            return false
        }

        accVelX += velX * Settings.shared.velocityMultiplier
        if abs(accVelX) < accVelXThreshold {
            return true
        }

        if startTime == nil {
            startTime = Date()
        } else {
            let interval = startTime!.timeIntervalSinceNow
            if -interval < appSwitcherUIDelay {
                clearEventState()
                return true
            }
        }

        startOrContinueGesture()
        clearEventState()
        return true
    }

    private static func processOtherFingers() {
        if startTime != nil {
            endGesture()
            clearEventState()
            startTime = nil
        }
    }

    private static func clearEventState() {
        accVelX = 0
        prevTouchPositions.removeAll()
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

            if touch.phase == .ended {
                prevTouchPositions.removeValue(forKey: "\(touch.identity)")
            } else {
                prevTouchPositions["\(touch.identity)"] = touch.normalizedPosition
            }
        }
        
        guard allRight || allLeft else { return nil }

        let velX = sumVelX / Float(touches.count)
        let velY = sumVelY / Float(touches.count)
        guard abs(velX) > abs(velY) else { return nil }

        return velX
    }
    
    private static func touchVelocity(_ touch: NSTouch) -> (Float, Float) {
        guard let prevPosition = prevTouchPositions["\(touch.identity)"] else {
            return (0, 0)
        }
        let position = touch.normalizedPosition
        return (Float(position.x - prevPosition.x), Float(position.y - prevPosition.y))
    }
}

@Observable
class Settings {
    static let shared = Settings()

    var accVelXThreshold: Float {
        didSet { UserDefaults.standard.set(accVelXThreshold, forKey: "accVelXThreshold") }
    }

    var appSwitcherUIDelay: Double {
        didSet { UserDefaults.standard.set(appSwitcherUIDelay, forKey: "appSwitcherUIDelay") }
    }

    var velocityMultiplier: Float {
        didSet { UserDefaults.standard.set(velocityMultiplier, forKey: "velocityMultiplier") }
    }

    var isLaunchAtLoginEnabled: Bool {
        didSet {
            let service = SMAppService.mainApp
            do {
                if isLaunchAtLoginEnabled {
                    if service.status != .enabled { try service.register() }
                } else {
                    if service.status == .enabled { try service.unregister() }
                }
            } catch {
                debugPrint("Failed to set launch status: \(error)")
                isLaunchAtLoginEnabled = service.status == .enabled
            }
        }
    }

    var showMenuBarIcon: Bool {
        didSet { UserDefaults.standard.set(showMenuBarIcon, forKey: "showMenuBarIcon") }
    }

    private init() {
        UserDefaults.standard.register(defaults: [
            "accVelXThreshold": Float(0.035),
            "appSwitcherUIDelay": Double(0.125),
            "velocityMultiplier": Float(1.0),
            "showMenuBarIcon": true
        ])
        self.accVelXThreshold = UserDefaults.standard.float(forKey: "accVelXThreshold")
        self.appSwitcherUIDelay = UserDefaults.standard.double(forKey: "appSwitcherUIDelay")
        self.velocityMultiplier = UserDefaults.standard.float(forKey: "velocityMultiplier")
        self.showMenuBarIcon = UserDefaults.standard.bool(forKey: "showMenuBarIcon")
        self.isLaunchAtLoginEnabled = SMAppService.mainApp.status == .enabled
    }

    func resetToDefaults() {
        accVelXThreshold = 0.035
        appSwitcherUIDelay = 0.125
        velocityMultiplier = 1.0
        showMenuBarIcon = true
    }
}
