import SwiftUI
import ServiceManagement
import UniformTypeIdentifiers

enum SettingsSection: String, CaseIterable, Identifiable {
    case general = "General"
    case integrations = "Integrations"
    case reminders = "Reminders"
    case appearance = "Appearance"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .general: return "gearshape"
        case .integrations: return "puzzlepiece.extension"
        case .reminders: return "bell.badge"
        case .appearance: return "paintbrush.pointed"
        }
    }
}

struct SetupView: View {
    let calendarManager: CalendarManager
    let settingsManager: SettingsManager
    let onTestFlight: (String?) -> Void
    let onSyncTodoist: (@escaping (Int?, Error?) -> Void) -> Void

    @State private var selection: SettingsSection? = .general

    @State private var launchAtLogin: Bool = false
    @State private var calendarStatus: String = "Checking..."
    @State private var isAuthorized: Bool = false
    @State private var bannerWidth: Double = 230.0
    @State private var bannerHeight: Double = 76.0
    @State private var selectedSpeed: String = "medium"
    @State private var selectedBg: String = "#20222C"
    @State private var selectedText: String = "#FFFFFF"
    @State private var selectedTheme: String = "airplane"
    @State private var customEmoji: String = ""
    @State private var customImagePath: String? = nil
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
    @State private var lastAutoSync: Date? = nil
    @State private var todoistSyncInterval: Int = 300
    @State private var isSoundEnabled: Bool = true
    @State private var selectedSoundType: String = "Glass"

    private let syncIntervalOptions: [(label: String, seconds: Int)] = [
        ("1 min",  60),
        ("2 min",  120),
        ("5 min",  300),
        ("10 min", 600),
        ("15 min", 900),
        ("30 min", 1800),
    ]
    @State private var verifyManager: TodoistManager? = nil
    @State private var isEditingToken: Bool = false

    private let thresholdOptions = [1, 2, 5, 10, 15, 30]
    private let soundTypeOptions = ["Basso", "Blow", "Bottle", "Frog", "Funk", "Glass", "Hero", "Morse", "Ping", "Pop", "Purr", "Sosumi", "Submarine", "Tink"]
    private let bgPresets: [(String, String)] = [
        ("#20222C", "Dark"), ("#F8F8F8", "Light"), ("#FFC0CB", "Pink"),
        ("#FFB300", "Amber"), ("#0F1E4B", "Blue"), ("#2ECC71", "Green")
    ]
    private let textPresets: [(String, String)] = [
        ("#FFFFFF", "White"), ("#000000", "Black"), ("#FFEB3B", "Yellow"),
        ("#FFB300", "Amber"), ("#FFC0CB", "Pink")
    ]

    var body: some View {
        NavigationSplitView {
            List(selection: $selection) {
                Section("Flyby") {
                    ForEach(SettingsSection.allCases) { section in
                        Label(section.rawValue, systemImage: section.icon)
                            .tag(section)
                    }
                }
            }
            .navigationSplitViewColumnWidth(min: 180, ideal: 196, max: 230)
        } detail: {
            detailPane
                .background(
                    VisualEffectBackground(material: .underWindowBackground, blendingMode: .behindWindow)
                        .ignoresSafeArea()
                )
                .navigationTitle(selection?.rawValue ?? "Flyby")
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Button { onTestFlight(nil) } label: {
                            Label("Test Animation", systemImage: "play.fill")
                        }
                    }
                }
        }
        .frame(minWidth: 720, idealWidth: 780, minHeight: 540, idealHeight: 600)
        .onAppear {
            loadSettings()
            NotificationCenter.default.addObserver(forName: Notification.Name("TodoistSyncCompleted"),
                                                   object: nil, queue: .main) { _ in
                lastAutoSync = settingsManager.lastTodoistSync()
            }
            NotificationCenter.default.addObserver(forName: Notification.Name("CalendarAccessChanged"),
                                                   object: nil, queue: .main) { _ in
                checkPermission()
            }
        }
    }

    // MARK: - Detail panes

    @ViewBuilder
    private var detailPane: some View {
        switch selection ?? .general {
        case .general: generalPane
        case .integrations: integrationsPane
        case .reminders: remindersPane
        case .appearance: appearancePane
        }
    }

    private var generalPane: some View {
        paneScroll {
            glassCard(title: "Startup", footer: "Keep Flyby running in the background and start it automatically when you log in.") {
                Toggle("Launch at Login", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { setLaunchAtLogin(launchAtLogin) }
            }

            glassCard(title: "About") {
                infoRow("Application", "Flyby")
                infoRow("Tagline", "Animated Meeting Reminders")
                infoRow("Version", Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown")
            }
        }
    }

    private var integrationsPane: some View {
        paneScroll {
            // Calendar integration
            glassCard(footer: "Flyby reads upcoming events from macOS Calendar to fly a reminder across your screen before each meeting.") {
                integrationHeader(icon: "calendar", title: "Calendar", subtitle: "macOS Calendar (iCloud, Google, Exchange)", isOn: $isCalendarEnabled) {
                    settingsManager.setCalendarEnabled(isCalendarEnabled)
                    if isCalendarEnabled {
                        requestPermission()
                    } else {
                        calendarStatus = "Disabled"
                    }
                    NotificationCenter.default.post(name: Notification.Name("TodoistTokenChanged"), object: nil)
                }

                if isCalendarEnabled {
                    Divider().opacity(0.4)
                    HStack {
                        Text("Permission")
                        Spacer()
                        Label(isAuthorized ? "Granted" : "Not Granted",
                              systemImage: isAuthorized ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                            .foregroundStyle(isAuthorized ? .green : .orange)
                            .fontWeight(.medium)
                        if !isAuthorized {
                            Button("Grant…") { requestPermission() }
                                .buttonStyle(.borderedProminent)
                        }
                    }
                    Divider().opacity(0.4)
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Preview")
                            Text("See how a Calendar meeting banner looks")
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Button { onTestFlight("Google Meet") } label: {
                            Label("Test Banner", systemImage: "play.fill")
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
            }

            // Todoist integration
            glassCard(footer: "Create your API token at todoist.com → Settings → Integrations → Developer.") {
                integrationHeader(icon: "todoist", title: "Todoist", subtitle: "Timed tasks via the Todoist API", isOn: $isTodoistEnabled) {
                    settingsManager.setTodoistEnabled(isTodoistEnabled)
                    if !isTodoistEnabled {
                        todoistStatus = "Disconnected"
                    } else {
                        todoistStatus = todoistToken.isEmpty ? "Token Required" : "Connected"
                        isEditingToken = todoistToken.isEmpty
                    }
                    NotificationCenter.default.post(name: Notification.Name("TodoistTokenChanged"), object: nil)
                }

                if isTodoistEnabled {
                    todoistContent
                }
            }
        }
        .animation(.smooth(duration: 0.3), value: isCalendarEnabled)
        .animation(.smooth(duration: 0.3), value: isTodoistEnabled)
        .animation(.smooth(duration: 0.3), value: isEditingToken)
        .animation(.smooth(duration: 0.3), value: todoistStatus)
        .animation(.smooth(duration: 0.3), value: isAuthorized)
    }

    private var remindersPane: some View {
        paneScroll {
            if !isCalendarEnabled && !isTodoistEnabled {
                glassCard {
                    HStack(spacing: 10) {
                        Image(systemName: "puzzlepiece.extension")
                            .foregroundStyle(.secondary)
                        Text("Enable a source in **Integrations** to choose when you’re reminded.")
                            .foregroundStyle(.secondary)
                        Spacer(minLength: 0)
                    }
                }
            }

            if isCalendarEnabled {
                glassCard {
                    integrationLabel(icon: "calendar", title: "Calendar")
                    Divider().opacity(0.4)
                    thresholdRow(label: "Alert intervals", selected: $calendarThresholds) { updated in
                        settingsManager.setCalendarThresholds(Array(updated))
                    }
                }
            }

            if isTodoistEnabled {
                glassCard {
                    integrationLabel(icon: "todoist", title: "Todoist")
                    Divider().opacity(0.4)
                    thresholdRow(label: "Alert intervals", selected: $todoistThresholds) { updated in
                        settingsManager.setTodoistThresholds(Array(updated))
                    }
                }
            }

            glassCard(title: "Sound", footer: "Play a system sound when a reminder banner flies across the screen.") {
                Toggle("Enable Sound", isOn: $isSoundEnabled)
                    .onChange(of: isSoundEnabled) { settingsManager.setSoundEnabled(isSoundEnabled) }
                if isSoundEnabled {
                    Divider().opacity(0.4)
                    HStack {
                        Text("Sound Type")
                        Spacer()
                        Picker("", selection: $selectedSoundType) {
                            ForEach(soundTypeOptions, id: \.self) { name in
                                Text(name).tag(name)
                            }
                        }
                        .labelsHidden()
                        .frame(width: 130)
                        .onChange(of: selectedSoundType) {
                            settingsManager.setSoundType(selectedSoundType)
                        }
                        Button {
                            if let sound = NSSound(named: NSSound.Name(selectedSoundType)) {
                                sound.play()
                            }
                        } label: {
                            Image(systemName: "speaker.wave.2.fill")
                        }
                        .buttonStyle(.bordered)
                    }
                }
            }
            .animation(.smooth(duration: 0.3), value: isSoundEnabled)
        }
        .animation(.smooth(duration: 0.3), value: isCalendarEnabled)
        .animation(.smooth(duration: 0.3), value: isTodoistEnabled)
    }

    @ViewBuilder
    private var todoistContent: some View {
        Divider().opacity(0.4)

        if todoistStatus == "Connected" && !isEditingToken {
            HStack {
                Text("API Token")
                Spacer()
                Text("••••••••••••").foregroundStyle(.secondary)
                Button("Change") {
                    isEditingToken = true
                    todoistToken = ""
                }
                .buttonStyle(.bordered)
            }

            HStack {
                Text("Status")
                Spacer()
                Label("Connected", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .fontWeight(.medium)
            }

            HStack {
                Text("Sync Interval")
                Spacer()
                Picker("", selection: $todoistSyncInterval) {
                    ForEach(syncIntervalOptions, id: \.seconds) { option in
                        Text(option.label).tag(option.seconds)
                    }
                }
                .labelsHidden()
                .frame(width: 100)
                .onChange(of: todoistSyncInterval) {
                    settingsManager.setTodoistSyncInterval(todoistSyncInterval)
                    NotificationCenter.default.post(name: Notification.Name("TodoistTokenChanged"), object: nil)
                }
            }

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Last Synced")
                    if let date = lastAutoSync {
                        Text(date, style: .relative)
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    } else {
                        Text("Never")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                if isSyncingTodoist {
                    ProgressView().controlSize(.small)
                    Text("Syncing…").foregroundStyle(.secondary)
                } else {
                    if !lastSyncResult.isEmpty {
                        Text(lastSyncResult).font(.callout).foregroundStyle(.secondary)
                    }
                    Button {
                        syncTodoistTasks()
                    } label: {
                        Label("Sync Now", systemImage: "arrow.clockwise")
                    }
                    .buttonStyle(.bordered)
                }
            }

            Divider().opacity(0.4)
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Preview")
                    Text("See how a Todoist task banner looks")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button { onTestFlight("Todoist") } label: {
                    Label("Test Banner", systemImage: "play.fill")
                }
                .buttonStyle(.borderedProminent)
            }

            Divider().opacity(0.4)
            HStack {
                Spacer()
                Button("Disconnect", role: .destructive) {
                    todoistToken = ""
                    settingsManager.setTodoistToken("")
                    todoistStatus = "Token Required"
                    lastSyncResult = ""
                    isEditingToken = true
                    NotificationCenter.default.post(name: Notification.Name("TodoistTokenChanged"), object: nil)
                }
                .buttonStyle(.bordered)
            }
        } else {
            HStack {
                Text("API Token")
                Spacer()
                SecurePasteField(placeholder: "Paste token", text: $todoistToken)
                    .frame(width: 190, height: 22)
                if isVerifyingTodoist {
                    ProgressView().controlSize(.small)
                } else {
                    Button("Verify") { verifyTodoistToken() }
                        .buttonStyle(.borderedProminent)
                }
            }

            HStack {
                Text("Status")
                Spacer()
                Text(todoistStatus)
                    .foregroundStyle(statusIsError ? .red : .secondary)
            }

            if !settingsManager.todoistToken().isEmpty && isEditingToken {
                HStack {
                    Spacer()
                    Button("Cancel") {
                        todoistToken = settingsManager.todoistToken()
                        todoistStatus = "Connected"
                        isEditingToken = false
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
    }

    private var statusIsError: Bool {
        todoistStatus.hasPrefix("Error") || todoistStatus.hasPrefix("Invalid") || todoistStatus.hasPrefix("Network")
    }

    private var appearancePane: some View {
        paneScroll {
            glassCard(title: "Animation Theme") {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 4), spacing: 12) {
                    themeButton(key: "airplane", label: "Plane") { themePreviewImage("airplane", fallback: "✈️") }
                    themeButton(key: "f1car", label: "F1 Car") { themePreviewImage("f1car", fallback: "🏎️") }
                    themeButton(key: "motorbike", label: "Moto") { themePreviewImage("motorbike", fallback: "🏍️") }
                    themeButton(key: "locomotive", label: "Train") { themePreviewImage("locomotive", fallback: "🚂") }
                    themeButton(key: "helicopter", label: "Heli") { themePreviewImage("helicopter", fallback: "🚁") }
                    themeButton(key: "rocket", label: "Rocket") { themePreviewImage("rocket", fallback: "🚀") }
                    themeButton(key: "snoopy", label: "Snoopy") { themePreviewImage("snoopy", fallback: "🐕") }
                    themeButton(key: "bluecat", label: "Blue Cat") { themePreviewImage("bluecat", fallback: "🐱") }
                    themeButton(key: "goldendog", label: "Doggo") { themePreviewImage("goldendog", fallback: "🐶") }
                    themeButton(key: "elephant", label: "Elephant") { themePreviewImage("elephant", fallback: "🐘") }
                    themeButton(key: "penguin", label: "Penguin") { themePreviewImage("penguin", fallback: "🐧") }
                    themeButton(key: "dragon", label: "Dragon") { themePreviewImage("dragon", fallback: "🐉") }
                    themeButton(key: "unicorn", label: "Unicorn") { themePreviewImage("unicorn", fallback: "🦄") }
                    themeButton(key: "superhero", label: "Hero") { themePreviewImage("superhero", fallback: "🦸") }
                    themeButton(key: "superman", label: "Superman") { themePreviewImage("superman", fallback: "🦸‍♂️") }
                    themeButton(key: "webslinger", label: "Spidey") { themePreviewImage("webslinger", fallback: "🕷️") }
                    themeButton(key: "cartman", label: "Cart") { themePreviewImage("cartman", fallback: "🛒") }
                    themeButton(key: "rickshaw", label: "Rickshaw") { themePreviewImage("rickshaw", fallback: "🛺") }
                    themeButton(key: "modiji", label: "Modi") { themePreviewImage("modiji", fallback: "🇮🇳") }
                    themeButton(key: "nirmala", label: "Nirmala") { themePreviewImage("nirmala", fallback: "🏛️") }
                    themeButton(key: "rahul", label: "Rahul") { themePreviewImage("rahul", fallback: "✋") }
                    themeButton(key: "trump", label: "Trump") { themePreviewImage("trump", fallback: "🇺🇸") }
                    themeButton(key: "wonderwoman", label: "WonderW") { themePreviewImage("wonderwoman", fallback: "🦸‍♀️") }
                    themeButton(key: "thor", label: "Thor") { themePreviewImage("thor", fallback: "⚡") }
                    themeButton(key: "dinosaur", label: "Dino") { Text("🦕").font(.system(size: 28)) }
                    themeButton(key: "emoji:\(customEmoji)", label: "Emoji") { Text("✏️").font(.system(size: 24)) }
                    customImageTile()
                }

                if selectedTheme.hasPrefix("emoji:") {
                    Divider().opacity(0.4)
                    HStack {
                        Text("Custom Emoji")
                        Spacer()
                        TextField("Paste emoji", text: $customEmoji)
                            .font(.system(size: 20))
                            .frame(width: 70)
                            .multilineTextAlignment(.center)
                            .textFieldStyle(.roundedBorder)
                            .onChange(of: customEmoji) {
                                let trimmed = String(customEmoji.prefix(1))
                                if trimmed != customEmoji { customEmoji = trimmed }
                                let theme = "emoji:\(trimmed)"
                                selectedTheme = theme
                                settingsManager.setAnimationTheme(theme)
                            }
                    }
                }
            }

            glassCard(title: "Banner Size") {
                sliderRow(label: "Width", value: $bannerWidth, range: 160...400, step: 5, unit: "px") {
                    settingsManager.setBannerWidth(bannerWidth)
                }
                Divider().opacity(0.4)
                sliderRow(label: "Height", value: $bannerHeight, range: 50...120, step: 2, unit: "px") {
                    settingsManager.setBannerHeight(bannerHeight)
                }
            }

            glassCard(title: "Motion") {
                HStack {
                    Text("Flight Speed")
                    Spacer()
                    Picker("", selection: $selectedSpeed) {
                        Text("Slow").tag("slow")
                        Text("Medium").tag("medium")
                        Text("Fast").tag("fast")
                    }
                    .labelsHidden()
                    .pickerStyle(.segmented)
                    .frame(width: 240)
                    .onChange(of: selectedSpeed) { settingsManager.setFlightSpeed(selectedSpeed) }
                }
                Divider().opacity(0.4)
                HStack {
                    Text("Banner Position")
                    Spacer()
                    Picker("", selection: $selectedPosition) {
                        Text("Top").tag("top")
                        Text("Middle").tag("middle")
                        Text("Bottom").tag("bottom")
                    }
                    .labelsHidden()
                    .pickerStyle(.segmented)
                    .frame(width: 240)
                    .onChange(of: selectedPosition) { settingsManager.setBannerPosition(selectedPosition) }
                }
            }

            glassCard(title: "Colors", footer: "Click ‘Join’ or ‘Open’ on the banner to launch the meeting or task. Click ‘X’ to dismiss it.") {
                HStack {
                    ColorPicker("Card Background", selection: $customBgColor)
                        .onChange(of: customBgColor) {
                            if let hex = customBgColor.toHex() {
                                selectedBg = hex
                                settingsManager.setCardBackground(hex)
                            }
                        }
                    Spacer()
                    swatchRow(presets: bgPresets, selectedHex: selectedBg) { hex in
                        selectedBg = hex
                        customBgColor = Color(hex: hex)
                        settingsManager.setCardBackground(hex)
                    }
                }
                Divider().opacity(0.4)
                HStack {
                    ColorPicker("Text Color", selection: $customTextColor)
                        .onChange(of: customTextColor) {
                            if let hex = customTextColor.toHex() {
                                selectedText = hex
                                settingsManager.setTextColor(hex)
                            }
                        }
                    Spacer()
                    swatchRow(presets: textPresets, selectedHex: selectedText) { hex in
                        selectedText = hex
                        customTextColor = Color(hex: hex)
                        settingsManager.setTextColor(hex)
                    }
                }
            }
        }
    }

    // MARK: - Layout helpers

    @ViewBuilder
    private func paneScroll<C: View>(@ViewBuilder content: () -> C) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                content()
            }
            .padding(28)
            .frame(maxWidth: 680, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
    }

    @ViewBuilder
    private func glassCard<C: View>(title: String? = nil, footer: String? = nil, @ViewBuilder content: () -> C) -> some View {
        VStack(alignment: .leading, spacing: 9) {
            if let title {
                Text(title)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                    .tracking(0.5)
                    .padding(.leading, 6)
            }
            VStack(alignment: .leading, spacing: 14) {
                content()
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.primary.opacity(0.07), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.07), radius: 12, x: 0, y: 5)
            if let footer {
                Text(footer)
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
                    .padding(.horizontal, 6)
            }
        }
    }

    @ViewBuilder
    private func infoRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
            Spacer()
            Text(value).foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private func integrationIcon(_ name: String, size: CGFloat) -> some View {
        if let path = Bundle.main.path(forResource: name, ofType: "png"),
           let img = NSImage(contentsOfFile: path) {
            Image(nsImage: img)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: size, height: size)
        } else {
            Image(systemName: "app.dashed")
                .font(.system(size: size * 0.7))
                .foregroundStyle(.secondary)
                .frame(width: size, height: size)
        }
    }

    @ViewBuilder
    private func integrationHeader(icon: String, title: String, subtitle: String, isOn: Binding<Bool>, onChange: @escaping () -> Void) -> some View {
        HStack(spacing: 12) {
            integrationIcon(icon, size: 36)
            VStack(alignment: .leading, spacing: 1) {
                Text(title).font(.system(size: 14, weight: .semibold))
                Text(subtitle).font(.system(size: 11)).foregroundStyle(.secondary)
            }
            Spacer()
            Toggle("", isOn: isOn)
                .labelsHidden()
                .onChange(of: isOn.wrappedValue) { onChange() }
        }
    }

    @ViewBuilder
    private func integrationLabel(icon: String, title: String) -> some View {
        HStack(spacing: 10) {
            integrationIcon(icon, size: 22)
            Text(title).font(.system(size: 13, weight: .semibold))
            Spacer(minLength: 0)
        }
    }

    @ViewBuilder
    private func sliderRow(label: String, value: Binding<Double>, range: ClosedRange<Double>, step: Double, unit: String, onChange: @escaping () -> Void) -> some View {
        HStack {
            Text(label)
            Slider(value: value, in: range, step: step)
                .frame(minWidth: 140)
                .onChange(of: value.wrappedValue) { onChange() }
            Text("\(Int(value.wrappedValue)) \(unit)")
                .foregroundStyle(.secondary).monospacedDigit()
                .frame(width: 52, alignment: .trailing)
        }
    }

    @ViewBuilder
    private func thresholdRow(label: String, selected: Binding<Set<Int>>, onChange: @escaping (Set<Int>) -> Void) -> some View {
        HStack {
            Text(label)
            Spacer()
            HStack(spacing: 6) {
                ForEach(thresholdOptions, id: \.self) { mins in
                    let isOn = selected.wrappedValue.contains(mins)
                    Button {
                        var updated = selected.wrappedValue
                        if isOn { updated.remove(mins) } else { updated.insert(mins) }
                        selected.wrappedValue = updated
                        onChange(updated)
                    } label: {
                        Text("\(mins)m")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(isOn ? Color.white : Color.primary)
                            .padding(.horizontal, 9)
                            .padding(.vertical, 4)
                            .background(
                                isOn ? AnyShapeStyle(Color.accentColor) : AnyShapeStyle(.ultraThinMaterial),
                                in: Capsule()
                            )
                            .overlay(
                                Capsule().stroke(Color.primary.opacity(isOn ? 0 : 0.08), lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .animation(.smooth(duration: 0.2), value: selected.wrappedValue)
        }
    }

    @ViewBuilder
    private func swatchRow(presets: [(String, String)], selectedHex: String, action: @escaping (String) -> Void) -> some View {
        HStack(spacing: 8) {
            ForEach(presets, id: \.0) { (hex, _) in
                let isSelected = selectedHex.uppercased() == hex.uppercased()
                Button {
                    action(hex)
                } label: {
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .fill(Color(hex: hex))
                        .frame(width: 26, height: 26)
                        .overlay(
                            RoundedRectangle(cornerRadius: 7, style: .continuous)
                                .stroke(isSelected ? Color.accentColor : Color.primary.opacity(0.15),
                                        lineWidth: isSelected ? 2.5 : 1)
                        )
                        .scaleEffect(isSelected ? 1.08 : 1.0)
                }
                .buttonStyle(.plain)
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
            }
        }
    }

    @ViewBuilder
    private func themePreviewImage(_ name: String, fallback: String) -> some View {
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
    private func themeButton<Content: View>(key: String, label: String, @ViewBuilder content: () -> Content) -> some View {
        let isSelected = selectedTheme == key || (key.hasPrefix("emoji:") && selectedTheme.hasPrefix("emoji:"))
        Button {
            selectedTheme = key
            settingsManager.setAnimationTheme(key)
        } label: {
            VStack(spacing: 5) {
                content()
                    .frame(width: 40, height: 40)
                Text(label)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(isSelected ? Color.accentColor : Color.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                isSelected ? AnyShapeStyle(Color.accentColor.opacity(0.14)) : AnyShapeStyle(.ultraThinMaterial),
                in: RoundedRectangle(cornerRadius: 14, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(isSelected ? Color.accentColor : Color.primary.opacity(0.06),
                            lineWidth: isSelected ? 2 : 1)
            )
            .scaleEffect(isSelected ? 1.0 : 0.97)
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }

    @ViewBuilder
    private func customImageTile() -> some View {
        let isSelected = selectedTheme == "custom_image"
        Button { pickCustomImage() } label: {
            VStack(spacing: 5) {
                Group {
                    if let path = customImagePath, let img = NSImage(contentsOfFile: path) {
                        Image(nsImage: img)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 34, height: 34)
                    } else {
                        Image(systemName: isSelected ? "photo.fill" : "photo.badge.plus")
                            .font(.system(size: 22))
                            .foregroundStyle(isSelected ? Color.accentColor : Color.secondary)
                            .frame(width: 34, height: 34)
                    }
                }
                Text(customImagePath != nil ? "Image" : "Add Image")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(isSelected ? Color.accentColor : Color.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                isSelected ? AnyShapeStyle(Color.accentColor.opacity(0.14)) : AnyShapeStyle(.ultraThinMaterial),
                in: RoundedRectangle(cornerRadius: 14, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(isSelected ? Color.accentColor : Color.primary.opacity(0.06),
                            lineWidth: isSelected ? 2 : 1)
            )
            .scaleEffect(isSelected ? 1.0 : 0.97)
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }

    private func pickCustomImage() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.image]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.message = "Choose any image — Flyby will resize and convert it automatically."
        panel.prompt = "Use Image"
        guard panel.runModal() == .OK, let url = panel.url else { return }
        guard let dest = SettingsManager.processAndSaveCustomImage(from: url) else { return }
        customImagePath = dest.path
        settingsManager.setCustomImagePath(dest.path)
        selectedTheme = "custom_image"
        settingsManager.setAnimationTheme("custom_image")
    }

    // MARK: - Logic (unchanged behavior)

    private func loadSettings() {
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
        customImagePath = settingsManager.customImagePath()

        lastAutoSync = settingsManager.lastTodoistSync()
        todoistSyncInterval = settingsManager.todoistSyncInterval()
        isCalendarEnabled = settingsManager.isCalendarEnabled()
        isTodoistEnabled = settingsManager.isTodoistEnabled()
        calendarThresholds = Set(settingsManager.calendarThresholds())
        todoistThresholds = Set(settingsManager.todoistThresholds())
        todoistToken = settingsManager.todoistToken()
        let hasToken = !todoistToken.isEmpty
        todoistStatus = hasToken ? "Connected" : "Token Required"
        isEditingToken = !hasToken

        launchAtLogin = (SMAppService.mainApp.status == .enabled)
        isSoundEnabled = settingsManager.isSoundEnabled()
        selectedSoundType = settingsManager.soundType()
        checkPermission()
    }

    private func setLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled {
                if SMAppService.mainApp.status != .enabled {
                    try SMAppService.mainApp.register()
                }
            } else {
                if SMAppService.mainApp.status == .enabled {
                    try SMAppService.mainApp.unregister()
                }
            }
        } catch {
            print("⚠️ Launch at Login toggle failed: \(error.localizedDescription)")
            launchAtLogin = (SMAppService.mainApp.status == .enabled)
        }
    }

    private func checkPermission() {
        let authorized = calendarManager.isCalendarAuthorized()
        isAuthorized = authorized
        calendarStatus = authorized ? "Granted" : "Denied / Tap to Request"
    }

    private func requestPermission() {
        calendarManager.requestAccess { granted in
            DispatchQueue.main.async {
                isAuthorized = granted
                calendarStatus = granted ? "Granted" : "Denied"
            }
        }
    }

    private func syncTodoistTasks() {
        isSyncingTodoist = true
        lastSyncResult = ""
        onSyncTodoist { count, error in
            isSyncingTodoist = false
            if let error = error {
                lastSyncResult = "Sync failed: \(error.localizedDescription)"
            } else if let count = count {
                let formatter = DateFormatter()
                formatter.dateFormat = "h:mm a"
                lastSyncResult = "\(count) task\(count == 1 ? "" : "s") at \(formatter.string(from: Date()))"
            }
        }
    }

    private func verifyTodoistToken() {
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

// MARK: - Vibrancy (frosted-glass window background)

struct VisualEffectBackground: NSViewRepresentable {
    var material: NSVisualEffectView.Material = .underWindowBackground
    var blendingMode: NSVisualEffectView.BlendingMode = .behindWindow

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}

struct SecurePasteField: NSViewRepresentable {
    let placeholder: String
    @Binding var text: String

    func makeNSView(context: Context) -> NSSecureTextField {
        let textField = PasteSecureTextField()
        textField.placeholderString = placeholder
        textField.isBordered = true
        textField.bezelStyle = .roundedBezel
        textField.drawsBackground = true
        textField.delegate = context.coordinator
        textField.focusRingType = .default
        textField.textColor = .labelColor
        textField.font = NSFont.systemFont(ofSize: 12)
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
