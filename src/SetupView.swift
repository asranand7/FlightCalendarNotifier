import SwiftUI

struct SetupView: View {
    let calendarManager: CalendarManager
    let settingsManager: SettingsManager
    let onTestFlight: () -> Void
    let onSyncTodoist: (@escaping (Int?, Error?) -> Void) -> Void
    
    @State private var calendarStatus: String = "Checking..."
    @State private var isAuthorized: Bool = false
    @State private var bannerWidth: Double = 230.0
    @State private var bannerHeight: Double = 76.0
    @State private var selectedSpeed: String = "medium"
    @State private var selectedBg: String = "#20222C"
    @State private var selectedText: String = "#FFFFFF"
    @State private var selectedTheme: String = "airplane"
    @State private var customEmoji: String = ""
    @State private var selectedPosition: String = "top"
    @State private var customBgColor: Color = Color(hex: "#20222C")
    @State private var customTextColor: Color = Color(hex: "#FFFFFF")
    
    @State private var isCalendarEnabled: Bool = false
    @State private var isTodoistEnabled: Bool = false
    @State private var calendarThresholds: Set<Int> = []
    @State private var todoistThresholds: Set<Int> = []
    @State private var todoistToken: String = ""
    @State private var todoistStatus: String = "Disconnected"
    @State private var isVerifyingTodoist: Bool = false
    @State private var isSyncingTodoist: Bool = false
    @State private var lastSyncResult: String = ""
    @State private var verifyManager: TodoistManager? = nil
    @State private var isEditingToken: Bool = false
    
    var body: some View {
        VStack(spacing: 14) {
            // Header
            VStack(spacing: 3) {
                Text("✨ Flyby")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                Text("Animated Meeting Reminders")
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.6))
            }
            .padding(.top, 6)
            
            // Permissions Panel
            VStack(alignment: .leading, spacing: 8) {
                Text("System Permissions")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white.opacity(0.8))
                
                HStack {
                    Text("Calendar Access:")
                        .font(.system(size: 11.5))
                        .foregroundColor(.white.opacity(0.7))
                    Spacer()
                    Text(calendarStatus)
                        .font(.system(size: 11.5, weight: .bold))
                        .foregroundColor(isAuthorized ? .green : .orange)
                        .onTapGesture {
                            if !isAuthorized {
                                requestPermission()
                            }
                        }
                }
            }
            .padding(10)
            .background(Color.white.opacity(0.04))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.white.opacity(0.06), lineWidth: 1)
            )
            
            // Reminder Sources Panel
            VStack(alignment: .leading, spacing: 10) {
                Text("Reminder Sources")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white.opacity(0.8))
                
                Toggle("Enable Calendar Reminders", isOn: $isCalendarEnabled)
                    .font(.system(size: 11.5))
                    .foregroundColor(.white.opacity(0.75))
                    .toggleStyle(SwitchToggleStyle(tint: .amber))
                    .onChange(of: isCalendarEnabled) {
                        settingsManager.setCalendarEnabled(isCalendarEnabled)
                        if isCalendarEnabled {
                            requestPermission()
                        } else {
                            calendarStatus = "Disabled"
                        }
                        NotificationCenter.default.post(name: Notification.Name("TodoistTokenChanged"), object: nil)
                    }

                if isCalendarEnabled {
                    thresholdPicker(label: "Calendar alerts:", selected: $calendarThresholds) { newVal in
                        settingsManager.setCalendarThresholds(Array(newVal))
                    }
                }

                Divider().background(Color.white.opacity(0.05))

                Toggle("Enable Todoist Reminders", isOn: $isTodoistEnabled)
                    .font(.system(size: 11.5))
                    .foregroundColor(.white.opacity(0.75))
                    .toggleStyle(SwitchToggleStyle(tint: .amber))
                    .onChange(of: isTodoistEnabled) {
                        settingsManager.setTodoistEnabled(isTodoistEnabled)
                        if !isTodoistEnabled {
                            todoistStatus = "Disconnected"
                            NotificationCenter.default.post(name: Notification.Name("TodoistTokenChanged"), object: nil)
                        } else {
                            todoistStatus = todoistToken.isEmpty ? "Token Required" : "Connected"
                            NotificationCenter.default.post(name: Notification.Name("TodoistTokenChanged"), object: nil)
                        }
                    }
                
                if isTodoistEnabled {
                    VStack(alignment: .leading, spacing: 8) {
                        if todoistStatus == "Connected" && !isEditingToken {
                            // Saved token state — no need to re-enter
                            HStack {
                                Text("●●●●●●●●●●●●●●●●")
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundColor(.white.opacity(0.4))
                                Spacer()
                                Button("Change") {
                                    isEditingToken = true
                                    todoistToken = ""
                                }
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(.white.opacity(0.6))
                                .buttonStyle(.plain)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 6)
                            .background(Color.black.opacity(0.2))
                            .cornerRadius(6)

                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                    .font(.system(size: 10))
                                Text("Connected")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.green)
                                Spacer()
                                Button("Disconnect") {
                                    todoistToken = ""
                                    settingsManager.setTodoistToken("")
                                    todoistStatus = "Token Required"
                                    lastSyncResult = ""
                                    isEditingToken = false
                                    NotificationCenter.default.post(name: Notification.Name("TodoistTokenChanged"), object: nil)
                                }
                                .font(.system(size: 9))
                                .foregroundColor(.red.opacity(0.8))
                                .buttonStyle(.plain)
                            }

                            // Sync row
                            HStack(spacing: 8) {
                                if isSyncingTodoist {
                                    ProgressView().scaleEffect(0.5).frame(width: 16, height: 16)
                                    Text("Syncing...")
                                        .font(.system(size: 10))
                                        .foregroundColor(.white.opacity(0.5))
                                } else {
                                    Button(action: syncTodoistTasks) {
                                        HStack(spacing: 4) {
                                            Image(systemName: "arrow.clockwise")
                                                .font(.system(size: 9, weight: .bold))
                                            Text("Sync Now")
                                                .font(.system(size: 10, weight: .semibold))
                                        }
                                        .foregroundColor(.black)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 4)
                                        .background(Color.amber)
                                        .cornerRadius(5)
                                    }
                                    .buttonStyle(.plain)

                                    if !lastSyncResult.isEmpty {
                                        Text(lastSyncResult)
                                            .font(.system(size: 10))
                                            .foregroundColor(.white.opacity(0.5))
                                    }
                                }
                            }

                            thresholdPicker(label: "Todoist alerts:", selected: $todoistThresholds) { newVal in
                                settingsManager.setTodoistThresholds(Array(newVal))
                            }

                        } else {
                            // Input mode — enter / change token
                            HStack {
                                SecurePasteField(placeholder: "Paste API token", text: $todoistToken)
                                    .padding(5)
                                    .background(Color.black.opacity(0.3))
                                    .cornerRadius(5)
                                    .frame(height: 24)

                                if isVerifyingTodoist {
                                    ProgressView().scaleEffect(0.5).frame(width: 20, height: 20)
                                } else {
                                    Button("Verify") {
                                        verifyTodoistToken()
                                    }
                                    .font(.system(size: 10, weight: .bold))
                                    .buttonStyle(.plain)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.amber)
                                    .foregroundColor(.black)
                                    .cornerRadius(4)
                                }
                            }

                            HStack {
                                Text("Status: ")
                                    .font(.system(size: 10))
                                    .foregroundColor(.white.opacity(0.5))
                                Text(todoistStatus)
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(todoistStatus.hasPrefix("Error") || todoistStatus.hasPrefix("Invalid") || todoistStatus.hasPrefix("Network") ? .red : .white.opacity(0.6))

                                if isEditingToken {
                                    Spacer()
                                    Button("Cancel") {
                                        todoistToken = settingsManager.todoistToken()
                                        todoistStatus = "Connected"
                                        isEditingToken = false
                                    }
                                    .font(.system(size: 9))
                                    .foregroundColor(.white.opacity(0.5))
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                    .padding(.top, 4)
                }
            }
            .padding(10)
            .background(Color.white.opacity(0.04))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.white.opacity(0.06), lineWidth: 1)
            )
            
            // Flight Customization Panel
            VStack(alignment: .leading, spacing: 10) {
                Text("Flight Customization")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white.opacity(0.8))
                
                // Theme selector
                VStack(alignment: .leading, spacing: 8) {
                    Text("Animation Theme:")
                        .font(.system(size: 11.5))
                        .foregroundColor(.white.opacity(0.7))
                    // Row 1
                    HStack(spacing: 10) {
                        themeButton(key: "airplane", label: "Plane") {
                            themePreviewImage("airplane", fallback: "✈️")
                        }
                        themeButton(key: "f1car", label: "F1 Car") {
                            themePreviewImage("f1car", fallback: "🏎️")
                        }
                        themeButton(key: "motorbike", label: "Moto") {
                            themePreviewImage("motorbike", fallback: "🏍️")
                        }
                        themeButton(key: "locomotive", label: "Train") {
                            themePreviewImage("locomotive", fallback: "🚂")
                        }
                    }
                    // Row 2
                    HStack(spacing: 10) {
                        themeButton(key: "helicopter", label: "Heli") {
                            themePreviewImage("helicopter", fallback: "🚁")
                        }
                        themeButton(key: "rocket", label: "Rocket") {
                            themePreviewImage("rocket", fallback: "🚀")
                        }
                        themeButton(key: "dinosaur", label: "Dino") {
                            Text("🦕").font(.system(size: 28))
                        }
                        themeButton(key: "emoji:\(customEmoji)", label: "Custom") {
                            Text("✏️").font(.system(size: 24))
                        }
                    }

                    if selectedTheme.hasPrefix("emoji:") {
                        HStack(spacing: 6) {
                            TextField("Paste emoji", text: $customEmoji)
                                .font(.system(size: 20))
                                .frame(width: 50)
                                .onChange(of: customEmoji) { newVal in
                                    let trimmed = String(newVal.prefix(1))
                                    if trimmed != newVal { customEmoji = trimmed }
                                    let theme = "emoji:\(trimmed)"
                                    selectedTheme = theme
                                    settingsManager.setAnimationTheme(theme)
                                }
                            Text("← type any single emoji")
                                .font(.system(size: 10))
                                .foregroundColor(.white.opacity(0.4))
                        }
                    }
                }
                       Divider().background(Color.white.opacity(0.05))

                // Dimension Sliders
                VStack(spacing: 8) {
                    HStack {
                        Text("Banner Width:")
                            .font(.system(size: 11.5))
                            .foregroundColor(.white.opacity(0.7))
                        Spacer()
                        Text("\(Int(bannerWidth)) px")
                            .font(.system(size: 11.5, weight: .bold))
                            .foregroundColor(.white.opacity(0.9))
                    }
                    Slider(value: $bannerWidth, in: 160...400, step: 5)
                        .onChange(of: bannerWidth) {
                            settingsManager.setBannerWidth(bannerWidth)
                        }
                    
                    HStack {
                        Text("Banner Height:")
                            .font(.system(size: 11.5))
                            .foregroundColor(.white.opacity(0.7))
                        Spacer()
                        Text("\(Int(bannerHeight)) px")
                            .font(.system(size: 11.5, weight: .bold))
                            .foregroundColor(.white.opacity(0.9))
                    }
                    Slider(value: $bannerHeight, in: 50...120, step: 2)
                        .onChange(of: bannerHeight) {
                            settingsManager.setBannerHeight(bannerHeight)
                        }
                }
                
                Divider().background(Color.white.opacity(0.05))
                
                // Speed selector
                HStack {
                    Text("Flight Speed:")
                        .font(.system(size: 11.5))
                        .foregroundColor(.white.opacity(0.7))
                    Spacer()
                    HStack(spacing: 5) {
                        ForEach(["slow", "medium", "fast"], id: \.self) { speedName in
                            Button(action: {
                                selectedSpeed = speedName
                                settingsManager.setFlightSpeed(speedName)
                            }) {
                                Text(speedName.capitalized)
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundColor(selectedSpeed == speedName ? .black : .white.opacity(0.7))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(selectedSpeed == speedName ? Color.amber : Color.white.opacity(0.06))
                                    .cornerRadius(4)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                
                Divider().background(Color.white.opacity(0.05))

                // Banner position selector
                HStack {
                    Text("Banner Position:")
                        .font(.system(size: 11.5))
                        .foregroundColor(.white.opacity(0.7))
                    Spacer()
                    HStack(spacing: 5) {
                        ForEach([("top", "▲ Top"), ("middle", "● Middle"), ("bottom", "▼ Bottom")], id: \.0) { (pos, label) in
                            Button(action: {
                                selectedPosition = pos
                                settingsManager.setBannerPosition(pos)
                            }) {
                                Text(label)
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundColor(selectedPosition == pos ? .black : .white.opacity(0.7))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(selectedPosition == pos ? Color.amber : Color.white.opacity(0.06))
                                    .cornerRadius(4)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                Divider().background(Color.white.opacity(0.05))

                // Card Background selector (Solid options + ColorPicker)
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Card Background:")
                            .font(.system(size: 11.5))
                            .foregroundColor(.white.opacity(0.7))
                        Spacer()
                        ColorPicker("", selection: $customBgColor)
                            .labelsHidden()
                            .onChange(of: customBgColor) {
                                if let hex = customBgColor.toHex() {
                                    selectedBg = hex
                                    settingsManager.setCardBackground(hex)
                                }
                            }
                    }
                    
                    HStack(spacing: 5) {
                        ForEach([
                            ("#20222C", "DARK"),
                            ("#F8F8F8", "LIGHT"),
                            ("#FFC0CB", "PINK"),
                            ("#FFB300", "AMBER"),
                            ("#0F1E4B", "BLUE"),
                            ("#2ECC71", "GREEN")
                        ], id: \.0) { (hex, label) in
                            Button(action: {
                                selectedBg = hex
                                customBgColor = Color(hex: hex)
                                settingsManager.setCardBackground(hex)
                            }) {
                                Text(label)
                                    .font(.system(size: 9, weight: .semibold))
                                    .foregroundColor(selectedBg == hex ? .black : .white.opacity(0.7))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(selectedBg == hex ? Color.amber : Color.white.opacity(0.06))
                                    .cornerRadius(4)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                
                Divider().background(Color.white.opacity(0.05))
                
                // Text Color selector (Solid options + ColorPicker)
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Text Color:")
                            .font(.system(size: 11.5))
                            .foregroundColor(.white.opacity(0.7))
                        Spacer()
                        ColorPicker("", selection: $customTextColor)
                            .labelsHidden()
                            .onChange(of: customTextColor) {
                                if let hex = customTextColor.toHex() {
                                    selectedText = hex
                                    settingsManager.setTextColor(hex)
                                }
                            }
                    }
                    
                    HStack(spacing: 5) {
                        ForEach([
                            ("#FFFFFF", "WHITE"),
                            ("#000000", "BLACK"),
                            ("#FFEB3B", "YELLOW"),
                            ("#FFB300", "AMBER"),
                            ("#FFC0CB", "PINK")
                        ], id: \.0) { (hex, label) in
                            Button(action: {
                                selectedText = hex
                                customTextColor = Color(hex: hex)
                                settingsManager.setTextColor(hex)
                            }) {
                                Text(label)
                                    .font(.system(size: 9, weight: .semibold))
                                    .foregroundColor(selectedText == hex ? .black : .white.opacity(0.7))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(selectedText == hex ? Color.amber : Color.white.opacity(0.06))
                                    .cornerRadius(4)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding(12)
            .background(Color.white.opacity(0.04))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.white.opacity(0.06), lineWidth: 1)
            )
            
            // Test Button
            Button(action: onTestFlight) {
                HStack(spacing: 6) {
                    Image(systemName: "play.fill")
                        .font(.system(size: 12, weight: .bold))
                    Text("Test Animation")
                        .font(.system(size: 11.5, weight: .semibold))
                }
                .foregroundColor(.black)
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
                .background(Color.amber)
                .cornerRadius(8)
                .shadow(color: Color.amber.opacity(0.2), radius: 5, x: 0, y: 2)
            }
            .buttonStyle(.plain)
            .padding(.vertical, 2)
            
            // Help description
            Text("Click on the 'Join' button on the banner as it flies to directly launch your Zoom/Meet link. You can also click 'X' to dismiss it instantly.")
                .font(.system(size: 9))
                .foregroundColor(.white.opacity(0.4))
                .multilineTextAlignment(.center)
                .lineSpacing(2)
                .padding(.horizontal, 8)
                .padding(.bottom, 4)
        }
        .padding(14)
        .frame(width: 400, height: 720)
        .background(Color(red: 25/255, green: 25/255, blue: 35/255))
        .onAppear {
            bannerWidth = settingsManager.bannerWidth()
            bannerHeight = settingsManager.bannerHeight()
            selectedSpeed = settingsManager.flightSpeed()
            selectedBg = settingsManager.cardBackground()
            selectedText = settingsManager.textColor()
            customBgColor = Color(hex: selectedBg)
            customTextColor = Color(hex: selectedText)
            let theme = settingsManager.animationTheme()
            selectedTheme = theme
            if theme.hasPrefix("emoji:") {
                customEmoji = String(theme.dropFirst(6))
            }
            selectedPosition = settingsManager.bannerPosition()
            
            isCalendarEnabled = settingsManager.isCalendarEnabled()
            isTodoistEnabled = settingsManager.isTodoistEnabled()
            calendarThresholds = Set(settingsManager.calendarThresholds())
            todoistThresholds = Set(settingsManager.todoistThresholds())
            todoistToken = settingsManager.todoistToken()
            let hasToken = !todoistToken.isEmpty
            todoistStatus = hasToken ? "Connected" : "Token Required"
            isEditingToken = !hasToken
            
            if isCalendarEnabled {
                checkPermission()
            } else {
                calendarStatus = "Disabled"
            }
        }
    }
    
    @ViewBuilder
    func thresholdPicker(label: String, selected: Binding<Set<Int>>, onChange: @escaping (Set<Int>) -> Void) -> some View {
        let all = [1, 2, 5, 10, 15, 30]
        VStack(alignment: .leading, spacing: 5) {
            Text(label)
                .font(.system(size: 10))
                .foregroundColor(.white.opacity(0.5))
            HStack(spacing: 5) {
                ForEach(all, id: \.self) { mins in
                    let isOn = selected.wrappedValue.contains(mins)
                    Button(action: {
                        var updated = selected.wrappedValue
                        if isOn { updated.remove(mins) } else { updated.insert(mins) }
                        selected.wrappedValue = updated
                        onChange(updated)
                    }) {
                        Text("\(mins)m")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(isOn ? .black : .white.opacity(0.5))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(isOn ? Color.amber : Color.white.opacity(0.06))
                            .cornerRadius(4)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    @ViewBuilder
    func themePreviewImage(_ name: String, fallback: String) -> some View {
        if let path = Bundle.main.path(forResource: name, ofType: "png"),
           let img = NSImage(contentsOfFile: path) {
            Image(nsImage: img)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 34, height: 34)
        } else {
            Text(fallback).font(.system(size: 26))
        }
    }

    @ViewBuilder
    func themeButton<Content: View>(key: String, label: String, @ViewBuilder content: () -> Content) -> some View {
        let isSelected = selectedTheme == key || (key.hasPrefix("emoji:") && selectedTheme.hasPrefix("emoji:"))
        Button(action: {
            selectedTheme = key
            settingsManager.setAnimationTheme(key)
        }) {
            VStack(spacing: 4) {
                content()
                    .frame(width: 40, height: 40)
                Text(label)
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundColor(isSelected ? .black : .white.opacity(0.6))
            }
            .padding(6)
            .background(isSelected ? Color.amber.opacity(0.9) : Color.white.opacity(0.06))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.amber : Color.clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }

    func checkPermission() {
        let authorized = calendarManager.isCalendarAuthorized()
        isAuthorized = authorized
        calendarStatus = authorized ? "Granted" : "Denied / Tap to Request"
    }
    
    func requestPermission() {
        calendarManager.requestAccess { granted in
            DispatchQueue.main.async {
                isAuthorized = granted
                calendarStatus = granted ? "Granted" : "Denied"
            }
        }
    }
    
    func syncTodoistTasks() {
        isSyncingTodoist = true
        lastSyncResult = ""
        onSyncTodoist { count, error in
            isSyncingTodoist = false
            if let error = error {
                lastSyncResult = "Sync failed: \(error.localizedDescription)"
            } else if let count = count {
                let now = Date()
                let formatter = DateFormatter()
                formatter.dateFormat = "h:mm a"
                lastSyncResult = "\(count) task\(count == 1 ? "" : "s") at \(formatter.string(from: now))"
            }
        }
    }

    func verifyTodoistToken() {
        guard !todoistToken.isEmpty else {
            todoistStatus = "Token Required"
            return
        }
        isVerifyingTodoist = true
        todoistStatus = "Verifying..."

        let manager = TodoistManager()
        verifyManager = manager  // retain until callback fires
        manager.fetchTasks(token: todoistToken) { tasks, error in
            DispatchQueue.main.async {
                isVerifyingTodoist = false
                verifyManager = nil
                if let error = error {
                    let code = (error as NSError).code
                    if code == 401 || code == 403 {
                        todoistStatus = "Invalid token"
                    } else if code == NSURLErrorTimedOut || code == NSURLErrorNotConnectedToInternet {
                        todoistStatus = "Network error — check connection"
                    } else {
                        todoistStatus = "Error \(code): \((error as NSError).localizedDescription)"
                    }
                } else {
                    todoistStatus = "Connected"
                    isEditingToken = false
                    settingsManager.setTodoistToken(todoistToken)
                    NotificationCenter.default.post(name: Notification.Name("TodoistTokenChanged"), object: nil)
                }
            }
        }
    }
}

struct SecurePasteField: NSViewRepresentable {
    let placeholder: String
    @Binding var text: String
    
    func makeNSView(context: Context) -> NSSecureTextField {
        let textField = PasteSecureTextField()
        textField.placeholderString = placeholder
        textField.isBordered = false
        textField.drawsBackground = false
        textField.delegate = context.coordinator
        textField.focusRingType = .none
        textField.textColor = .white
        textField.font = NSFont.systemFont(ofSize: 11)
        return textField
    }
    
    func updateNSView(_ nsView: NSSecureTextField, context: Context) {
        if nsView.stringValue != text {
            nsView.stringValue = text
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, NSTextFieldDelegate {
        var parent: SecurePasteField
        
        init(_ parent: SecurePasteField) {
            self.parent = parent
        }
        
        func controlTextDidChange(_ obj: Notification) {
            if let textField = obj.object as? NSTextField {
                parent.text = textField.stringValue
            }
        }
    }
}

class PasteSecureTextField: NSSecureTextField {
    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        if flags == .command {
            switch event.charactersIgnoringModifiers {
            case "x":
                if let editor = self.currentEditor() {
                    editor.cut(nil)
                    return true
                }
            case "c":
                if let editor = self.currentEditor() {
                    editor.copy(nil)
                    return true
                }
            case "v":
                if let editor = self.currentEditor() {
                    editor.paste(nil)
                    return true
                }
            case "a":
                if let editor = self.currentEditor() {
                    editor.selectAll(nil)
                    return true
                }
            default:
                break
            }
        }
        return super.performKeyEquivalent(with: event)
    }
}
