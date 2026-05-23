import Foundation

struct CalendarEvent: Codable {
    let title: String
    let startDate: Date
    let endDate: Date
    let eventIdentifier: String
    let platform: String?
    let url: String?
}

class CalendarManager {
    
    // Path to the python script inside the app bundle resources
    var scriptPath: String {
        if let path = Bundle.main.path(forResource: "fetch_calendar", ofType: "py") {
            return path
        }
        // Fallback for local development
        return "/Users/anand/Desktop/dev/FlightCalendarNotifier/fetch_calendar.py"
    }
    
    func requestAccess(completion: @escaping (Bool) -> Void) {
        // Run a test query to verify the bridge is active
        fetchUpcomingEvents { events in
            completion(true)
        }
    }
    
    private struct PythonEvent: Codable {
        let title: String
        let startDate: Double
        let endDate: Double
        let eventIdentifier: String
        let platform: String?
        let url: String?
    }
    
    private func runPythonCalendarScript(action: String, completion: @escaping ([CalendarEvent]) -> Void) {
        let process = Process()
        let pipe = Pipe()
        
        process.standardOutput = pipe
        process.standardError = Pipe() // Silence stderr
        process.arguments = [scriptPath, "--action", action]
        
        // Dynamically locate the Homebrew Python or System Python executable
        var pythonExecutable = "/opt/homebrew/bin/python3"
        if !FileManager.default.fileExists(atPath: pythonExecutable) {
            pythonExecutable = "/usr/bin/python3"
        }
        process.executableURL = URL(fileURLWithPath: pythonExecutable)
        
        do {
            try process.run()
            process.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            
            if action == "upcoming" {
                if let pyEvents = try? JSONDecoder().decode([PythonEvent].self, from: data) {
                    let events = pyEvents.map {
                        CalendarEvent(
                            title: $0.title,
                            startDate: Date(timeIntervalSince1970: $0.startDate),
                            endDate: Date(timeIntervalSince1970: $0.endDate),
                            eventIdentifier: $0.eventIdentifier,
                            platform: $0.platform,
                            url: $0.url
                        )
                    }
                    completion(events)
                    return
                }
            } else if action == "next" {
                if let pyEvent = try? JSONDecoder().decode(PythonEvent.self, from: data) {
                    let event = CalendarEvent(
                        title: pyEvent.title,
                        startDate: Date(timeIntervalSince1970: pyEvent.startDate),
                        endDate: Date(timeIntervalSince1970: pyEvent.endDate),
                        eventIdentifier: pyEvent.eventIdentifier,
                        platform: pyEvent.platform,
                        url: pyEvent.url
                    )
                    completion([event])
                    return
                }
            }
            completion([])
        } catch {
            print("Failed to run python calendar helper: \(error.localizedDescription)")
            completion([])
        }
    }
    
    func fetchUpcomingEvents(completion: @escaping ([CalendarEvent]) -> Void) {
        runPythonCalendarScript(action: "upcoming", completion: completion)
    }
    
    func fetchNextUpcomingEvent(completion: @escaping (CalendarEvent?) -> Void) {
        runPythonCalendarScript(action: "next") { events in
            completion(events.first)
        }
    }
}
