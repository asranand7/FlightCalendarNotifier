import Foundation

struct TodoistDue: Codable {
    let date: String       // "YYYY-MM-DD", floating "YYYY-MM-DDTHH:MM:SS", or absolute "...Z"/"...+05:30"
    let timezone: String?

    // True when the due date includes a specific time
    var isDatetime: Bool { date.contains("T") }

    // Resolves the due string to an absolute Date, handling both
    // absolute (UTC/offset) and floating (no-offset, local) Todoist formats.
    var parsedDate: Date? {
        guard isDatetime else { return nil }

        let hasOffset = date.hasSuffix("Z")
            || date.range(of: "[+-]\\d{2}:?\\d{2}$", options: .regularExpression) != nil

        if hasOffset {
            // Absolute instant — e.g. "2026-05-23T14:06:26Z"
            let iso = ISO8601DateFormatter()
            iso.formatOptions = [.withInternetDateTime]
            if let d = iso.date(from: date) { return d }
            iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            return iso.date(from: date)
        }

        // Floating time — e.g. "2026-05-23T20:01:00". Interpret in the task's
        // timezone if named, otherwise the user's current timezone.
        let df = DateFormatter()
        df.locale = Locale(identifier: "en_US_POSIX")
        df.timeZone = timezone.flatMap { TimeZone(identifier: $0) } ?? TimeZone.current
        for format in ["yyyy-MM-dd'T'HH:mm:ss", "yyyy-MM-dd'T'HH:mm"] {
            df.dateFormat = format
            if let d = df.date(from: date) { return d }
        }
        return nil
    }
}

struct TodoistTask: Codable {
    let id: String
    let content: String
    let description: String?
    let due: TodoistDue?

    var url: String { "https://todoist.com/app/task/\(id)" }
}

private struct TodoistTasksResponse: Codable {
    let results: [TodoistTask]
}

class TodoistManager {
    func fetchTasks(token: String, completion: @escaping ([TodoistTask]?, Error?) -> Void) {
        guard !token.isEmpty else {
            completion([], nil)
            return
        }

        guard let url = URL(string: "https://api.todoist.com/api/v1/tasks") else {
            completion(nil, NSError(domain: "TodoistManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"]))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 10.0

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(nil, error)
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                completion(nil, NSError(domain: "TodoistManager", code: -2, userInfo: [NSLocalizedDescriptionKey: "Invalid HTTP Response"]))
                return
            }

            guard httpResponse.statusCode == 200 else {
                let msg = "HTTP Status \(httpResponse.statusCode)"
                completion(nil, NSError(domain: "TodoistManager", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: msg]))
                return
            }

            guard let data = data else {
                completion(nil, NSError(domain: "TodoistManager", code: -3, userInfo: [NSLocalizedDescriptionKey: "No data received"]))
                return
            }

            do {
                let decoder = JSONDecoder()
                let response = try decoder.decode(TodoistTasksResponse.self, from: data)
                let timedTasks = response.results.filter { $0.due?.isDatetime == true }
                completion(timedTasks, nil)
            } catch {
                completion(nil, error)
            }
        }
        task.resume()
    }
}
