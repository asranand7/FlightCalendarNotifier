import SwiftUI

struct SetupView: View {
    let calendarManager: CalendarManager
    let settingsManager: SettingsManager
    let onTestFlight: () -> Void
    
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
    @State private var todoistToken: String = ""
    @State private var todoistStatus: String = "Disconnected"
    @State private var isVerifyingTodoist: Bool = false
    
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
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            SecureField("API Token", text: $todoistToken)
                                .textFieldStyle(PlainTextFieldStyle())
                                .font(.system(size: 11))
                                .padding(6)
                                .background(Color.black.opacity(0.3))
                                .cornerRadius(5)
                                .foregroundColor(.white)
                            
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
                                .foregroundColor(todoistStatus == "Connected" ? .green : (todoistStatus == "Disconnected" || todoistStatus == "Token Required" ? .white.opacity(0.6) : .red))
                            
                            if !todoistToken.isEmpty && todoistStatus == "Connected" {
                                Spacer()
                                Button("Disconnect") {
                                    todoistToken = ""
                                    settingsManager.setTodoistToken("")
                                    todoistStatus = "Token Required"
                                    NotificationCenter.default.post(name: Notification.Name("TodoistTokenChanged"), object: nil)
                                }
                                .font(.system(size: 9))
                                .foregroundColor(.red.opacity(0.8))
                                .buttonStyle(.plain)
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
            todoistToken = settingsManager.todoistToken()
            todoistStatus = todoistToken.isEmpty ? "Token Required" : "Connected"
            
            if isCalendarEnabled {
                checkPermission()
            } else {
                calendarStatus = "Disabled"
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
    
    func verifyTodoistToken() {
        guard !todoistToken.isEmpty else {
            todoistStatus = "Token Required"
            return
        }
        isVerifyingTodoist = true
        todoistStatus = "Verifying..."
        
        let tManager = TodoistManager()
        tManager.fetchTasks(token: todoistToken) { tasks, error in
            DispatchQueue.main.async {
                isVerifyingTodoist = false
                if error != nil {
                    todoistStatus = "Invalid Token / Error"
                } else {
                    todoistStatus = "Connected"
                    settingsManager.setTodoistToken(todoistToken)
                    NotificationCenter.default.post(name: Notification.Name("TodoistTokenChanged"), object: nil)
                }
            }
        }
    }
}
