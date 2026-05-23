import Foundation
import EventKit

struct CalendarEvent: Codable {
    let title: String
    let startDate: Date
    let endDate: Date
    let eventIdentifier: String
    let platform: String?
    let url: String?
}

class CalendarManager {
    let eventStore = EKEventStore()

    func requestAccess(completion: @escaping (Bool) -> Void) {
        let status = EKEventStore.authorizationStatus(for: .event)
        if status == .authorized {
            completion(true)
            return
        }
        if #available(macOS 14.0, *), status.rawValue == 4 { // fullAccess
            completion(true)
            return
        }
        if status == .notDetermined {
            if #available(macOS 14.0, *) {
                eventStore.requestFullAccessToEvents { granted, error in
                    completion(granted)
                }
            } else {
                eventStore.requestAccess(to: .event) { granted, error in
                    completion(granted)
                }
            }
        } else {
            completion(false)
        }
    }
    
    func isCalendarAuthorized() -> Bool {
        let status = EKEventStore.authorizationStatus(for: .event)
        if status == .authorized { return true }
        if #available(macOS 14.0, *), status.rawValue == 4 { return true }
        return false
    }
    
    // MARK: - Native EventKit fetching

    private func meetingPlatform(location: String?, url: URL?, notes: String?) -> String? {
        let loc = (location ?? "").lowercased()
        let urlStr = (url?.absoluteString ?? "").lowercased()
        let notesStr = (notes ?? "").lowercased()
        func matches(_ needle: String) -> Bool {
            return loc.contains(needle) || urlStr.contains(needle) || notesStr.contains(needle)
        }
        if matches("meet.google.com") { return "Google Meet" }
        if matches("zoom.us") { return "Zoom" }
        if matches("teams.microsoft.com") { return "Teams" }
        if let location = location, !location.isEmpty { return location }
        return nil
    }

    private func meetingURL(for event: EKEvent) -> String? {
        if let url = event.url { return url.absoluteString }
        if let loc = event.location, loc.lowercased().hasPrefix("http") { return loc }

        let notes = event.notes ?? ""
        guard let regex = try? NSRegularExpression(pattern: "(https?://\\S+)") else { return nil }
        let range = NSRange(notes.startIndex..., in: notes)
        let urls: [String] = regex.matches(in: notes, range: range).compactMap {
            Range($0.range, in: notes).map { String(notes[$0]) }
        }
        let trimChars = CharacterSet(charactersIn: ".,;)")
        for u in urls {
            let ul = u.lowercased()
            if ul.contains("meet.google.com") || ul.contains("zoom.us") || ul.contains("teams.microsoft.com") {
                return u.trimmingCharacters(in: trimChars)
            }
        }
        return urls.first?.trimmingCharacters(in: trimChars)
    }

    private func isDeclined(_ event: EKEvent) -> Bool {
        guard let attendees = event.attendees else { return false }
        return attendees.contains { $0.isCurrentUser && $0.participantStatus == .declined }
    }

    private func mapEvent(_ event: EKEvent) -> CalendarEvent {
        return CalendarEvent(
            title: event.title ?? "Untitled Meeting",
            startDate: event.startDate,
            endDate: event.endDate,
            eventIdentifier: event.eventIdentifier ?? UUID().uuidString,
            platform: meetingPlatform(location: event.location, url: event.url, notes: event.notes),
            url: meetingURL(for: event)
        )
    }

    func fetchUpcomingEvents(completion: @escaping ([CalendarEvent]) -> Void) {
        guard isCalendarAuthorized() else { completion([]); return }
        let now = Date()
        let predicate = eventStore.predicateForEvents(withStart: now.addingTimeInterval(-5 * 60), end: now.addingTimeInterval(45 * 60), calendars: nil)
        let result = eventStore.events(matching: predicate)
            .filter { !$0.isAllDay && !isDeclined($0) }
            .map { mapEvent($0) }
        completion(result)
    }

    func fetchNextUpcomingEvent(completion: @escaping (CalendarEvent?) -> Void) {
        guard isCalendarAuthorized() else { completion(nil); return }
        let now = Date()
        let predicate = eventStore.predicateForEvents(withStart: now, end: now.addingTimeInterval(24 * 60 * 60), calendars: nil)
        let result = eventStore.events(matching: predicate)
            .filter { !$0.isAllDay && !isDeclined($0) && $0.startDate > now }
            .sorted { $0.startDate < $1.startDate }
        completion(result.first.map { mapEvent($0) })
    }
}
