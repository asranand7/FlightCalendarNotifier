# Flyby — Animated Meeting Reminders

A lightweight macOS menu-bar app that flies an animated banner across your screen
before calendar meetings and timed Todoist tasks, so you never miss the start.

- **Calendar reminders** — reads your macOS Calendar (Google/iCloud/Exchange accounts synced to Calendar.app) natively via EventKit.
- **Todoist reminders** — fetches timed tasks via the Todoist API.
- **Per-source alert intervals** — choose independently when to be reminded (1, 2, 5, 10, 15, 30 min before) for Calendar and Todoist.
- **Customizable banner** — theme (plane, F1 car, rocket, custom image, or 18+ high-quality character themes like Snoopy, Superhero, Modiji, Trump, Thor, Wonder Woman), size, speed, position, colors.
- **Notification History** — view a rolling list of the last 50 triggered notifications with source icons, timestamps, and quick cleanup.
- **Secure Credentials** — sensitive API keys are stored safely inside the native macOS Keychain.
- **Launch at Login** — keep it running quietly in the background.

---

## Requirements

- macOS 14 (Sonoma) or later
- Xcode **Command Line Tools** (provides `swiftc` — no full Xcode needed)

  ```bash
  xcode-select --install
  ```

That's the only dependency. Calendar access uses native Swift/EventKit, so there is **no** Python requirement.

---

## Build & Install (on any Mac)

Clone the repo, then build and install in one step:

```bash
git clone https://github.com/asranand7/FlightCalendarNotifier.git
cd FlightCalendarNotifier
./build.sh install
```

`./build.sh install` compiles the app, copies **Flyby.app** into `/Applications`, and launches it.

- To **build only** (output lands in `build/Flyby.app` without installing):

  ```bash
  ./build.sh
  ```

- To **update** after pulling new code, just run `./build.sh install` again — it quits the running copy and replaces it.

> **Note on signing:** the build is ad-hoc signed (`codesign --sign -`). Because you build it locally on the same machine, Gatekeeper allows it. If you instead copy a prebuilt `.app` from another Mac, macOS may block it — prefer rebuilding from source on each machine.

---

## First launch — grant permissions

1. Open the app (the **Flyby** window appears and an ✈️ icon is added to the menu bar).
2. Go to **Reminders → Enable Calendar Reminders**. macOS will prompt for Calendar access — click **Allow**.
   - If you miss the prompt, grant it under **System Settings → Privacy & Security → Calendars → Flyby**.
3. Permission is requested **once** and persists across launches.

---

## Keep it always on (Launch at Login)

1. Open Flyby → **General**.
2. Turn on **Launch at Login**.

Flyby will now start automatically every time you log in and keep polling in the
background. You can confirm/manage it under **System Settings → General → Login Items**.

---

## Todoist setup (optional)

1. In Todoist, go to **Settings → Integrations → Developer** and copy your **API token**.
2. In Flyby → **Reminders → Enable Todoist Reminders**, paste the token, and click **Verify**.
3. Use **Sync Now** to pull tasks immediately; otherwise tasks auto-sync every 10 minutes.

Your API token is encrypted and stored securely in the **macOS Keychain** (`com.anand.FlightNotifier` / `todoist_token`), keeping it protected.

Only tasks with a **specific time** (e.g. "today at 3pm") trigger banners — date-only
tasks are ignored. Both fixed-timezone and floating (no-timezone) times are supported.

---

## Configuration

All settings live in the app window (open it from the menu-bar ✈️ icon → or relaunch the app):

| Pane | What you can change |
|------|---------------------|
| **General** | Launch at Login, Calendar permission status, version info |
| **Reminders** | Enable Calendar / Todoist, per-source alert intervals, Todoist token verification & sync controls |
| **Appearance** | Animation theme (18+ presets + custom images), banner width/height, flight speed, position, card/text colors |
| **History** | View and clear the last 50 triggered notifications |

Use the **Test Animation** button (top-right toolbar) to preview the banner anytime.
General preferences are stored in `UserDefaults` (`com.anand.FlightNotifier`), while the Todoist API token is stored securely in the **macOS Keychain**.

---

## Troubleshooting

- **No calendar banners:** ensure Calendar Reminders is enabled and access is **Granted** (General pane), and that the meeting has a specific start time within the next 45 minutes.
- **No Todoist banners:** the task needs a specific *time*; click **Sync Now** if you just created it (auto-sync runs every 10 min). Todoist triggering currently rides on the Calendar polling timer, so leaving Calendar enabled is recommended.
- **Re-prompted for Calendar access after rebuilding:** ad-hoc signatures change per build, which can reset the macOS permission grant during development. Re-grant when prompted; installed `/Applications` copies stay stable between launches.
- **"Launch at Login" won't stick:** install to `/Applications` first (`./build.sh install`), then toggle it on — login items are tied to the app's location.

---

## Uninstall

1. Flyby → General → turn **Launch at Login** off.
2. Quit Flyby (menu-bar icon → Quit).
3. Delete `/Applications/Flyby.app`.
4. (Optional) Revoke Calendar access in System Settings → Privacy & Security → Calendars.
