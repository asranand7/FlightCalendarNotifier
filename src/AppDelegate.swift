import AppKit
import SwiftUI
import ServiceManagement

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusBarItem: NSStatusItem!
    let calendarManager = CalendarManager()
    let settingsManager = SettingsManager()
    let todoistManager = TodoistManager()
    var timer: Timer?
    var todoistTimer: Timer?
    var activeWindows: [NSWindow] = []
    var window: NSWindow!
    
    // Store triggered thresholds: eventIdentifier -> Set of intervals (e.g. [10, 5])
    var triggeredEvents: [String: Set<Int>] = [:]
    
    // Store fetched Todoist tasks
    var cachedTodoistTasks: [TodoistTask] = []
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Always keep Flyby registered to launch at login
        enableLaunchAtLogin()

        // Initialize the menu bar UI
        setupMenuBar()
        
        // Open setup window in foreground
        let windowFrame = NSRect(x: 100, y: 100, width: 760, height: 560)
        window = NSWindow(
            contentRect: windowFrame,
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.title = "Flyby"
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.isOpaque = false
        window.backgroundColor = .clear
        window.isReleasedWhenClosed = false
        // Observe window close to hide dock icon
        NotificationCenter.default.addObserver(self, selector: #selector(windowDidClose), name: NSWindow.willCloseNotification, object: nil)
        window.contentView = NSHostingView(rootView: SetupView(
            calendarManager: calendarManager,
            settingsManager: settingsManager,
            onTestFlight: { [weak self] platform in
                self?.testAnimationWith(platform: platform)
            },
            onSyncTodoist: { [weak self] completion in
                self?.fetchTodoistTasks(completion: completion)
            }
        ))
        window.center()
        window.makeKeyAndOrderFront(nil)
        
        print("🚀 Flight Notifier started!")
        
        // Force the app to activate (foreground focus)
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        
        // Register for settings/token changes
        NotificationCenter.default.addObserver(self, selector: #selector(handleSettingsChanged), name: Notification.Name("TodoistTokenChanged"), object: nil)
        
        // Register for system wake to restart timers that stall during sleep
        NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(handleSystemWake), name: NSWorkspace.didWakeNotification, object: nil)
        
        // Start timers conditionally based on settings
        if settingsManager.isCalendarEnabled() {
            calendarManager.requestAccess { [weak self] granted in
                print("🔑 Calendar access request completed. Granted: \(granted)")
                DispatchQueue.main.async {
                    self?.updateMenu()
                    NotificationCenter.default.post(name: Notification.Name("CalendarAccessChanged"), object: nil)
                    if granted {
                        self?.startTimer()
                    } else if self?.settingsManager.isTodoistEnabled() == true {
                        // Calendar access denied but Todoist is on — still need the polling loop
                        self?.startTimer()
                    }
                }
            }
        } else if settingsManager.isTodoistEnabled() {
            // Calendar disabled but Todoist is on — start polling loop for Todoist
            startTimer()
            updateMenu()
        } else {
            updateMenu()
        }

        if settingsManager.isTodoistEnabled() {
            startTodoistTimer()
        }
    }
    
    func setupMenuBar() {
        statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusBarItem.button {
            button.image = NSImage(systemSymbolName: "airplane.circle", accessibilityDescription: "Flight Notifier")
        }
        updateMenu()
    }
    
    func updateMenu() {
        let menu = NSMenu()
        
        // App header
        let titleItem = NSMenuItem(title: "✨ Flyby", action: nil, keyEquivalent: "")
        titleItem.isEnabled = false
        menu.addItem(titleItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Display Next Meeting Label (Python Bridge manages access)
        let statusItem = NSMenuItem(title: "📅 Next meeting: Checking...", action: nil, keyEquivalent: "")
        statusItem.isEnabled = false
        menu.addItem(statusItem)
        updateNextMeetingLabel(statusItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Test button
        let testItem = NSMenuItem(title: "Test Flight Animation", action: #selector(testAnimation), keyEquivalent: "t")
        testItem.target = self
        menu.addItem(testItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Preferences header
        let prefHeader = NSMenuItem(title: "Alert Intervals:", action: nil, keyEquivalent: "")
        prefHeader.isEnabled = false
        menu.addItem(prefHeader)
        
        // Alert thresholds configuration (checkboxes)
        let thresholds = [30, 15, 10, 5, 2, 1]
        for threshold in thresholds {
            let item = NSMenuItem(
                title: "  \(threshold) minutes before",
                action: #selector(toggleThreshold(_:)),
                keyEquivalent: ""
            )
            item.target = self
            item.tag = threshold
            item.state = settingsManager.isThresholdEnabled(threshold) ? .on : .off
            menu.addItem(item)
        }
        
        menu.addItem(NSMenuItem.separator())
        
        // Open Settings
        let settingsItem = NSMenuItem(title: "Open Settings…", action: #selector(openSettings), keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(settingsItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Quit
        let quitItem = NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
        
        statusBarItem.menu = menu
    }
    
    @objc func requestAccessAgain() {
        calendarManager.requestAccess { [weak self] granted in
            DispatchQueue.main.async {
                self?.updateMenu()
                if granted {
                    self?.startTimer()
                }
            }
        }
    }
    
    @objc func toggleThreshold(_ sender: NSMenuItem) {
        let threshold = sender.tag
        let isEnabled = settingsManager.isThresholdEnabled(threshold)
        settingsManager.setThreshold(threshold, enabled: !isEnabled)
        updateMenu()
    }
    
    @objc func testAnimation() {
        testAnimationWith(platform: nil)
    }

    func testAnimationWith(platform: String?) {
        let isTodoist = platform == "Todoist"
        showFlightAnimation(
            meetingTitle: isTodoist ? "Finish project proposal" : "Project Review Meeting",
            minutesRemaining: 10,
            startDate: Date(),
            endDate: isTodoist ? nil : Date().addingTimeInterval(30 * 60),
            platform: isTodoist ? "Todoist" : (platform ?? "Google Meet"),
            meetingUrl: isTodoist ? "https://todoist.com/app/task/12345" : "https://meet.google.com/abc-defg-hij"
        )
    }
    
    @objc func openSettings() {
        window.makeKeyAndOrderFront(nil)
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc func windowDidClose(_ notification: Notification) {
        guard let closedWindow = notification.object as? NSWindow, closedWindow === window else { return }
        // Hide dock icon when settings window is closed — app lives in menu bar only
        NSApp.setActivationPolicy(.accessory)
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        // When the user opens Flyby from Spotlight/Finder while it's already running
        if !flag {
            openSettings()
        }
        return true
    }

    @objc func quitApp() {
        NSApplication.shared.terminate(nil)
    }

    func enableLaunchAtLogin() {
        guard SMAppService.mainApp.status != .enabled else { return }
        do {
            try SMAppService.mainApp.register()
            print("✅ Registered Flyby to launch at login")
        } catch {
            print("⚠️ Could not register login item: \(error.localizedDescription)")
        }
    }
    
    func startTimer() {
        print("⏱️ Starting background calendar polling timer (interval: 10s)")
        timer?.invalidate()
        let t = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { [weak self] _ in
            self?.checkCalendarForUpcomingMeetings()
        }
        RunLoop.current.add(t, forMode: .common)
        timer = t
        checkCalendarForUpcomingMeetings()
    }
    
    func updateNextMeetingLabel(_ menuItem: NSMenuItem) {
        if !settingsManager.isCalendarEnabled() {
            menuItem.title = "📅 Reminders: Open Setup to Enable"
            return
        }
        calendarManager.fetchNextUpcomingEvent { event in
            DispatchQueue.main.async {
                if let event = event {
                    let title = event.title
                    let startDate = event.startDate
                    let diff = Int(round(startDate.timeIntervalSinceNow / 60.0))
                    if diff > 0 {
                        menuItem.title = "📅 Next: \(title) (in \(diff)m)"
                    } else if diff == 0 {
                        menuItem.title = "📅 Next: \(title) (starting now)"
                    } else {
                        menuItem.title = "📅 Next: \(title) (started \(abs(diff))m ago)"
                    }
                } else {
                    menuItem.title = "📅 No more meetings scheduled today"
                }
            }
        }
    }
    
    func checkCalendarForUpcomingMeetings() {
        let now = Date()
        let calendarThresholds = self.settingsManager.calendarThresholds()
        let todoistThresholds = self.settingsManager.todoistThresholds()
        
        // 1. Process Calendar Events (if enabled)
        if settingsManager.isCalendarEnabled() {
            print("📅 Polling calendar for upcoming meetings...")
            calendarManager.fetchUpcomingEvents { [weak self] events in
                guard let self = self else { return }
                
                print("🔍 Found \(events.count) upcoming events in the next 45 minutes:")
                for event in events {
                    print("   - [\(event.title)] starting at \(event.startDate)")
                }
                
                DispatchQueue.main.async {
                    if let menu = self.statusBarItem.menu, menu.items.count > 2 {
                        let nextMeetingItem = menu.items[2]
                        self.updateNextMeetingLabel(nextMeetingItem)
                    }
                }
                
                let activeEventIds = Set(events.compactMap { $0.eventIdentifier })
                
                DispatchQueue.main.async {
                    let keysToRemove = self.triggeredEvents.keys.filter { !$0.hasPrefix("todoist_") && !activeEventIds.contains($0) }
                    for key in keysToRemove {
                        print("🧹 Clearing triggered memory for old calendar event ID: \(key)")
                        self.triggeredEvents.removeValue(forKey: key)
                    }
                    
                    for event in events {
                        let eventId = event.eventIdentifier
                        let startDate = event.startDate
                        
                        let diffInSeconds = startDate.timeIntervalSince(now)
                        let diffInMinutes = Int(round(diffInSeconds / 60.0))
                        print("     * Event [\(event.title)] starting in \(diffInMinutes)m (exact diff: \(Int(diffInSeconds))s)")
                        
                        for threshold in calendarThresholds {
                            let thresholdSeconds = Double(threshold) * 60.0
                            let withinWindow = diffInSeconds > 0 && abs(diffInSeconds - thresholdSeconds) <= 45
                            if withinWindow {
                                var triggeredSet = self.triggeredEvents[eventId] ?? Set<Int>()
                                if !triggeredSet.contains(threshold) {
                                    print("🔔 Triggering \(threshold)-minute notification for [\(event.title)]!")
                                    triggeredSet.insert(threshold)
                                    self.triggeredEvents[eventId] = triggeredSet
                                    self.showFlightAnimation(
                                        meetingTitle: event.title,
                                        minutesRemaining: threshold,
                                        startDate: event.startDate,
                                        endDate: event.endDate,
                                        platform: event.platform,
                                        meetingUrl: event.url
                                    )
                                    self.settingsManager.addNotificationEntry(
                                        title: event.title,
                                        source: "Calendar",
                                        threshold: threshold
                                    )
                                }
                            }
                        }
                    }
                }
            }
        } else {
            // Update next meeting label to disabled state
            DispatchQueue.main.async {
                if let menu = self.statusBarItem.menu, menu.items.count > 2 {
                    let nextMeetingItem = menu.items[2]
                    self.updateNextMeetingLabel(nextMeetingItem)
                }
            }
        }
        
        // 2. Process Todoist Tasks (if enabled and cached)
        if settingsManager.isTodoistEnabled() {
            // Clean up triggered keys for Todoist tasks that are no longer in the cache
            let activeTaskIds = Set(cachedTodoistTasks.map { "todoist_\($0.id)" })
            let keysToRemove = triggeredEvents.keys.filter { $0.hasPrefix("todoist_") && !activeTaskIds.contains($0) }
            for key in keysToRemove {
                print("🧹 Clearing triggered memory for old Todoist task ID: \(key)")
                triggeredEvents.removeValue(forKey: key)
            }
            
            for task in cachedTodoistTasks {
                guard let dueDate = task.due?.parsedDate else { continue }
                
                let diffInSeconds = dueDate.timeIntervalSince(now)
                
                let eventId = "todoist_\(task.id)"
                
                for threshold in todoistThresholds {
                    let thresholdSeconds = Double(threshold) * 60.0
                    let withinWindow = diffInSeconds > 0 && abs(diffInSeconds - thresholdSeconds) <= 45
                    
                    if withinWindow {
                        var triggeredSet = self.triggeredEvents[eventId] ?? Set<Int>()
                        if !triggeredSet.contains(threshold) {
                            print("🔔 Triggering \(threshold)-minute Todoist notification for [\(task.content)]!")
                            triggeredSet.insert(threshold)
                            self.triggeredEvents[eventId] = triggeredSet
                            
                            self.showFlightAnimation(
                                meetingTitle: task.content,
                                minutesRemaining: threshold,
                                startDate: dueDate,
                                endDate: nil, // Tasks do not have an end time
                                platform: "Todoist",
                                meetingUrl: task.url
                            )
                            self.settingsManager.addNotificationEntry(
                                title: task.content,
                                source: "Todoist",
                                threshold: threshold
                            )
                        }
                    }
                }
            }
        }
    }

    @objc func handleSystemWake() {
        print("☀️ System woke from sleep")
        
        // Restart the calendar polling timer (it stalls during sleep)
        if settingsManager.isCalendarEnabled() || settingsManager.isTodoistEnabled() {
            if timer != nil {
                print("   ↻ Restarting calendar polling timer")
                startTimer()
            }
        }
        
        // Check if Todoist sync is overdue and re-sync immediately
        if settingsManager.isTodoistEnabled() {
            let interval = TimeInterval(settingsManager.todoistSyncInterval())
            let lastSync = settingsManager.lastTodoistSync()
            let elapsed = lastSync.map { Date().timeIntervalSince($0) } ?? .infinity
            
            if elapsed >= interval {
                print("   ↻ Todoist sync overdue (last sync \(Int(elapsed))s ago, interval \(Int(interval))s). Syncing now...")
                fetchTodoistTasks()
            } else {
                print("   ✓ Todoist sync still within interval (last sync \(Int(elapsed))s ago)")
            }
            
            // Always restart the Todoist timer so it counts from now, not from pre-sleep
            print("   ↻ Restarting Todoist sync timer")
            startTodoistTimer()
        }
    }

    @objc func handleSettingsChanged() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.updateMenu()
            
            let calendarOn = self.settingsManager.isCalendarEnabled()
            let todoistOn  = self.settingsManager.isTodoistEnabled()

            if calendarOn {
                if self.timer == nil {
                    self.calendarManager.requestAccess { granted in
                        DispatchQueue.main.async {
                            if granted || todoistOn { self.startTimer() }
                        }
                    }
                }
            } else {
                // Clear calendar-triggered events
                let keysToRemove = self.triggeredEvents.keys.filter { !$0.hasPrefix("todoist_") }
                for key in keysToRemove { self.triggeredEvents.removeValue(forKey: key) }

                if !todoistOn {
                    // Nothing needs the polling loop anymore
                    self.timer?.invalidate()
                    self.timer = nil
                } else if self.timer == nil {
                    // Calendar off but Todoist still on — keep/start polling
                    self.startTimer()
                }
            }

            if todoistOn {
                self.startTodoistTimer()
                if self.timer == nil { self.startTimer() }
            } else {
                self.todoistTimer?.invalidate()
                self.todoistTimer = nil
                self.cachedTodoistTasks.removeAll()
                let keysToRemove = self.triggeredEvents.keys.filter { $0.hasPrefix("todoist_") }
                for key in keysToRemove { self.triggeredEvents.removeValue(forKey: key) }
                if !calendarOn {
                    self.timer?.invalidate()
                    self.timer = nil
                }
            }
        }
    }
    
    func startTodoistTimer() {
        let interval = TimeInterval(settingsManager.todoistSyncInterval())
        print("⏱️ Starting Todoist caching timer (interval: \(Int(interval))s)")
        todoistTimer?.invalidate()
        let t = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            self?.fetchTodoistTasks()
        }
        RunLoop.current.add(t, forMode: .common)
        todoistTimer = t
        fetchTodoistTasks()
    }
    
    func fetchTodoistTasks(completion: ((Int?, Error?) -> Void)? = nil) {
        let token = settingsManager.todoistToken()
        guard !token.isEmpty && settingsManager.isTodoistEnabled() else {
            completion?(nil, nil)
            return
        }
        print("📥 Fetching Todoist tasks for cache...")
        todoistManager.fetchTasks(token: token) { [weak self] tasks, error in
            guard let self = self else { return }
            if let error = error {
                print("⚠️ Todoist fetch failed: \(error.localizedDescription)")
                DispatchQueue.main.async { completion?(nil, error) }
            } else if let tasks = tasks {
                print("✅ Todoist cache updated: found \(tasks.count) timed tasks")
                self.cachedTodoistTasks = tasks
                self.settingsManager.setLastTodoistSync(Date())
                DispatchQueue.main.async {
                    completion?(tasks.count, nil)
                    NotificationCenter.default.post(name: Notification.Name("TodoistSyncCompleted"), object: nil)
                }
            }
        }
    }
    
    func showFlightAnimation(meetingTitle: String, minutesRemaining: Int, startDate: Date?, endDate: Date?, platform: String?, meetingUrl: String?) {
        print("🎬 showFlightAnimation triggered! Title: '\(meetingTitle)', minutesRemaining: \(minutesRemaining)")
        
        // Play notification sound if enabled
        if settingsManager.isSoundEnabled() {
            let soundName = settingsManager.soundType()
            if let sound = NSSound(named: NSSound.Name(soundName)) {
                sound.play()
                print("🔊 Playing sound: \(soundName)")
            }
        }
        // Detect active screen (screen containing the mouse cursor)
        let mouseLocation = NSEvent.mouseLocation
        let targetScreen = NSScreen.screens.first { NSMouseInRect(mouseLocation, $0.frame, false) }
            ?? NSScreen.main
            ?? NSScreen.screens.first
        
        guard let screen = targetScreen else { return }
        
        let screenFrame = screen.frame
        print("   * Target Screen Frame: \(screenFrame), Mouse Location: \(mouseLocation)")
        let cardWidth = CGFloat(settingsManager.bannerWidth())
        let cardHeight = CGFloat(settingsManager.bannerHeight())
        
        let hasPlatform = (platform != nil)
        let platformStubWidth: CGFloat = hasPlatform ? 112 : 0
        let paddingAndPlaneWidth: CGFloat = 145 // plane, spacing, details padding, divider, offsets, safety buffer
        let windowWidth = cardWidth + platformStubWidth + paddingAndPlaneWidth
        let windowHeight = cardHeight + 50.0 // safety buffer for vertical bobbing and shadow
        
        // Position based on user preference
        let position = settingsManager.bannerPosition()
        let windowY: CGFloat
        switch position {
        case "middle":
            windowY = screenFrame.minY + (screenFrame.height - windowHeight) / 2
        case "bottom":
            windowY = screenFrame.minY + 30
        default: // top
            windowY = screenFrame.minY + screenFrame.height - windowHeight - 70
        }
        
        // Start position: off-screen left
        let startX = screenFrame.minX - windowWidth
        let endX = screenFrame.minX + screenFrame.width
        
        let rect = NSRect(
            x: startX,
            y: windowY,
            width: windowWidth,
            height: windowHeight
        )
        
        let overlayPanel = FlightOverlayPanel(contentRect: rect, screen: screen)
        overlayPanel.ignoresMouseEvents = false // Let clicks pass inside the window!
        
        // Setup flight speed duration
        let speed = settingsManager.flightSpeed()
        var duration: Double = 8.0
        if speed == "slow" { duration = 12.0 }
        else if speed == "fast" { duration = 5.0 }
        
        let fps: Double = 60.0
        let totalSteps = Int(duration * fps)
        var currentStep = 0
        
        var isPaused = false
        var timerReference: Timer? = nil
        
        let animView = FlightAnimationView(
            eventTitle: meetingTitle,
            minutesRemaining: minutesRemaining,
            screenWidth: windowWidth,
            bannerWidth: cardWidth,
            bannerHeight: cardHeight,
            flightSpeedName: settingsManager.flightSpeed(),
            cardBgName: settingsManager.cardBackground(),
            fontColorName: settingsManager.textColor(),
            startDate: startDate,
            endDate: endDate,
            platform: platform,
            meetingUrl: meetingUrl,
            animationThemeName: settingsManager.animationTheme(),
            onClose: { [weak self, weak overlayPanel] in
                DispatchQueue.main.async {
                    timerReference?.invalidate()
                    if let panel = overlayPanel {
                        panel.close()
                        self?.activeWindows.removeAll { $0 === panel }
                    }
                }
            },
            onHoverEnter: {
                isPaused = true
                print("⏸️ Mouse hover entered: Pausing flight animation")
            },
            onHoverExit: {
                isPaused = false
                print("▶️ Mouse hover exited: Resuming flight animation")
            }
        )
        
        let hostingView = NSHostingView(rootView: animView)
        hostingView.wantsLayer = true
        hostingView.layer?.masksToBounds = false
        overlayPanel.contentView = hostingView
        
        activeWindows.append(overlayPanel)
        overlayPanel.orderFrontRegardless()
        
        // Animate the window X coordinate horizontally
        let animTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / fps, repeats: true) { animTimer in
            if isPaused { return }
            currentStep += 1
            let progress = CGFloat(currentStep) / CGFloat(totalSteps)
            
            if currentStep % 60 == 0 || currentStep == 1 {
                print("   [Animation Progress] Step \(currentStep)/\(totalSteps) (\(Int(progress * 100))%), current x: \(startX + progress * (endX - startX))")
            }
            
            if progress >= 1.0 {
                print("🏁 Animation finished! Closing panel.")
                animTimer.invalidate()
                DispatchQueue.main.async {
                    overlayPanel.close()
                    self.activeWindows.removeAll { $0 === overlayPanel }
                }
            } else {
                let x = startX + progress * (endX - startX)
                overlayPanel.setFrameOrigin(NSPoint(x: x, y: windowY))
            }
        }
        RunLoop.current.add(animTimer, forMode: .common)
        timerReference = animTimer
    }
}
